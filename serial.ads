with Interfaces; use Interfaces;

package SERIAL is
   pragma Preelaborate (SERIAL);
   subtype Baudrate is Natural range 1 .. 115_200;
   type SerialPorts is (COM1, COM2, COM3, COM4, COM5, COM6);

   subtype Divisor is Unsigned_16 range 0 .. Unsigned_16'Last;
   procedure serial_init (rate : Baudrate);
   procedure send_char (c : Character);

private
   procedure set_baud_rate (serial_divisor : Divisor);
end SERIAL;
