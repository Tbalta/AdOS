with File_System;
with Log;
with SERIAL;
with System.Address_To_Access_Conversions;
with Interfaces.C;
with Util;

package body Syscall is
   package Logger renames Log.Serial_Logger;

   --------------------
   -- Handle Syscall --
   --------------------
   procedure Handle_Syscall
     (number  : in Unsigned_32;
      arg1    : in Unsigned_32;
      arg2    : in Unsigned_32;
      arg3    : in Unsigned_32;
      arg4    : in Unsigned_32;
      arg5    : in Unsigned_32;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result) is
   begin
      Logger.Log_Info ("Handling syscall number: " & number'Image);
      x86.vmm.Load_Kernel_Mapping;
      x86.vmm.Enable_Paging;
      case number is
         when SYSCALL_WRITE =>
            Write_Syscall (arg1, System.Address (arg2), Storage_Count (arg3), process, result);

         when SYSCALL_READ =>
            Read_Syscall (arg1, System.Address (arg2), Storage_Count (arg3), process, result);

         when SYSCALL_OPEN =>
            Open_Syscall (System.Address (arg1), arg2, process, result);

         when others =>
            Logger.Log_Error ("Unknown syscall number: " & number'Image);
            result.Signed_Value := -1;
      end case;
   end Handle_Syscall;


   -------------------
   -- Write Syscall --
   -------------------
   procedure Write_Syscall
     (arg1    : in Unsigned_32;
      buffer  : in System.Address;
      count   : in Storage_Count;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result)
   is
      use all type File_System.File_Descriptor;
      use all type System.Address;

      Kernel_CR3    : constant x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Kernel_Buffer : System.Address := System.Null_Address;

      type byte_array is array (0 .. Integer (count) - 1) of Interfaces.C.char;
      package Conversion is new System.Address_To_Access_Conversions (byte_array);

      function Write is new File_System.write (byte_array);
      kernel_buffer_access : access byte_array := null;

      fd : File_System.File_Descriptor;
   begin
      Logger.Log_Info
        ("Write_Syscall: fd=" & arg1'Image & " buffer=" & buffer'Image & " count=" & count'Image);

      -- Check --
      if not File_System.Is_File_Descriptor (Integer (arg1)) then
         Logger.Log_Error ("Write_Syscall: Invalid file descriptor: " & fd'Image);
         result.Signed_Value := -1;
         return;
      end if;
      fd := File_System.File_Descriptor (arg1);

      Kernel_Buffer := x86.vmm.Process_To_Process_Map (process, buffer, Kernel_CR3, count);
      if Kernel_Buffer = System.Null_Address then
         Logger.Log_Error ("Write_Syscall: Failed to map user buffer to kernel address");
         result.Signed_Value := -1;
         return;
      end if;
      kernel_buffer_access := Conversion.To_Pointer (Kernel_Buffer);

      -- write --
      result.Signed_Value := Integer_32 (Write (fd, kernel_buffer_access));
      Logger.Log_Info ("Write_Syscall'Result=" & result.Signed_Value'Image);
      x86.vmm.Unmap (Kernel_CR3, Kernel_Buffer, count);
   end Write_Syscall;


   ------------------
   -- Read Syscall --
   ------------------
   procedure Read_Syscall
     (arg1    : in Unsigned_32;
      buffer  : in System.Address;
      count   : in Storage_Count;
      process : in x86.vmm.CR3_register;
      result  : out Syscall_Result)
   is
      use all type File_System.File_Descriptor;
      use all type System.Address;

      Kernel_CR3    : constant x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Kernel_Buffer : System.Address := System.Null_Address;

      type byte_array is array (0 .. Integer (count) - 1) of Interfaces.C.char;
      package Conversion is new System.Address_To_Access_Conversions (byte_array);

      function Read is new File_System.read (byte_array);
      kernel_buffer_access : access byte_array := null;

      fd : File_System.File_Descriptor;
   begin
      Logger.Log_Info
        ("Read_Syscall: arg1=" & arg1'Image & " buffer=" & buffer'Image & " count=" & count'Image);
      -- Check --
      if not File_System.Is_File_Descriptor (Integer (arg1)) then
         Logger.Log_Error ("Read_Syscall: Invalid file descriptor: " & fd'Image);
         result.Signed_Value := -1;
         return;
      end if;
      fd := File_System.File_Descriptor (arg1);

      Kernel_Buffer := x86.vmm.Process_To_Process_Map (process, buffer, Kernel_CR3, count);
      if Kernel_Buffer = System.Null_Address then
         Logger.Log_Error ("Read_Syscall: Failed to map user buffer to kernel address");
         result.Signed_Value := -1;
         return;
      end if;
      kernel_buffer_access := Conversion.To_Pointer (Kernel_Buffer);

      -- read --
      result.Signed_Value := Integer_32 (Read (fd, kernel_buffer_access.all));
      Logger.Log_Info ("Read_Syscall'Result=" & result.Signed_Value'Image);
      x86.vmm.Unmap (Kernel_CR3, Kernel_Buffer, count);
   end Read_Syscall;


   ------------------
   -- Open Syscall --
   ------------------
   procedure Open_Syscall
     (File_Path : in System.Address;
      flag      : in Unsigned_32;
      process   : in x86.vmm.CR3_register;
      result    : out Syscall_Result)
   is
      use File_System;
      use all type System.Address;
      Max_Length  : constant := 256;
      Kernel_CR3  : constant x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Kernel_Path : constant System.Address :=
        x86.vmm.Process_To_Process_Map (process, File_Path, Kernel_CR3, Max_Length);

   begin
      if Kernel_Path = System.Null_Address then
         Logger.Log_Error ("Open_Syscall: Failed to map user file path to kernel address");
         result.Signed_Value := -1;
         return;
      end if;

      declare
         Path_String : constant String := Util.Read_String_From_Address (Kernel_Path);
      begin
         result.Signed_Value := Integer_32 (open (File_System.Path (Path_String), Integer (flag)));
         Logger.Log_Info
           ("Open_Syscall: Opening file: " & Path_String & " FD: " & result.Signed_Value'Image);
      end;

      x86.vmm.Unmap (Kernel_CR3, Kernel_Path, Max_Length);
   end Open_Syscall;
end Syscall;
