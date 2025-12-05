------------------------------------------------------------------------------
--                                   VGA                                    --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with VGA;
with x86.Port_IO;
with Log;
with Interfaces;             use Interfaces;
with System;
with System.Machine_Code;
with VGA.Graphic_Controller; use VGA.Graphic_Controller;
with VGA.Sequencer;          use VGA.Sequencer;
with VGA.CRTC;               use VGA.CRTC;
with VGA.Attribute;          use VGA.Attribute;
with VGA.DAC;                use VGA.DAC;
with VGA.GTF;                use VGA.GTF;
with Util;
with Ada.Unchecked_Conversion;
with System.Address_To_Access_Conversions;
with x86.vmm;
with System.Storage_Elements;
with File_System;
package body VGA is
   use Standard.ASCII;
   package Logger renames Log.Serial_Logger;

   procedure Dump_Registers
   is
      function To_U8 is new Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Miscellaneous_Output_Register);
   begin
      Logger.Log_Info (To_U8 (Read_Miscellaneous_Output_Register)'Image);
      Dump_Sequencer_Registers;
      Dump_CRTC_Register;
      Dump_Graphic_Controller_Registers;
      Dump_Attribute_Registers;
   end Dump_Registers;

   procedure save_buffer
   is
      use all type System.Address;
      use all type System.Storage_Elements.Storage_Offset;
      CR3 : x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      package Conversion is new System.Address_To_Access_Conversions (vga_buffer);
   begin
      if save_buffer_address = System.Null_Address then
         save_buffer_address := x86.vmm.kmalloc(Size => 320 * 200, CR3 => CR3);
      end if;

      if save_buffer_address = System.Null_Address then
         Logger.Log_Error ("Unable to allocate vga save buffer");
         return;
      end if;

      declare
         buffer : access vga_buffer := Conversion.To_Pointer (save_buffer_address);
         current_vga_buffer : access vga_buffer := Conversion.To_Pointer (Get_Frame_Buffer);
      begin
         buffer.all := current_vga_buffer.all;
      end;

      Logger.Log_Ok ("vga buffer saved at address: " & save_buffer_address'Image);
   end save_buffer;

   procedure restore_buffer
   is
      use all type System.Address;
      package Conversion is new System.Address_To_Access_Conversions (vga_buffer);
   begin
      if save_buffer_address = System.Null_Address then
         Logger.Log_Error ("save buffer is not allocated");
         return;
      end if;

      declare
         buffer : access vga_buffer := Conversion.To_Pointer (save_buffer_address);
         current_vga_buffer : access vga_buffer := Conversion.To_Pointer (Get_Frame_Buffer);
      begin
         current_vga_buffer.all := buffer.all;
      end;

      Logger.Log_Ok ("vga buffer restored from address: " & save_buffer_address'Image);
   end restore_buffer;

   procedure load_palette (p : File_System.Path)
   is
   begin
      Reset_Attribute_Register;
      Select_Attribute_Register (16#0#);
      VGA.Dac.load_palette (p);

      -- Reenable IPAS for normal operations
      Reset_Attribute_Register;
      Select_Attribute_Register (16#20#);
   end load_palette;
   ----------------------
   -- Get_Frame_Buffer --
   ----------------------
   function Get_Frame_Buffer return System.Address is
      Miscellaneous : Miscellaneous_Register := Read_Miscellaneous_Register;
   begin
      Logger.Log_Info (Miscellaneous.Memory_Map'Image);
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

   ------------------------------
   -- Reset_Attribute_Register --
   ------------------------------
   procedure Reset_Attribute_Register is
      function Read_ISR1 is new x86.Port_IO.Inb (Unsigned_8);
      Register : Unsigned_8;
      pragma Unreferenced (Register);
   begin
      Register := Read_ISR1 (x86.Port_IO.Port_Address (16#03DA#));
   end Reset_Attribute_Register;

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

   ------------------------------------
   -- Prepare_CRTC_For_Configuration --
   ------------------------------------
   procedure Prepare_CRTC_For_Configuration is
   begin
      Write_End_Horizontal_Blanking_Register ((Display_Enable_Skew => 0, others => <>));
      Write_End_Horizontal_Retrace_Register ((HRD => 0, others => <>));
      Write_Vertical_Retrace_End_Register
        ((Clear_Vertical_Interrupt  => False,
          Enable_Vertical_Interrupt => False,
          Select_5_Refresh_Cycles   => False,
          Protect_Register          => False,
          others                    => 0));
      Write_Maximum_Scan_Line_Register ((Double_Scanning => False, others => <>));
      Write_Start_Address_High_Register (0);
      Write_Start_Address_Low_Register (0);

      Write_Cursor_Location_High_Register (0);
      Write_Cursor_Location_Low_Register (0);
   end Prepare_CRTC_For_Configuration;

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

   ----------------------
   -- Set_Graphic_Mode --
   ----------------------
   procedure Set_Graphic_Mode (Width, Height, Color_Depth : Positive) is
      -- HW Properties --
      CELL_GRAN_RND : constant := 8;
      Line_Compare_Disable : constant := 16#3FF#;

      Scan_Per_Character_Row : Integer := Get_MSL_Multiplier (Height);
      Dot_Per_Pixel          : Positive := Compute_Dot_Per_Pixel (Color_Depth);

      Timing : VGA_Timing :=
        Compute_Timing (Width * Dot_Per_Pixel, Height * Scan_Per_Character_Row);

      -- Other configuration --
      Pixel_Per_Address : constant := 2; -- TODO compute this value
      Memory_Address_Size : constant := 2; -- TODO compute this value
      Offset     : Positive := Width / (Pixel_Per_Address * Memory_Address_Size * 2);
      Memory_Map : Memory_Map_Addressing :=
        Compute_Needed_Memory_Map (Width, Height, Get_Pixel_Size (Color_Depth));

   begin
      Logger.Log_Info ("Setting mode: " & Width'Image & "x" & Height'Image & "x" & Color_Depth'Image);
      Logger.Log_Info (Timing'Image);
      -- MISC --
      ----------
      Write_Miscellaneous_Output_Register
        ((IOS => True, OE => False, ERAM => True, CS => Clock_25M_640_320_PELs, Size => Size_400_Lines));

      ---------------
      -- Sequencer --
      ---------------
      Write_Reset_Register ((ASR => True, SR => True));
      Write_Clocking_Mode_Register
        ((D89 => CELL_GRAN_RND = 8, SL => False, DC => True, SH4 => False, SO => False));
      Write_Map_Mask_Register ((others => True));
      Write_Character_Map_Select_Register
        (To_Character_Map_Select_Register (Map_2_1st_8KB, Map_2_1st_8KB));
      Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => True, Chain_4 => True));

      --------------------
      -- CRT Controller --
      --------------------
      Prepare_CRTC_For_Configuration;

      Write_Horizontal_Total_Register (Horizontal_Total_Register (Timing.Total_H - 5));
      Write_Horizontal_Display_Enable_End_Register
        (Horizontal_Display_Enable_End_Register (Timing.Active_H_Chars - 1));
      Set_Horizontal_Blanking (Timing.H_Blanking_Start, Timing.H_Blanking_Duration);
      Set_Horizontal_Retrace (Timing.H_Retrace_Start, Timing.H_Retrace_Duration);

      Set_Vertical_Total (Timing.Total_V - 2);
      Set_Vertical_Display (Timing.Active_V_Chars - 1);
      Set_Vertical_Blanking (Timing.V_Blanking_Start, Timing.V_Blanking_Duration);
      Set_Vertical_Retrace (Timing.V_Retrace_Start, Timing.V_Retrace_Duration);

      Set_Line_Compare (Line_Compare_Disable);
      Write_Cursor_Start_Register ((Row_Scan_Cursor_Begins => 0, Cursor_Off => False));
      Write_Cursor_End_Register ((Row_Scan_Cursor_Ends => 0, Cursor_Skew_Control => 0));

      Write_Offset_Register (Offset_Register (Offset));
      Write_Underline_Location_Register
        ((Start_Under_Line => 0, Count_By_4 => False, Double_Word => True, others => <>));

      Write_Maximum_Scan_Line_Register
        ((MSL => Unsigned_5 (Scan_Per_Character_Row) - 1, Double_Scanning => False, others => 0));

      Write_CRT_Mode_Control_Register
        ((CSM_0          => True,
          SRC            => True,
          HRS            => False,
          Count_By_2     => False,
          Address_Wrap   => True,
          Word_Byte_Mode => False,
          Hardware_Reset => True));
      Logger.Log_Info ("Setting GC");
      Write_Set_Reset_Register ((SR0 => False, SR1 => False, SR2 => False, SR3 => False));
      Write_Enable_Set_Reset_Register
        ((ESR0 => False, ESR1 => False, ESR2 => False, ESR3 => False));
      Write_Color_Compare_Register ((CC0 => False, CC1 => False, CC2 => False, CC3 => False));
      Write_Data_Rotate_Register ((Rotate_Count => 0, Function_Select => No_Function));
      Write_Read_Map_Select_Register (0);
      Write_Graphics_Mode_Register
        ((WM                  => Mode_0,
          Read_Mode           => False,
          Odd_Even            => False,
          Shift_Register_Mode => False,
          Color_Mode          => True));
      Write_Miscellaneous_Register
        ((Graphics_Mode => True, Odd_Even => False, Memory_Map => Memory_Map));
      Write_Color_Dont_Care_Register ((M0X => True, M1X => True, M2X => True, M3X => True));
      Write_Bit_Mask_Register ((others => True));

      Logger.Log_Info ("Setting Attribute");
      Reset_Attribute_Register;
      for i in Internal_Palette_Register_Index range 0 .. 15 loop
         Write_Internal_Palette_Register (i, Internal_Palette_Register (i));
      end loop;

      Write_Attribute_Mode_Control_Register
        ((Graphic_Mode              => True,
          Mono_Emulation            => False,
          Enable_Line_Graphics      => False,
          Enable_Blink              => False,
          PEL_Panning_Compatibility => False,
          PEL_Width                 => True,
          P5_P4_Select              => False));
      Write_Overscan_Color_Register (0);
      Write_Color_Plane_Enable_Register (16#0F#);
      Write_Horizontal_PEL_Panning_Register (16#00#);
      Write_Color_Select_Register
        ((Select_Color_4 => False,
          Select_Color_5 => False,
          Select_Color_6 => False,
          Select_Color_7 => False));

      -- Disable IPAS to load color values to register
      Reset_Attribute_Register;
      Select_Attribute_Register (16#0#);
      load_default_palette;

      -- Reenable IPAS for normal operations
      Reset_Attribute_Register;
      Select_Attribute_Register (16#20#);
   end Set_Graphic_Mode;

   procedure Set_Text_Mode (Width, Height : Positive) is
      -- HW Properties --
      CELL_GRAN_RND : constant := 9;
      Line_Compare_Disable : constant := 16#3FF#;

      Scan_Per_Character_Row : constant Integer := 1;
      Dot_Per_Pixel          : constant Positive := 16;

      Timing : VGA_Timing :=
        Compute_Timing (Width * 8, Height * 8);

      -- Other configuration --
      Pixel_Per_Address : constant := 1; -- TODO compute this value
      Memory_Address_Size : constant := 1; -- TODO compute this value
      Offset     : Positive := Width / (Pixel_Per_Address * Memory_Address_Size * 2);
      Memory_Map : Memory_Map_Addressing := B8000_32KB;
      --    Compute_Needed_Memory_Map (Width, Height, 8);

   begin
      Logger.Log_Info ("Setting mode: " & Width'Image & "x" & Height'Image);
      Logger.Log_Info (Timing'Image);
      -- MISC --
      ----------
      Write_Miscellaneous_Output_Register
        ((IOS => True, OE => True, ERAM => True, CS => Clock_28M_720_360_PELs, Size => Size_400_Lines));

      ---------------
      -- Sequencer --
      ---------------
      Write_Reset_Register ((ASR => True, SR => True));
      Write_Clocking_Mode_Register
        ((D89 => False, SL => False, DC => False, SH4 => False, SO => False));
      Write_Map_Mask_Register ((Map_0_Enable => True, Map_1_Enable => True, others => False));
      Write_Character_Map_Select_Register
        (To_Character_Map_Select_Register (Map_2_1st_8KB, Map_2_1st_8KB));
      Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => False, Chain_4 => False));

      --------------------
      -- CRT Controller --
      --------------------
      Prepare_CRTC_For_Configuration;

      Write_Horizontal_Total_Register (Horizontal_Total_Register (Timing.Total_H - 5));
      Write_Horizontal_Display_Enable_End_Register
        (Horizontal_Display_Enable_End_Register (Timing.Active_H_Chars - 1));
      Set_Horizontal_Blanking (Timing.H_Blanking_Start, 18);
      Set_Horizontal_Retrace (85, 8 + 4);

      Set_Vertical_Total (449 - 2);
      Set_Vertical_Display (144 - 1 + 256);
      Set_Vertical_Blanking (150 + 256, 36);
      Set_Vertical_Retrace (156 + 256, 18);

      Write_Cursor_Start_Register ((Row_Scan_Cursor_Begins => 16#D#, Cursor_Off => False));
      Write_Cursor_End_Register ((Row_Scan_Cursor_Ends => 16#E#, Cursor_Skew_Control => 0));

      Write_Offset_Register (Offset_Register (Offset));
      Write_Underline_Location_Register
        ((Start_Under_Line => 16#1F#, Count_By_4 => False, Double_Word => False, others => <>));

      Write_Maximum_Scan_Line_Register
        ((MSL => Unsigned_5 (Dot_Per_Pixel) - 1, Double_Scanning => False, others => 0));
      Set_Line_Compare (Line_Compare_Disable);

      Write_CRT_Mode_Control_Register
        ((CSM_0          => True,
          SRC            => True,
          HRS            => False,
          Count_By_2     => False,
          Address_Wrap   => True,
          Word_Byte_Mode => False,
          Hardware_Reset => True));
      Write_Cursor_Location_Low_Register (16#50#);
      --------------------
      -- CRT Controller --
      --------------------
      Logger.Log_Info ("Setting GC");
      Write_Set_Reset_Register ((SR0 => False, SR1 => False, SR2 => False, SR3 => False));
      Write_Enable_Set_Reset_Register
        ((ESR0 => False, ESR1 => False, ESR2 => False, ESR3 => False));
      Write_Color_Compare_Register ((CC0 => False, CC1 => False, CC2 => False, CC3 => False));
      Write_Data_Rotate_Register ((Rotate_Count => 0, Function_Select => No_Function));
      Write_Read_Map_Select_Register (0);
      Write_Graphics_Mode_Register
        ((WM                  => Mode_0,
          Read_Mode           => False,
          Odd_Even            => True,
          Shift_Register_Mode => False,
          Color_Mode          => False));
      Write_Miscellaneous_Register
        ((Graphics_Mode => False, Odd_Even => True, Memory_Map => Memory_Map));
      Write_Color_Dont_Care_Register ((M0X => False, M1X => False, M2X => False, M3X => False));
      Write_Bit_Mask_Register ((others => True));

      Logger.Log_Info ("Setting Attribute");
      Reset_Attribute_Register;
      for i in Internal_Palette_Register_Index range 0 .. 15 loop
         Write_Internal_Palette_Register (i, Internal_Palette_Register (i));
      end loop;

      Write_Attribute_Mode_Control_Register
        ((Graphic_Mode              => False,
          Mono_Emulation            => False,
          Enable_Line_Graphics      => True,
          Enable_Blink              => True,
          PEL_Panning_Compatibility => False,
          PEL_Width                 => False,
          P5_P4_Select              => False));
      Write_Overscan_Color_Register (0);
      Write_Color_Plane_Enable_Register (16#0F#);
      Write_Horizontal_PEL_Panning_Register (16#08#);
      Write_Color_Select_Register
        ((Select_Color_4 => False,
          Select_Color_5 => False,
          Select_Color_6 => False,
          Select_Color_7 => False));

      -- Disable IPAS to load color values to register
      Reset_Attribute_Register;
      Select_Attribute_Register (16#0#);
      load_default_palette;

      -- Reenable IPAS for normal operations
      Reset_Attribute_Register;
      Select_Attribute_Register (16#20#);
   end Set_Text_Mode;
end VGA;
