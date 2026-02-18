------------------------------------------------------------------------------
--                                   VGA                                    --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with VGA;
with x86.Port_IO;
with Loggers;
with Interfaces;                       use Interfaces;
with System;
with System.Machine_Code;
with VGA.Graphic_Controller;           use VGA.Graphic_Controller;
with VGA.Graphic_Controller.Registers; use VGA.Graphic_Controller.Registers;
with VGA.Sequencer;                    use VGA.Sequencer;
with VGA.Sequencer.Registers;          use VGA.Sequencer.Registers;
with VGA.CRTC;                         use VGA.CRTC;
with VGA.CRTC.Registers;
with VGA.Attribute;                    use VGA.Attribute;
with VGA.Attribute.Registers;
with VGA.Terminal;
with VGA.DAC;                          use VGA.DAC;
with VGA.GTF;                          use VGA.GTF;
with Util;
with Ada.Unchecked_Conversion;
with System.Address_To_Access_Conversions;
with x86.vmm;
with System.Storage_Elements;
with File_System;
with x86; use x86;

package body VGA is
   use Standard.ASCII;
   package Logger renames Loggers;

   --------------------
   -- Dump_Registers --
   --------------------
   procedure Dump_Registers is
      function To_U8 is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Miscellaneous_Output_Register);
   begin
      Logger.Log_Info (To_U8 (Read_Miscellaneous_Output_Register)'Image);
      Dump_Sequencer_Registers;
      VGA.CRTC.Registers.Dump;
      Dump_Graphic_Controller_Registers;
      VGA.Attribute.Registers.Dump_Attribute_Registers;
   end Dump_Registers;

   ------------------------
   -- Is_In_Graphic_Mode --
   ------------------------
   function Is_In_Graphic_Mode return Boolean is
   begin
      return Current_Mode = all_point_addressable;
   end Is_In_Graphic_Mode;

   -----------------------
   -- Save_Frame_Buffer --
   -----------------------
   procedure Save_Frame_Buffer is
      use all type System.Address;
      use all type System.Storage_Elements.Storage_Offset;
      CR3 : x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      package Conversion is new System.Address_To_Access_Conversions (vga_buffer);
   begin
      if save_buffer_address = System.Null_Address then
         save_buffer_address :=
           x86.vmm.Kernel_Alloc (Size => 320 * 200, CR3 => CR3, Is_Writable => True);
      end if;

      if save_buffer_address = System.Null_Address then
         Logger.Log_Error ("Unable to allocate vga save buffer");
         return;
      end if;

      declare
         buffer             : access vga_buffer := Conversion.To_Pointer (save_buffer_address);
         current_vga_buffer : access vga_buffer := Conversion.To_Pointer (Get_Frame_Buffer);
      begin
         buffer.all := current_vga_buffer.all;
      end;

      Logger.Log_Ok ("vga buffer (" & Get_Frame_Buffer'Image & ") saved at address: " & save_buffer_address'Image);
   end Save_Frame_Buffer;

   --------------------------
   -- Restore_Frame_Buffer --
   --------------------------
   procedure Restore_Frame_Buffer is
      use all type System.Address;
      package Conversion is new System.Address_To_Access_Conversions (vga_buffer);
   begin
      if save_buffer_address = System.Null_Address then
         Logger.Log_Error ("save buffer is not allocated");
         return;
      end if;

      declare
         buffer             : access vga_buffer := Conversion.To_Pointer (save_buffer_address);
         current_vga_buffer : access vga_buffer := Conversion.To_Pointer (Get_Frame_Buffer);
      begin
         current_vga_buffer.all := buffer.all;
      end;

      Logger.Log_Ok ("vga buffer ("& Get_Frame_Buffer'Image &") restored from address: " & save_buffer_address'Image);
   end Restore_Frame_Buffer;

   ------------------
   -- Load_Palette --
   ------------------
   procedure Load_Palette (p : File_System.Path) is
   begin
      -- Disable IPAS to load color values to register
      Reset_Attribute_Register;
      -- VGA.Attribute.Registers.Select_Attribute_Register (16#0#);
      VGA.Dac.Load_File (p);

      -- Reenable IPAS for normal operations
      -- Reset_Attribute_Register;
      -- VGA.Attribute.Registers.Select_Attribute_Register (16#20#);
   end Load_Palette;

   ----------------------
   -- Get_Frame_Buffer --
   ----------------------
   function Get_Frame_Buffer return System.Address is
      Miscellaneous : Miscellaneous_Register := Read_Miscellaneous_Register;
   begin
      --  Logger.Log_Info (Miscellaneous.Memory_Map'Image);
      case Miscellaneous.Memory_Map is
         when A0000_128KB =>
            return System.Address (16#A0000#);

         when A0000_64KB =>
            return System.Address (16#A0000#);

         when B0000_32KB =>
            return System.Address (16#B0000#);

         when B8000_32KB =>
            return System.Address (16#B8000#);

         when others =>
            return System.Address'First;
      end case;
   end Get_Frame_Buffer;


   -------------------------------
   -- Compute_Needed_Memory_Map --
   -------------------------------
   function Compute_Needed_Memory_Map
     (Width, Height : Positive; Pixel_Size : Positive) return Memory_Map_Addressing
   is
      Storage_Needed : Positive := Width * Height * Pixel_Size / System.Storage_Unit;
   begin

      if Storage_Needed <= 32 * 1024 then
         return B0000_32KB;
      end if;

      if Storage_Needed <= 64 * 1024 then
         return A0000_64KB;
      end if;

      if Storage_Needed <= 128 * 1024 then
         return A0000_128KB;
      end if;
      raise Program_Error;
   end Compute_Needed_Memory_Map;

   --------------------
   -- Get_Pixel_Size --
   --------------------
   function Get_Pixel_Size (Color_Depth : Positive) return Positive is
   begin
      case Color_Depth is
         when 256 =>
            return 8;

         when 16 =>
            return 8;

         when others =>
            raise Program_Error;
      end case;
   end Get_Pixel_Size;

   ---------------------------
   -- Compute_Dot_Per_Pixel --
   ---------------------------
   function Compute_Dot_Per_Pixel (Color_Depth : Positive) return Positive is
   begin
      if Color_Depth = 256 then
         -- In 256 mode 4 pixels are outputed from memory each dot clock
         -- Hence, 2 dot ticks are required for 1 pixel.
         return 2;
      else
         return 1;
      end if;
   end Compute_Dot_Per_Pixel;

   ---------------
   -- Find_Mode --
   ---------------

   function Find_Mode
     (Width, Height, Color_Depth : Positive; graphic_mode : Mode_Type) return VGA_Mode
   is
      function Find_Graphic_Mode return VGA_Mode is
      begin
         for mode of reverse Modes loop
            if mode.vga_type = all_point_addressable then
               if mode.Pixel_Height = Height
                 and then mode.Pixel_Width = Width
                 and then mode.Colors = Color_Depth
               then
                  return mode;
               end if;
            end if;
         end loop;

         return (vga_type => mode_invalid, others => <>);
      end Find_Graphic_Mode;

      function Find_Text_Mode return VGA_Mode is
      begin
         for mode of Modes loop
            if mode.vga_type = alphanumeric then
               if mode.AN_Format.Height = Height
                 and then mode.AN_Format.Width = Width
                 and then mode.Colors = Color_Depth
               then
                  return mode;
               end if;
            end if;
         end loop;

         return (vga_type => mode_invalid, others => <>);
      end Find_Text_Mode;

   begin
      if graphic_mode = all_point_addressable then
         return Find_Graphic_Mode;
      else
         return Find_Text_Mode;
      end if;
   end;


   ------------------------
   -- Get_MSL_Multiplier --
   ------------------------
   function Get_MSL_Multiplier (Height : Scan_Line_Count) return Integer is
      HW_MAX_SUPPORTED_HEIGHT : Scan_Line_Count := 400;
   begin
      if HW_MAX_SUPPORTED_HEIGHT < Height then
         return 1;
      end if;

      return HW_MAX_SUPPORTED_HEIGHT / Height;
   end Get_MSL_Multiplier;

   function Get_Clock (width : Positive) return Clock_Select is
   begin
      case Width is
         when 720 | 360 =>
            return Clock_28M_720_360_PELs;

         when 640 | 320 =>
            return Clock_25M_640_320_PELs;

         when others =>
            raise Program_Error;
      end case;
   end Get_Clock;


   ----------------------
   -- Set_Graphic_Mode --
   ----------------------
   procedure Set_Graphic_Mode (Width, Height, Color_Depth : Positive) is
      mode : VGA_Mode := Find_Mode (Width, Height, Color_Depth, all_point_addressable);
      Miscellaneous : Miscellaneous_Output_Register;
      function To_U8 is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Miscellaneous_Output_Register);
   begin
      if mode.vga_type = mode_invalid then
         Logger.Log_Error
           ("mode " & Width'Image & "x" & Height'Image & "x" & Color_Depth'image & " is invalid");
         return;
      end if;
      Logger.Log_Info ("Setting mode: " & mode'Image);
      VGA.Terminal.Pause_Output;

      -- Disabling vga-terminal logging
      Current_Mode := all_point_addressable;

      Miscellaneous := (IOS  => True,
                        ERAM => True,
                        CS   => Get_Clock (mode.Pixel_Width),
                        OE   => True,
                        Size => Size_400_Lines);
      -- Misc
      Logger.Log_Info ("Misc Register set to: " & To_U8 (Miscellaneous)'Image);

      Write_Miscellaneous_Output_Register (Miscellaneous);

      Set_CRTC_For_Mode (mode);
      Set_Sequencer_For_Mode (mode);
      Set_Graphic_Controller_For_Mode (mode);
      Set_Attribute_For_Mode (mode);

      -- Disable IPAS to load color values to register
      Reset_Attribute_Register;
      VGA.Attribute.Registers.Select_Attribute_Register (16#0#);
      load_default_palette;

      -- Reenable IPAS for normal operations
      Reset_Attribute_Register;
      VGA.Attribute.Registers.Select_Attribute_Register (16#20#);

      Logger.Log_Ok ("mode " & Width'Image & "x" & Height'Image & "x" & Color_Depth'image & " set");
      Save_Frame_Buffer;
   end Set_Graphic_Mode;

   procedure Set_Text_Mode (Width, Height, Color_Depth : Positive) is
      mode : VGA_Mode := Find_Mode (Width, Height, Color_Depth, alphanumeric);
   begin
      if mode.vga_type = mode_invalid then
         Logger.Log_Error
           ("mode " & Width'Image & "x" & Height'Image & "x" & Color_Depth'image & " is invalid");
         return;
      end if;

      Logger.Log_Info ("Setting mode: " & mode'Image);
      Restore_Frame_Buffer;

      -- Misc
      Write_Miscellaneous_Output_Register
        ((IOS  => True,
          ERAM => True,
          CS   => Get_Clock (mode.Pixel_Width),
          OE   => True,
          Size => Size_400_Lines));

      Set_Sequencer_For_Mode (mode);
      Set_CRTC_For_Mode (mode);
      Set_Graphic_Controller_For_Mode (mode);
      Set_Attribute_For_Mode (mode);

      -- Disable IPAS to load color values to register
      Reset_Attribute_Register;
      VGA.Attribute.Registers.Select_Attribute_Register (16#0#);
      load_default_palette;

      -- Reenable IPAS for normal operations
      Reset_Attribute_Register;
      VGA.Attribute.Registers.Select_Attribute_Register (16#20#);

      Logger.Log_Ok ("mode " & Width'Image & "x" & Height'Image & "x" & Color_Depth'image & " set");
      Current_Mode := alphanumeric;
      Vga.Terminal.Resume;
   end Set_Text_Mode;
end VGA;
