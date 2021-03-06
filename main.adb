with SERIAL;
with x86.gdt;
with x86.idt;
with System.Machine_Code;
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

begin

   --  Clear (BLACK);
   --  Put_String (0, 0, BRIGHT, BLACK, "Ada says: Hello world!");
   SERIAL.serial_init (SERIAL.Baudrate'Last);
   x86.gdt.initialize_gdt;
   x86.idt.init_idt;
   SERIAL.send_line ("test");
   declare
      procedure setup_PIC;
      pragma Import (C, setup_PIC, "setup_PIC");
   begin
      setup_PIC;
   end;

   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   SERIAL.send_line ("trac");
   --  declare
   --     test  : constant Integer := 0;
   --     plouf : constant Integer          := 0;
   --     function func return Integer;
   --     function func return Integer is
   --     begin
   --        return plouf / test;
   --     end func;
   --  begin
   --     -- plouf := func;
   --     SERIAL.send_uint (Unsigned_32 (plouf));
   --  end;
   SERIAL.send_line ("plouf");
   while True loop
      System.Machine_Code.Asm (Template => "hlt", Volatile => True);
   end loop;

   --  Loop forever.

end Main;
