with System;
with x86; use x86;

package config is

   pragma Preelaborate;

   LD_Kernel_Start : constant System.Address;
   pragma Import (C, LD_Kernel_Start, "__kernel_start");

   LD_Kernel_End : constant System.Address;
   pragma Import (C, LD_Kernel_End, "__kernel_end");

   Kernel_Start : constant Virtual_Address := Virtual_Address (LD_Kernel_Start'Address);
   Kernel_End   : constant Virtual_Address := Virtual_Address (LD_Kernel_End'Address);
end config;
