with SERIAL;
with Generic_Logger;
package Log is
   pragma Preelaborate;

   package Serial_Logger is new Generic_Logger (Print_Function => SERIAL.send_line);
end Log;