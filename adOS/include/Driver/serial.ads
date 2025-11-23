with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System;
with System.Storage_Elements; use System.Storage_Elements;

package SERIAL is
   pragma Preelaborate (SERIAL);
   subtype Baudrate is Natural range 1 .. 115_200;
   type SerialPorts is (COM1, COM2, COM3, COM4, COM5, COM6);

   subtype Divisor is Unsigned_16 range 0 .. Unsigned_16'Last;
   procedure serial_init (rate : Baudrate);
   procedure send_char (c : Character);
   procedure send_cchar (c : Interfaces.C.char)
   with Export, Convention => C, External_Name => "send_cchar";
   procedure send_string (data : String);
   procedure send_uint (data : Interfaces.Unsigned_32);
   procedure send_hex (data : Interfaces.Unsigned_32);
   procedure send_line (data : in String)
   with Export, Convention => Ada, External_Name => "__gnat_debug_log";
   procedure send_raw_buffer (buffer : System.Address; size : Storage_Count);


private
   procedure set_baud_rate (serial_divisor : Divisor);
   function can_send_byte return Standard.Boolean;
end SERIAL;
