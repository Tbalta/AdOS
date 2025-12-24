with Ada;
with SERIAL;
with Generic_Logger;
with VGA.Terminal;

with Interfaces;
with Interfaces.C;
package Log is
   pragma Preelaborate;

   procedure Serial_Send_Line (Message : in String);
   package Serial_Logger is new Generic_Logger (Print_Function => Serial_Send_Line);
   package VGA_Logger is new Generic_Logger (Print_Function => VGA.Terminal.Put_String);

   procedure Log_Message (Message : in String);
   procedure Log_Error (Error_Message : in String);
   procedure Log_Info (Info_Message : in String)
      with Export, Convention => Ada, External_Name => "__gnat_debug_log";
   procedure Log_Ok (Ok_Message : in String);
   procedure Log_Warning (Warning_Message : in String);
   procedure Panic (Panic_Message : in String);
   pragma Export (Ada, Panic, "ADA_PANIC");
   procedure Log_C_Char (c : Interfaces.C.char)
      with Export, Convention => C, External_Name => "send_cchar";
end Log;
