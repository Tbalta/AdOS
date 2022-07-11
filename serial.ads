with x86;
with System.Storage_Elements; use System.Storage_Elements;
with Interfaces; use Interfaces;

package SERIAL is
    pragma Preelaborate (SERIAL);
    subtype Baudrate is Natural range 1 .. 115200;
    type SerialPorts is (COM1, COM2, COM3, COM4, COM5, COM6);

    subtype Divisor is Unsigned_16 range 0 .. Unsigned_16'Last;
    procedure serial_init(rate : in Baudrate);
    procedure send_char (c : in Character);

private
end SERIAL;