------------------------------------------------------------------------------
--                                 SYSCALL                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with VGA;
with x86.VMM;
with Interfaces;              use Interfaces;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with Arch; use Arch;
package Syscall is
   pragma Preelaborate;

   SYSCALL_EXIT  : constant Syscall_Arg := 1;
   SYSCALL_READ  : constant Syscall_Arg := 3;
   SYSCALL_WRITE : constant Syscall_Arg := 4;
   SYSCALL_OPEN  : constant Syscall_Arg := 5;
   SYSCALL_CLOSE : constant Syscall_Arg := 6;
   SYSCALL_LSEEK : constant Syscall_Arg := 19;
   SYSCALL_MMAP  : constant Syscall_Arg := 90;

   type Syscall_Result (signed : Boolean) is record
      case signed is
         when True =>
            Signed_Value : Signed_Syscall_Output;

         when False =>
            Unsigned_Value : Unsigned_Syscall_Output;
      end case;
   end record;
   pragma Unchecked_Union (Syscall_Result);

   procedure Handle_Syscall
     (number  : in Syscall_Arg;
      arg1    : in Syscall_Arg;
      arg2    : in Syscall_Arg;
      arg3    : in Syscall_Arg;
      arg4    : in Syscall_Arg;
      arg5    : in Syscall_Arg;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);


private
   procedure Exit_Syscall 
      (Status : in  Syscall_Arg;
      Process : in x86.vmm.CR3_Register);

   procedure Read_Syscall
     (arg1    : in Syscall_Arg;
      buffer  : in System.Address;
      count   : in Storage_Count;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);

   procedure Write_Syscall
     (arg1    : in Syscall_Arg;
      buffer  : in System.Address;
      count   : in Storage_Count;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);

   procedure Open_Syscall
     (File_Path : in System.Address;
      flag      : in Syscall_Arg;
      process   : in x86.vmm.CR3_register;
      result    : out Syscall_Result);
   procedure Close_Syscall
     (arg1 : in Syscall_Arg; process : in x86.vmm.CR3_register; result : out Syscall_Result);

   procedure Seek_Syscall
     (arg1    : Syscall_Arg;
      arg2    : Syscall_Arg;
      arg3    : Syscall_Arg;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);

   procedure Mmap_Syscall
     (addr    : System.Address;
      length  : Storage_Count;
      prot    : Syscall_Arg;
      flags   : Syscall_Arg;
      arg5    : Syscall_Arg;
      --  offset : Syscall_Arg;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result);

end Syscall;
