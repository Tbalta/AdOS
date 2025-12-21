with Ada;
with SERIAL;
with Generic_Logger;
with VGA.Terminal;
package Log is
   pragma Preelaborate;

   package Serial_Logger is new Generic_Logger (Print_Function => SERIAL.send_line);
   package VGA_Logger is new Generic_Logger (Print_Function => VGA.Terminal.Put_String);

   procedure Log_Message (Message : in String);
   procedure Log_Error (Error_Message : in String);
   procedure Log_Info (Info_Message : in String);
   procedure Log_Ok (Ok_Message : in String);
   procedure Log_Warning (Warning_Message : in String);
   procedure Panic (Panic_Message : in String);
   pragma Export (Ada, Panic, "ADA_PANIC");
end Log;
