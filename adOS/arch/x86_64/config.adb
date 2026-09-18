with Limine;
with System;
with x86; use x86;

with System.Storage_Elements; use System.Storage_Elements;
package body config is
   

   function Is_Kernel_Address (Address : Virtual_Address) return Boolean is ((Address in To_Virtual_Address (Kernel_Start) .. To_Virtual_Address (Kernel_End)));
   function Is_Kernel_Address (Address : Physical_Address) return Boolean is 
      Kernel_Physical_Start : Physical_Address := Physical_Address (Limine.executable_address_response.physical_base);
      Kernel_Physical_End   : Physical_Address := Kernel_Physical_Start + Kernel_Size;
   begin
      return Address in Kernel_Physical_Start .. Kernel_Physical_End;
   end Is_Kernel_Address;
end config;
