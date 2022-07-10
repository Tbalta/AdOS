with arch.x86;

package SERIAL is
    type baudrate_T is (b_115200, b_57600, b_38400 );
    type parity is (p_none, p_odd, p_even );

    for baudrate_T use (
        b_115200 => 1,
        b_57600 => 2,
        b_38400 => 3
    );
    for parity use (
        p_none => 0,
        p_odd => 1,
        p_even => 3
    );
    
    procedure serial_init(baudrate : in baudrate_T);

private
end SERIAL;