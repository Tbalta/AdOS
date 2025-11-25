with VGA;
with x86.Port_IO;
with Log;
with Interfaces; use Interfaces;
with System;
with System.Machine_Code;
with VGA.Graphic_Controller; use VGA.Graphic_Controller;
with VGA.Sequencer; use VGA.Sequencer;

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
      -- Sequencer
      Write_Reset_Register ((ASR => True, SR => True));
      Write_Clocking_Mode_Register ((D89 => False,
                                     SL  => False,
                                     DC  => False,
                                     SH4 => False,
                                     SO  => False));
      Write_Map_Mask_Register ((Map_0_Enable => True,
                                Map_1_Enable => True,
                                Map_2_Enable => False,
                                Map_3_Enable => False));
      Write_Character_Map_Select_Register (To_Character_Map_Select_Register (Map_2_1st_8KB, Map_2_1st_8KB));
      Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => False, Chain_4 => False));
      -- CRTC
   end enable_320x200x256;
   
end VGA;