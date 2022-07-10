with x86;

package body SERIAL is
    pragma Preelaborate;

    procedure serial_init (baudrate : in baudrate_T) is
    begin
        x86.outb(SERIAL_PORT, SERIAL_INIT);
    end serial_init;
end SERIAL;