with x86.Port_IO;
with System.Storage_Elements; use System.Storage_Elements;

package body SERIAL is
pragma Suppress (Index_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);
   procedure set_baud_rate (serial_divisor : Divisor) is
      divisor_low  : Interfaces.Unsigned_8;
      divisor_high : Interfaces.Unsigned_8;
      port         : constant System.Address := To_Address (16#3F8#);
   begin
      divisor_low  := Unsigned_8 (serial_divisor and 16#FF#);
      divisor_high :=
        Unsigned_8 (Shift_Right (serial_divisor, 8) and 16#FF#);
      x86.Port_IO.Outb (port + Storage_Offset (4), 16#80#);
      x86.Port_IO.Outb (port + Storage_Offset (1), divisor_low);
      x86.Port_IO.Outb (port + Storage_Offset (2), divisor_high);
      x86.Port_IO.Outb (port + Storage_Offset (4), 16#03#);
      x86.Port_IO.Outb (port + Storage_Offset (3), 16#47#);
   end set_baud_rate;
   procedure send_char (c : Character) is
      port : constant System.Address := To_Address (16#3F8#);
   begin
      x86.Port_IO.Outb (port + Storage_Offset (0), Character'Pos (c));
   end send_char;
   procedure serial_init (rate : Baudrate) is
   begin
      set_baud_rate (Divisor (rate / Baudrate'Last));
   end serial_init;
end SERIAL;
