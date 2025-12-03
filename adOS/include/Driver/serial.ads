with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with x86.Port_IO;

package SERIAL is
   pragma Pure;
   subtype Baudrate is Natural range 1 .. 115_200;

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
   COM1 : constant x86.Port_IO.Port_Address := 16#3F8#;
   COM2 : constant x86.Port_IO.Port_Address := 16#2F8#;
   COM3 : constant x86.Port_IO.Port_Address := 16#3E8#;
   COM4 : constant x86.Port_IO.Port_Address := 16#2E8#;
   COM5 : constant x86.Port_IO.Port_Address := 16#5F8#;
   COM6 : constant x86.Port_IO.Port_Address := 16#4F8#;
   COM8 : constant x86.Port_IO.Port_Address := 16#4E8#;
   COM7 : constant x86.Port_IO.Port_Address := 16#5E8#;
   procedure set_baud_rate (serial_divisor : Divisor);
   function can_send_byte return Standard.Boolean;

end SERIAL;
