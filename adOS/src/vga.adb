with x86.Port_IO;
with Log;
with Interfaces; use Interfaces;
with System;
with System.Machine_Code;
with VGA.Graphic_Controller; use VGA.Graphic_Controller;
with VGA.Sequencer; use VGA.Sequencer;
with VGA.CRTC;     use VGA.CRTC;
with VGA.Attribute;     use VGA.Attribute;
with VGA.DAC;           use VGA.DAC;
with Util;
package body VGA is
   use Standard.ASCII;
   package Logger renames Log.Serial_Logger;

   function Get_Frame_Buffer return System.Address is
      Miscellaneous : Miscellaneous_Register := Read_Miscellaneous_Register;
   begin
      Logger.Log_Info (Miscellaneous'Image);
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

   procedure Reset_Attribute_Register is
      function Read_ISR1 is new x86.Port_IO.Inb (Unsigned_8);
      Register : Unsigned_8;
      pragma Unreferenced (Register);
   begin
      Register := Read_ISR1 (System.Address (16#03DA#));
   end Reset_Attribute_Register;

   procedure Set_Horizontal_Blanking (start : Positive; duration : Positive)
   is
      --  To program Horizontal_Blanking_End for a signal width of W, the
      --  following algorithm is used: the width W, in character
      --  clock units, is added to the value from the Start
      --  Horizontal Blanking register. The 6 low-order bits of the
      --  result are the 6-bit value programmed
      Horizontal_Blanking_End : Natural := (Start + Duration) mod 2 ** End_Blanking_T'Size;
      Blanking_End_Breakdown  : End_Blanking_T := (Value => Unsigned_6 (Horizontal_Blanking_End), Bit_Access => False);

      EHB_Register : End_Horizontal_Blanking_Register := Read_End_Horizontal_Blanking_Register;
      EHR_Register : End_Horizontal_Retrace_Register := Read_End_Horizontal_Retrace_Register;
   begin
         Write_Start_Horizontal_Blanking_Register (Horizontal_Blanking_Start (start));

         EHB_Register.End_Blanking := Blanking_End_Breakdown.LSB;
         Write_End_Horizontal_Blanking_Register (EHB_Register);

         EHR_Register.EB5 := Blanking_End_Breakdown.MSB;
         Write_End_Horizontal_Retrace_Register (EHR_Register);
   end Set_Horizontal_Blanking;

   procedure Set_Horizontal_Retrace (Start : Positive; Duration : Natural)
   is
      --  To program these bits with a signal width of W, the
      --  following algorithm is used: the width W, in character
      --  clock units, is added to the value in the Start Retrace
      --  register. The 5 low-order bits of the result are the 5-bit
      --  value programmed.
      HR_End : Unsigned_5 := Unsigned_5 ((Start + Duration) mod 2 ** Unsigned_5'Size);

      EHR_Register : End_Horizontal_Retrace_Register := Read_End_Horizontal_Retrace_Register;
   begin
         Write_Start_Horizontal_Retrace_Pulse_Register (Start_Horizontal_Retrace_Pulse_Register (Start));

         EHR_Register.EHR := Unsigned_5 (HR_End);
         Write_End_Horizontal_Retrace_Register (EHR_Register);
   end Set_Horizontal_Retrace;

   procedure Set_Vertical_Blanking (Start : Natural; Duration : Natural)
   is
      Start_Vertical_Blanking : Start_Vertical_Blanking_T := (Value => Unsigned_10 (Start), Bit_Access => False);
      --  To program the End Blanking Register with a ‘vertical blanking’ signal of width W,
      --  the following algorithm is used: the width W, in horizontal scan
      --  line units, is added to the value in the Start Vertical Blanking
      --  register minus 1. The 8 low-order bits of the result are the 8-bit
      --  value programmed.
      Vertical_Blanking_End : Natural := (Start + Duration - 1) mod 2 ** End_Vertical_Blanking_Register'Size;

      Overflow : Overflow_Register := Read_Overflow_Register;
      Maximum_Scan_Line : Maximum_Scan_Line_Register := Read_Maximum_Scan_Line_Register;
   begin
      Overflow.VBS8 := Start_Vertical_Blanking.VSB8;
      Maximum_Scan_Line.VBS9 := Start_Vertical_Blanking.VSB9;

      Write_Start_Vertical_Blanking_Register (Start_Vertical_Blanking.LSB);
      Write_Overflow_Register (Overflow);
      Write_Maximum_Scan_Line_Register (Maximum_Scan_Line);
      Write_End_Vertical_Blanking_Register (End_Vertical_Blanking_Register (Vertical_Blanking_End));
   end Set_Vertical_Blanking;

   procedure Set_Vertical_Retrace (start : Natural; duration : Natural)
   is
      Start_Vertical_Retrace : Vertical_Retrace_Start_T := (Value => Unsigned_10 (start), Bit_Access => False);

      --  To program the End Vertical Retrace bits with a signal width of W,
      --  the following algorithm is used: the width W, in
      --  horizontal scan units, is added to the value in the Start
      --  Vertical Retrace register. The 4 low-order bits of the
      --  result are the 4-bit value programmed.
      Vertical_Retrace_End : Unsigned_4 := Unsigned_4 ((Start + Duration) mod 2 ** Unsigned_4'Size);


      VRE_Register : Vertical_Retrace_End_Register := Read_Vertical_Retrace_End_Register;
      Overflow : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Vertical_Retrace_Start_Register (Start_Vertical_Retrace.LSB);

      Overflow.VRS8 := Start_Vertical_Retrace.VRS8;
      Overflow.VRS9 := Start_Vertical_Retrace.VRS9;
      Write_Overflow_Register (Overflow);


      VRE_Register.VRE := Vertical_Retrace_End;
      Write_Vertical_Retrace_End_Register (VRE_Register);
   end Set_Vertical_Retrace;


   procedure Set_Vertical_Total (total : Natural)
   is
      Vertical_Total : Vertical_Total_T := (Value => Unsigned_10 (total), Bit_Access => False);
      Overflow : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Vertical_Total_Register (Vertical_Total.LSB);
      Overflow.VT8 := Vertical_Total.VT8;
      Overflow.VT9 := Vertical_Total.VT9;
      Write_Overflow_Register (Overflow);
   end Set_Vertical_Total;

   procedure Set_Vertical_Display (display : Natural)
   is
      Vertical_Displayed : Vertical_Display_Enable_End_T := (Value => Unsigned_10 (display), Bit_Access => False);

      Overflow : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Vertical_Display_Enable_End_Register (Vertical_Displayed.LSB);
      Overflow.VDE8 := Vertical_Displayed.VDE8;
      Overflow.VDE9 := Vertical_Displayed.VDE9;
      Write_Overflow_Register (Overflow);
   end Set_Vertical_Display;


   procedure Set_Line_Compare (Line : Natural)
   is
      Line_Compare : Line_Compare_T := (Value => Unsigned_10 (Line), Bit_Access => False);
      MSL_Register : Maximum_Scan_Line_Register := Read_Maximum_Scan_Line_Register;
      Overflow : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Line_Compare_register (Line_Compare.LSB);

      Overflow.LC8 := Line_Compare.LC8;
      Write_Overflow_Register (Overflow);

      MSL_Register.LC9 := Line_Compare.LC9;
      Write_Maximum_Scan_Line_Register (MSL_Register);
   end Set_Line_Compare;

   function Compute_Needed_Memory_Map (Width, Height : Positive; Pixel_Size : Positive) return Memory_Map_Addressing
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

   function Get_Pixel_Size (Color_Depth : Positive) return Positive
   is
   begin
      case Color_Depth is
         when 256 => 
            return 8;
         when others =>
            raise Program_Error;
      end case;
   end Get_Pixel_Size;

   function Compute_Dot_Per_Pixel (Color_Depth : Positive) return Positive
   is
   begin
      if Color_Depth = 256 then
         -- In 256 mode 4 pixels are outputed from memory each dot clock
         -- Hence, 2 dot ticks are required for 1 pixel.
         return 2;
      else
         return 1;
      end if;
   end Compute_Dot_Per_Pixel;

   procedure Prepare_CRTC_For_Configuration
   is
   begin
      Write_End_Horizontal_Blanking_Register ((Display_Enable_Skew => 0, others => <>));
      Write_End_Horizontal_Retrace_Register ((HRD => 0, others => <>));
      Write_Vertical_Retrace_End_Register ((Clear_Vertical_Interrupt  => False,
                                    Enable_Vertical_Interrupt => False,
                                    Select_5_Refresh_Cycles   => False,
                                    Protect_Register          => False,
                                    others => 0));
     Write_Maximum_Scan_Line_Register ((
                                       Double_Scanning => False,
                                       others => <>));
      Write_Start_Address_High_Register (0);
      Write_Start_Address_Low_Register (0);

      Write_Cursor_Location_High_Register (0);
      Write_Cursor_Location_Low_Register (0);
   end Prepare_CRTC_For_Configuration;

   procedure Set_Graphic_Mode (Width, Height, Color_Depth : Positive)
   is
      -- HW Properties --
      CELL_GRAN_RND             : constant := 8;
      Line_Compare_Disable      : constant := 16#3FF#;

      Dot_Per_Pixel : Positive := Compute_Dot_Per_Pixel (Color_Depth);
      -- HORIZONTAL configuration --
      Character_Displayed       : Positive :=  (Util.Round (Width, CELL_GRAN_RND) / CELL_GRAN_RND) * Dot_Per_Pixel;

      -- Blanking start rigth after the last character is displayed
      Horizontal_Blank_Start    : Positive := Character_Displayed;
      Horizontal_Blank_Duration : Positive := 20; -- gtf.py

      -- Retrace start after blanking
      Horizontal_Sync_Start    : Positive := 82; -- gtf.py
      Horizontal_Sync_Duration : Positive := 8; -- gtf.py

      Horizontal_Total : Positive := 100; -- gtf.py

      -- Vertical configuration --
      Vertical_Displayed         : Positive := Height;
      Vertical_Blanking_Start    : Positive := Vertical_Displayed;
      Vertical_Blanking_Duration : Positive := 18; -- gtf.py

      Vertical_Sync_Start    : Positive := 201; -- gtf.py
      Vertical_Sync_Duration : Positive := 17; -- gtf.py

      Vertical_Total : Positive := 218; -- -- gtf.py

      -- Other configuration --
      Pixel_Per_Address   : constant := 2; -- TODO compute this value
      Memory_Address_Size : constant := 2; -- TODO compute this value
      Offset : Positive := Width / (Pixel_Per_Address * Memory_Address_Size * 2);
      Memory_Map : Memory_Map_Addressing := Compute_Needed_Memory_Map (Width, Height, Get_Pixel_Size (Color_Depth));

   begin
      Logger.Log_Info ("Horizontal_Total" & Horizontal_Total'Image);
      Logger.Log_Info ("Character_Displayed" & Character_Displayed'Image);
      Logger.Log_Info ("Vertical_Displayed" & Vertical_Displayed'Image);
      Logger.Log_Info ("Vertical_Total" & Vertical_Total'Image);
      Logger.Log_Info ("Offset" & Offset'Image);

      ----------
      -- MISC --
      ----------
      Write_Miscellaneous_Output_Register ((IOS => True, ERAM => True, CS => Clock_25M_640_320_PELs, Size => Size_400_Lines));

      ---------------
      -- Sequencer --
      ---------------
      Write_Reset_Register ((ASR => True, SR => True));
      Write_Clocking_Mode_Register ((D89 => CELL_GRAN_RND = 8,
                                     SL  => False,
                                     DC  => True,
                                     SH4 => False,
                                     SO  => False));
      Write_Map_Mask_Register ((others => True));
      Write_Character_Map_Select_Register (To_Character_Map_Select_Register (Map_2_1st_8KB, Map_2_1st_8KB));
      Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => True, Chain_4 => True));


      --------------------
      -- CRT Controller --
      --------------------
      Prepare_CRTC_For_Configuration;

      Write_Horizontal_Total_Register (Horizontal_Total_Register (Horizontal_Total - 5));
      Write_Horizontal_Display_Enable_End_Register (Horizontal_Display_Enable_End_Register (Character_Displayed - 1));
      Set_Horizontal_Blanking (Character_Displayed, Horizontal_Blank_Duration);
      Set_Horizontal_Retrace (Horizontal_Sync_Start, Horizontal_Sync_Duration);

      Set_Vertical_Total (Vertical_total - 2);
      Set_Vertical_Display (Vertical_Displayed - 1);
      Set_Vertical_Retrace (Vertical_Sync_Start, Vertical_Sync_Duration);
      Set_Vertical_Blanking (Vertical_Blanking_Start, Vertical_Blanking_Duration);

      Set_Line_Compare (Line_Compare_Disable);
      Write_Cursor_Start_Register ((Row_Scan_Cursor_Begins => 0, Cursor_Off => False));
      Write_Cursor_End_Register ((Row_Scan_Cursor_Ends => 0, Cursor_Skew_Control => 0));

      Write_Offset_Register (Offset_Register (Offset));
      Write_Underline_Location_Register ((Start_Under_Line => 0, Count_By_4 => False, Double_Word => True, others => <>));

      Write_Maximum_Scan_Line_Register ((MSL           => 1 - 1,
                                       Double_Scanning => False,
                                       others => 0));


      Write_CRT_Mode_Control_Register ((CSM_0         => True,
                                       SRC            => True,
                                       HRS            => False,
                                       Count_By_2     => False,
                                       Address_Wrap   => True,
                                       Word_Byte_Mode => False,
                                       Hardware_Reset => True));
      Logger.Log_Info ("Setting GC");
      Write_Set_Reset_Register((SR0 => False, SR1 => False, SR2 => False, SR3 => False));
      Write_Enable_Set_Reset_Register ((ESR0 => False, ESR1 => False, ESR2 => False, ESR3 => False));
      Write_Color_Compare_Register ((CC0 => False, CC1 => False, CC2 => False, CC3 => False));
      Write_Data_Rotate_Register ((Rotate_Count => 0, Function_Select => No_Function));
      Write_Read_Map_Select_Register (0);
      Write_Graphics_Mode_Register ((WM                  => Mode_0,
                                     Read_Mode           => False,
                                     Odd_Even            => False,
                                     Shift_Register_Mode => False,
                                     Color_Mode          => True));
      Write_Miscellaneous_Register ((Graphics_Mode => True, Odd_Even => False, Memory_Map => Memory_Map));
      Write_Color_Dont_Care_Register ((M0X => True, M1X => True, M2X => True, M3X => True));
      Write_Bit_Mask_Register ((others => True));

      Logger.Log_Info ("Setting Attribute");
      Reset_Attribute_Register;
      for i in Internal_Palette_Register_Index range 0 .. 15 loop
         Write_Internal_Palette_Register (i, Internal_Palette_Register (i));
      end loop;

      Write_Attribute_Mode_Control_Register ((Graphic_Mode              => True,
                                          Mono_Emulation            => False,
                                          Enable_Line_Graphics      => False,
                                          Enable_Blink              => False,
                                          PEL_Panning_Compatibility => False,
                                          PEL_Width                 => True,
                                          P5_P4_Select              => False));
      Write_Overscan_Color_Register (0);
      Write_Color_Plane_Enable_Register (16#0F#);
      Write_Horizontal_PEL_Panning_Register (16#00#);
      Write_Color_Select_Register ((Select_Color_4 => False,
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

   procedure enable_320x200x256 is
      -- HW_SPECIFIC --
      Vertical_total   : constant := 449; -- Number of horizontal pixel
      Horizontal_Total : constant := 100;


      -- Mode_Specific --
      Pixel_Per_Character : constant := 8;
      Width  : constant := 320;
      Height : constant := 200;

      Vertical_Displayed     : constant := 400;
      Scan_Per_Character_Row : constant := Vertical_Displayed / Height;
      
      Memory_Map : Memory_Map_Addressing := Compute_Needed_Memory_Map (Width, Height, 8);


      Pixel_Per_Address : constant := 2;
      Memory_Address_Size  : constant := 2;

      Offset : constant := Width / (Pixel_Per_Address * Memory_Address_Size * 2);
      
      -- CRTC Variable --
      Horizontal_Displayed       : constant := 80;
      Horizontal_Sync_Start      : constant := 84;
      Horizontal_Sync_Duration   : constant := 12;
   
      Horizontal_Blanking_Character_Start    : constant := (Width / Pixel_Per_Character) * 2;
      Horizontal_Blanking_Character_Duration : constant := 18;


      Vertical_Sync_Start    : constant := 412;
      Vertical_Sync_Duration : constant := 18;

      Vertical_Blanking_Start : constant :=  406;
      Vertical_Blanking_Duration : constant := 36;

      Line_Compare_Disable : constant := 16#3FF#;

      Regenerative_Buffer : Start_Address_T := (Value => 0, Bit_Access => False);
   begin
      ----------
      -- MISC --
      ----------
      Write_Miscellaneous_Output_Register ((IOS => True, ERAM => True, CS => Clock_25M_640_320_PELs, Size => Size_400_Lines));

      ---------------
      -- Sequencer --
      ---------------
      Logger.Log_Info ("Sequencer");
      Write_Reset_Register ((ASR => True, SR => True));
      Write_Clocking_Mode_Register ((D89 => Pixel_Per_Character = 8,
                                     SL  => False,
                                     DC  => True,
                                     SH4 => False,
                                     SO  => False));
      Write_Map_Mask_Register ((Map_0_Enable => True,
                                Map_1_Enable => True,
                                Map_2_Enable => True,
                                Map_3_Enable => True));
      Write_Character_Map_Select_Register (To_Character_Map_Select_Register (Map_2_1st_8KB, Map_2_1st_8KB));
      Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => True, Chain_4 => True));
      
      --------------------
      -- CRT Controller --
      --------------------
      Logger.Log_Info ("Setting CRTC");

      -- Size_Setup --
      Write_Horizontal_Total_Register (Horizontal_Total - 5);
      Write_Horizontal_Display_Enable_End_Register (Horizontal_Displayed - 1);

      -- Clear_Register --
      Write_End_Horizontal_Blanking_Register ((Display_Enable_Skew => 0, others => <>));
      Write_End_Horizontal_Retrace_Register ((HRD => 0, others => <>));
      Write_Vertical_Retrace_End_Register ((VRE                       => 0,
                                    Clear_Vertical_Interrupt  => False,
                                    Enable_Vertical_Interrupt => False,
                                    Select_5_Refresh_Cycles   => False,
                                    Protect_Register          => False));
     Write_Maximum_Scan_Line_Register ((MSL           => Scan_Per_Character_Row - 1,
                                       Double_Scanning => False,
                                       others => 0));
      Write_Overflow_Register ((others => 0));
      Write_Preset_Row_Scan_Register ((Starting_Row_Scan_Count => 0, Byte_Panning => 0, others => <>));

      Set_Horizontal_Retrace (Horizontal_Sync_Start, Horizontal_Sync_Duration);
      Set_Horizontal_Blanking (Horizontal_Blanking_Character_Start, Horizontal_Blanking_Character_Duration);

      Set_Vertical_Total (Vertical_total - 2);
      Set_Vertical_Display (Vertical_Displayed - 1);
      Set_Vertical_Retrace (Vertical_Sync_Start, Vertical_Sync_Duration);
      Set_Vertical_Blanking (Vertical_Blanking_Start, Vertical_Blanking_Duration);

      Set_Line_Compare (Line_Compare_Disable);

      Write_Cursor_Start_Register ((Row_Scan_Cursor_Begins => 0, Cursor_Off => False));
      Write_Cursor_End_Register ((Row_Scan_Cursor_Ends => 0, Cursor_Skew_Control => 0));

      -- Start_Address --
      Write_Start_Address_High_Register (0);
      Write_Start_Address_Low_Register (0);

      -- Cursor_Logation --
      Write_Cursor_Location_High_Register (0);
      Write_Cursor_Location_Low_Register (0);

      Write_Offset_Register (Offset);
      Write_Underline_Location_Register ((Start_Under_Line => 0, Count_By_4 => False, Double_Word => True, others => <>));


      Write_CRT_Mode_Control_Register ((CSM_0          => True,
                                       SRC            => True,
                                       HRS            => False,
                                       Count_By_2     => False,
                                       Address_Wrap   => True,
                                       Word_Byte_Mode => False,
                                       Hardware_Reset => True));

      -------------------------
      -- Graphics Controller --
      -------------------------
      Logger.Log_Info("Setting GC");
      Write_Set_Reset_Register((SR0 => False, SR1 => False, SR2 => False, SR3 => False));
      Write_Enable_Set_Reset_Register ((ESR0 => False, ESR1 => False, ESR2 => False, ESR3 => False));
      Write_Color_Compare_Register ((CC0 => False, CC1 => False, CC2 => False, CC3 => False));
      Write_Data_Rotate_Register ((Rotate_Count => 0, Function_Select => No_Function));
      Write_Read_Map_Select_Register (0);
      Write_Graphics_Mode_Register ((WM                  => Mode_0,
                                     Read_Mode           => False,
                                     Odd_Even            => False,
                                     Shift_Register_Mode => False,
                                     Color_Mode          => True));
      Write_Miscellaneous_Register ((Graphics_Mode => True, Odd_Even => False, Memory_Map => Memory_Map));
      Write_Color_Dont_Care_Register ((M0X => True, M1X => True, M2X => True, M3X => True));
      Write_Bit_Mask_Register (Register => (others => True));

      --------------------------
      -- Attribute Controller --
      --------------------------
      Logger.Log_Info ("Setting Attribute");
      Reset_Attribute_Register;
      Write_Internal_Palette_Register (0, 16#0#);
      Write_Internal_Palette_Register (1, 16#01#);
      Write_Internal_Palette_Register (2, 16#02#);
      Write_Internal_Palette_Register (3, 16#03#);
      Write_Internal_Palette_Register (4, 16#04#);
      Write_Internal_Palette_Register (5, 16#05#);
      Write_Internal_Palette_Register (6, 16#06#);
      Write_Internal_Palette_Register (7, 16#07#);
      Write_Internal_Palette_Register (8, 16#08#);
      Write_Internal_Palette_Register (9, 16#09#);
      Write_Internal_Palette_Register (10, 16#0A#);
      Write_Internal_Palette_Register (11, 16#0B#);
      Write_Internal_Palette_Register (12, 16#0C#);
      Write_Internal_Palette_Register (13, 16#0D#);
      Write_Internal_Palette_Register (14, 16#0E#);
      Write_Internal_Palette_Register (15, 16#0F#);

      Write_Attribute_Mode_Control_Register ((Graphic_Mode              => True,
                                              Mono_Emulation            => False,
                                              Enable_Line_Graphics      => False,
                                              Enable_Blink              => False,
                                              PEL_Panning_Compatibility => False,
                                              PEL_Width                 => True,
                                              P5_P4_Select              => False));
      Write_Overscan_Color_Register (0);
      Write_Color_Plane_Enable_Register (16#0F#);
      Write_Horizontal_PEL_Panning_Register (16#00#);
      Write_Color_Select_Register ((Select_Color_4 => False,
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
   end enable_320x200x256;
   
end VGA;