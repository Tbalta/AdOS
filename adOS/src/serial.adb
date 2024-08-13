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
      divisor_high := Unsigned_8 (Shift_Right (serial_divisor, 8) and 16#FF#);
      x86.Port_IO.Outb (port + Storage_Offset (4), 16#80#);
      x86.Port_IO.Outb (port + Storage_Offset (1), divisor_low);
      x86.Port_IO.Outb (port + Storage_Offset (2), divisor_high);
      x86.Port_IO.Outb (port + Storage_Offset (4), 16#03#);
      x86.Port_IO.Outb (port + Storage_Offset (3), 16#47#);
   end set_baud_rate;

   function can_send_byte return Standard.Boolean is
      port : constant System.Address := To_Address (16#3F8#);
   begin
      return
        ((x86.Port_IO.Inb (port + Storage_Offset (5)) and 16#20#) = 16#20#);
   end can_send_byte;

   procedure send_string (data : String) is
   begin
      for character in data'Range loop
         send_char (data (character));
      end loop;
   end send_string;

   procedure send_uint (data : Interfaces.Unsigned_32) is
   begin
      if data /= 0 then
         send_uint (data / 10);
      end if;
      send_char (Character'Val ((data mod 10) + (Character'Pos ('0'))));
   end send_uint;

   procedure send_hex (data : Interfaces.Unsigned_32) is
      hex_array : constant String := "0123456789ABCDEF";
      procedure recur (number : Interfaces.Unsigned_32);
      procedure recur (number : Interfaces.Unsigned_32) is
      begin
         if number = 0 then
            return;
         end if;
         recur (number / 16);
         send_char (hex_array (Integer (number mod 16) + 1));
      end recur;
   begin
      if data = 0 then
         send_char ('0');
      end if;
      recur (data);
   end send_hex;

   procedure send_char (c : Character) is
      port : constant System.Address := To_Address (16#3F8#);
   begin
      x86.Port_IO.Outb (port + Storage_Offset (0), Character'Pos (c));
   end send_char;
   procedure serial_init (rate : Baudrate) is
   begin
      while not can_send_byte loop
         null;
      end loop;
      set_baud_rate (Divisor (rate / Baudrate'Last));
   end serial_init;
end SERIAL;
