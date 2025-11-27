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
package body VGA is
   use Standard.ASCII;
   package Logger renames Log.Serial_Logger;

   procedure Switch_To_Mode (mode : Graphic_Mode)
   is
   begin
      System.Machine_Code.Asm (
         "xor %%ah, %%ah" & LF &
         "mov %0, %%al"   & LF &
         "int $0x10",
      Inputs => (Graphic_Mode'Asm_Input("g", mode)),
      Volatile => True,
      Clobber => "eax");
   end Switch_To_Mode;

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

   procedure Set_Horizontal_Blanking (Blanking_Start : Horizontal_Blanking_Start; Blanking_Duration : Unsigned_6)
   is
      Blanking_Duration_Breakdown : End_Blanking_T := (Value => Blanking_Duration, Bit_Access => False);
      EHB_Register : End_Horizontal_Blanking_Register := Read_End_Horizontal_Blanking_Register;
      EHR_Register : End_Horizontal_Retrace_Register := Read_End_Horizontal_Retrace_Register;
   begin
         Write_Start_Horizontal_Blanking_Register (Blanking_Start);

         EHB_Register.End_Blanking := Blanking_Duration_Breakdown.LSB;
         Write_End_Horizontal_Blanking_Register (EHB_Register);

         EHR_Register.EB5 := Blanking_Duration_Breakdown.MSB;
         Write_End_Horizontal_Retrace_Register (EHR_Register);
   end Set_Horizontal_Blanking;
   

   procedure Set_Horizontal_Retrace (Retrace_Start : Start_Horizontal_Retrace_Pulse_Register; Retrace_Duration : Unsigned_5)
   is
      EHR_Register : End_Horizontal_Retrace_Register := Read_End_Horizontal_Retrace_Register;
   begin
         Write_Start_Horizontal_Retrace_Pulse_Register (Retrace_Start);

         EHR_Register.EHR := Retrace_Duration;
         Write_End_Horizontal_Retrace_Register (EHR_Register);
   end Set_Horizontal_Retrace;
   
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

   procedure Set_vertical_Sync (start : Natural; duration : Natural)
   is
      Retrace_Start : Vertical_Retrace_Start_T := (Value => Unsigned_10 (start), Bit_Access => False);
      VRE_Register : Vertical_Retrace_End_Register := Read_Vertical_Retrace_End_Register;
      Overflow : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Vertical_Retrace_Start_Register (Retrace_Start.LSB);

      Overflow.VRS8 := Retrace_Start.VRS8;
      Overflow.VRS9 := Retrace_Start.VRS9;
      Write_Overflow_Register (Overflow);


      VRE_Register.VRE := Unsigned_4 (duration);
      Write_Vertical_Retrace_End_Register (VRE_Register);
   end Set_vertical_Sync;

   procedure Set_Vertical_Blanking (Start : Natural; Duration : Natural)
   is
      Start_Vertical_Blanking : Start_Vertical_Blanking_T := (Value => Unsigned_10 (Start), Bit_Access => False);
      Blanking_Duration : End_Vertical_Blanking_Register := End_Vertical_Blanking_Register (Duration);

      Overflow : Overflow_Register := Read_Overflow_Register;
      Maximum_Scan_Line : Maximum_Scan_Line_Register := Read_Maximum_Scan_Line_Register;
   begin
      Overflow.VBS8 := Start_Vertical_Blanking.VSB8;
      Maximum_Scan_Line.VBS9 := Start_Vertical_Blanking.VSB9;

      Write_Start_Vertical_Blanking_Register (Start_Vertical_Blanking.LSB);
      Write_Overflow_Register (Overflow);
      Write_Maximum_Scan_Line_Register (Maximum_Scan_Line);
      Write_End_Vertical_Blanking_Register (Blanking_Duration);
   end Set_Vertical_Blanking;

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



   procedure enable_320x200x256 is
      Width : constant := 320;
      Pixel_Per_Address : constant := 2;
      Memory_Address_Size  : constant := 2;

      Offset : constant := Width / (Pixel_Per_Address * Memory_Address_Size * 2);
      
      -- CRTC Variable --
      Horizontal_Total     : constant := 100;
      Horizontal_Displayed : constant := 80;
      Horizontal_Sync_Start      : constant := 84;
      Horizontal_Sync_Duration   : constant := 0;
   
      Horizontal_Blanking_Character_Start    : constant := 80;
      Horizontal_Blanking_Character_Duration : constant := 34;


      Vertical_total         : constant := 449;
      Vertical_Displayed     : constant := 400;
      Vertical_Sync_Start    : constant := 412;
      Vertical_Sync_Duration : constant := 14;

      Vertical_Blanking_Duration : constant := 186;
      Vertical_Blanking_Start : constant :=  406;

      Line_Compare_Disable : constant := 16#3FF#;
      Scan_Per_Character_Row : constant := 2;

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
      Write_Clocking_Mode_Register ((D89 => True,
                                     SL  => False,
                                     DC  => False,
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
      Set_vertical_Sync (Vertical_Sync_Start, Vertical_Sync_Duration);
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

      --  Write_Vertical_Display_Enable_End_Register (Vertical_Display_Enable_End.LSB);
      Write_Offset_Register (Offset);
      Write_Underline_Location_Register ((Start_Under_Line => 0, Count_By_4 => False, Double_Word => True, others => <>));

      -- Vertical_Blanking --
      Write_End_Vertical_Blanking_Register (186 - 1);


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
      Write_Miscellaneous_Register ((Graphics_Mode => True, Odd_Even => False, Memory_Map => A0000_64KB));
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