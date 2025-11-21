with x86.VMM;
with Interfaces; use Interfaces;
with System;
with System.Storage_Elements; use System.Storage_Elements;

package Syscall is
   pragma Preelaborate;


   SYSCALL_READ  : constant Unsigned_32 := 3;
   SYSCALL_WRITE : constant Unsigned_32 := 4;
   SYSCALL_OPEN  : constant Unsigned_32 := 5;

   procedure Handle_Syscall
     (number   : in Unsigned_32;
      arg1     : in Unsigned_32;
      arg2     : in Unsigned_32;
      arg3     : in Unsigned_32;
      arg4     : in Unsigned_32;
      arg5     : in Unsigned_32;
      process  : in x86.vmm.CR3_register;
      result   : out Unsigned_32);


   procedure Write_Syscall
     (fd       : in Unsigned_32;
      buffer   : in System.Address;
      count    : in Storage_Count;
      process  : in x86.vmm.CR3_register;
      result   : out Unsigned_32);

   procedure Read_Syscall
      (fd       : in Unsigned_32;
       buffer   : in System.Address;
       count    : in Storage_Count;
       process  : in x86.vmm.CR3_register;
       result   : out Unsigned_32);

   procedure Open_Syscall
      (File_Path : in System.Address;
       flag      : in Unsigned_32;
       process   : in x86.vmm.CR3_register;
       result    : out Unsigned_32);
end Syscall;