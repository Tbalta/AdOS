with Interfaces; use Interfaces;
with Limine;
with x86; use x86;

package Arch is
   pragma Preelaborate;


   subtype Syscall_Arg is Unsigned_64;
   subtype Signed_Syscall_Output is Integer_64;
   subtype Unsigned_Syscall_Output is Unsigned_64;
   subtype Register_Type is Unsigned_64;


   function Get_User_Address_Space_Start return Virtual_Address is (Virtual_Address'First);
   function Get_User_Address_Space_End   return Virtual_Address is (Limine.Get_HHDM_Offset);

   function Get_Kernel_Address_Space_Start return Virtual_Address is (Limine.Get_HHDM_Offset);
   function Get_Kernel_Address_Space_End   return Virtual_Address is (Virtual_Address'Last);

private
   
end Arch;