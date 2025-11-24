with x86.Port_IO;
with Log;
with Interfaces; use Interfaces;
with System;
package body VGA is
   package Logger renames Log.Serial_Logger;
   
   procedure test is
      misc_reg : Miscellaneous_Output_Register;
      function inb is new x86.Port_IO.Inb (Miscellaneous_Output_Register);
   begin
      misc_reg := inb (System.Address (16#3CC#));
      Logger.Log_Info ("misc_reg: " & misc_reg'Image);
   end test;
   
end VGA;