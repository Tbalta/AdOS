with VGA;
with x86.Port_IO;
with Log;
with Interfaces; use Interfaces;
with System;
with System.Machine_Code;
with VGA.Graphic_Controller; use VGA.Graphic_Controller;
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
      Write_Miscellaneous_Output_Register ((IOS => True, ERAM => True, CS => Clock_25M_640_320_PELs, Size => Size_400_Lines));
      
   end enable_320x200x256;
   
end VGA;