with SERIAL;
with x86.gdt;
with x86.idt;
with pic;
with System.Machine_Code;
with Atapi;
--  with Interfaces; use Interfaces;
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
   --  procedure discover_atapi_drive;
   --  pragma Import (C, discover_atapi_drive, "discover_atapi_drive");
begin

   --  Clear (BLACK);
   --  Put_String (0, 0, BRIGHT, BLACK, "Ada says: Hello world!");
   SERIAL.serial_init (SERIAL.Baudrate'Last);
   x86.gdt.initialize_gdt;
   x86.idt.init_idt;
   SERIAL.send_line ("test");
   pic.init;

   Atapi.discoverAtapiDevices;
   --  discover_atapi_drive;
   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   SERIAL.send_line ("trac");
   SERIAL.send_line ("plouf");
   while True loop
      System.Machine_Code.Asm (Template => "hlt", Volatile => True);
   end loop;

   --  Loop forever.

end Main;
