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
   
   procedure test is
      --  SR_Reg : Set_Reset_Register;
      --  GM_Reg : Graphics_Mode_Register;
      --  function inb is new x86.Port_IO.Inb (Miscellaneous_Output_Register);
   begin
      Logger.Log_Info (Read_Miscellaneous_Output_Register'Image);
      Logger.Log_Info (Read_Set_Reset_Register'Image);
      Logger.Log_Info (Read_Graphics_Mode_Register'Image);
      Logger.Log_Info (Read_Enable_Set_Reset_Register'Image);
   end test;

   procedure enable_320x200x256 is
   begin
      -- MISC
      Write_Miscellaneous_Output_Register ((IOS => True, ERAM => True, CS => Clock_25M_640_320_PELs, Size => Size_400_Lines));
      --  Write_Miscellaneous_Output_Register (16#43#);
      -- Sequencer
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
      -- CRTC
      Logger.Log_Info ("Setting CRTC");
      Write_Horizontal_Total_Register (Register => (16#5F#));
      Write_Horizontal_Display_Enable_End_Register (Register => (16#4F#));
      Write_Start_Horizontal_Blanking_Register (Register => (16#50#));
      Write_End_Horizontal_Blanking_Register ((End_Blanking => 2, Display_Enable_Skew => 0, others => <>));
      Write_Start_Horizontal_Retrace_Pulse_Register (Register => 16#54#);
      Write_End_Horizontal_Retrace_Register ((EHR => 0, HRD => 0, EB5 => 1));
      Write_Vertical_Total_Register (16#BF#);
      Write_Overflow_Register ((VT8  => 1,
                              VDE8 => 1,
                              VRS8 => 1,
                              VBS8 => 1,
                              LC8  => 1,
                              VT9  => 0,
                              VDE9 => 0,
                              VRS9 => 0));
      Write_Preset_Row_Scan_Register ((Starting_Row_Scan_Count => 0, Byte_Panning => 0, others => <>));
      Write_Maximum_Scan_Line_Register ((MSL             => 1,
                                       VBS9            => 0,
                                       LC9             => 1,
                                       Double_Scanning => False));
      Write_Cursor_Start_Register ((Row_Scan_Cursor_Begins => 0, Cursor_Off => False));
      Write_Cursor_End_Register ((Row_Scan_Cursor_Ends => 0, Cursor_Skew_Control => 0));
      Write_Start_Address_High_Register (0);
      Write_Start_Address_Low_Register (0);
      Write_Cursor_Location_High_Register (0);
      Write_Cursor_Location_Low_Register (0);
      Write_Vertical_Retrace_Start_Register (16#9C#);
      Write_Vertical_Retrace_End_Register ((VRE                       => 16#E#,
                                          Clear_Vertical_Interrupt  => False,
                                          Enable_Vertical_Interrupt => False,
                                          Select_5_Refresh_Cycles   => False,
                                          Protect_Register          => False));
      Write_Vertical_Display_Enable_End_Register (16#8F#);
      Write_Offset_Register (16#28#);
      Write_Underline_Location_Register ((Start_Under_Line => 0, Count_By_4 => False, Double_Word => True, others => <>));
      Write_Start_Vertical_Blanking_Register (16#96#);
      Write_End_Vertical_Blanking_Register (16#B9#);
      Write_CRT_Mode_Control_Register ((CSM_0          => True,
                                       SRC            => True,
                                       HRS            => False,
                                       Count_By_2     => False,
                                       Address_Wrap   => True,
                                       Word_Byte_Mode => False,
                                       Hardware_Reset => True));
      Write_Line_Compare_Register (16#FF#);

      -- Graphics Controller
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

      -- Attribute Controller
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
      Select_Internal_Palette_Register (16#0#);
      load_default_palette;

      -- Reenable IPAS for normal operations
      Reset_Attribute_Register;
      Select_Internal_Palette_Register (16#20#);
   end enable_320x200x256;
   
end VGA;