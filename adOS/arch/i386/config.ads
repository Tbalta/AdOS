with System;
with x86; use x86;
with Interfaces;
package config is

   pragma Preelaborate;

   LD_Kernel_Start : constant System.Address;
   pragma Import (C, LD_Kernel_Start, "__kernel_start");

   LD_Kernel_End : constant System.Address;
   pragma Import (C, LD_Kernel_End, "__kernel_end");

   STACK_CHK_GUARD : Interfaces.Unsigned_32 := 16#e2dee396#;
   pragma Export (C, STACK_CHK_GUARD, "__stack_chk_guard");

   Kernel_Start : constant Physical_Address := Physical_Address (LD_Kernel_Start'Address);
   Kernel_End   : constant Physical_Address := Physical_Address (LD_Kernel_End'Address);
end config;
