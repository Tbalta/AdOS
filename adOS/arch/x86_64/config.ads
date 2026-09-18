with System;
with x86; use x86;

with System.Storage_Elements; use System.Storage_Elements;
package config is

   pragma Preelaborate;

   LD_Kernel_Start : constant System.Address;
   pragma Import (C, LD_Kernel_Start, "__kernel_start");

   LD_Kernel_End : constant System.Address;
   pragma Import (C, LD_Kernel_End, "__kernel_end");

   Kernel_Start : constant System.Address :=  LD_Kernel_Start'Address;
   Kernel_End   : constant System.Address :=  LD_Kernel_End'Address;

   function Kernel_Size return Storage_Count is (Storage_Count (Kernel_End - Kernel_Start));
   function Is_Kernel_Address (Address : Virtual_Address) return Boolean;
   function Is_Kernel_Address (Address : Physical_Address) return Boolean;
end config;
