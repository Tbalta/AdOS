with x86.VMM;
with Interfaces;              use Interfaces;
with System;
with System.Storage_Elements; use System.Storage_Elements;

package Syscall is
   pragma Preelaborate;

   SYSCALL_READ  : constant Unsigned_32 := 3;
   SYSCALL_WRITE : constant Unsigned_32 := 4;
   SYSCALL_OPEN  : constant Unsigned_32 := 5;

   type Syscall_Result (signed : Boolean) is record
      case signed is
         when True =>
            Signed_Value : Integer_32;

         when False =>
            Unsigned_Value : Unsigned_32;
      end case;
   end record;
   pragma Unchecked_Union (Syscall_Result);

   procedure Handle_Syscall
     (number  : in Unsigned_32;
      arg1    : in Unsigned_32;
      arg2    : in Unsigned_32;
      arg3    : in Unsigned_32;
      arg4    : in Unsigned_32;
      arg5    : in Unsigned_32;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);


private
   procedure Write_Syscall
     (arg1    : in Unsigned_32;
      buffer  : in System.Address;
      count   : in Storage_Count;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);

   procedure Read_Syscall
     (arg1    : in Unsigned_32;
      buffer  : in System.Address;
      count   : in Storage_Count;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);

   procedure Open_Syscall
     (File_Path : in System.Address;
      flag      : in Unsigned_32;
      process   : in x86.vmm.CR3_register;
      result    : out Syscall_Result);
end Syscall;
