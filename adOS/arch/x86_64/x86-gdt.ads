with Interfaces; use Interfaces;
with System;     use System;

package x86.gdt is
   pragma Preelaborate (x86.gdt);

   procedure initialize_gdt;

end x86.gdt;
