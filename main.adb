with SERIAL;
with x86.gdt;
with Interfaces;
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
   SERIAL.send_string ("Hello world!");

   for i in 0 .. 16 loop
      SERIAL.send_hex (Interfaces.Unsigned_32 (i));
   end loop;

   x86.gdt.initialize_gdt;
   SERIAL.send_string ("finish");
   declare
      test : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (25);
   begin
      SERIAL.send_string (Interfaces.Unsigned_32'Image (test));
   end;
   --  Loop forever.
   while True loop
      null;
   end loop;

end Main;
