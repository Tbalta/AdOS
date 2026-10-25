with Interfaces; use Interfaces;
with x86; use x86;
package Arch is
   pragma Pure;


   subtype Syscall_Arg is Unsigned_32;
   subtype Signed_Syscall_Output is Integer_32;
   subtype Unsigned_Syscall_Output is Unsigned_32;
   subtype Register_Type is Unsigned_32;


   function Get_User_Address_Space_Start return Virtual_Address is (Virtual_Address'First);
   function Get_User_Address_Space_End return Virtual_Address is (Virtual_Address'Last);

   function Get_Kernel_Address_Space_Start return Virtual_Address is (Virtual_Address'First);
   function Get_Kernel_Address_Space_End return Virtual_Address is (Virtual_Address'Last);
private
   
end Arch;