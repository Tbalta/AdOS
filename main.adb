with SERIAL;
procedure Main is

   --  Suppress some checks to prevent undefined references during linking to
   --
   --    __gnat_rcheck_CE_Range_Check
   --    __gnat_rcheck_CE_Overflow_Check
   --
   --  These are Ada Runtime functions (see also GNAT's a-except.adb).

   pragma Suppress (Index_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);

begin

   --  Clear (BLACK);
   --  Put_String (0, 0, BRIGHT, BLACK, "Ada says: Hello world!");
   SERIAL.serial_init (SERIAL.Baudrate'Last);
   SERIAL.send_char ('H');
   SERIAL.send_char ('e');
   SERIAL.send_char ('l');
   SERIAL.send_char ('l');
   SERIAL.send_char ('o');

   --  Loop forever.
   while True loop
      null;
   end loop;

end Main;
