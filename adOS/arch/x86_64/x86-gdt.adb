with System.Storage_Elements; use System.Storage_Elements;
with SERIAL;                  use SERIAL;
with System.Machine_Code;     use System.Machine_Code;
with x86.gdt;
with Loggers;

package body x86.gdt is
   use Standard.ASCII;
   pragma Suppress (Index_Check);
   pragma Suppress (Range_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);
   package Logger renames Loggers.VGA_Logger;


   procedure initialize_gdt is
   begin
      null;
   end initialize_gdt;
end x86.gdt;
