with File_System;
with Log;
with SERIAL;
with System.Address_To_Access_Conversions;
with Interfaces.C;
with Util;
with System.Storage_Elements; use System.Storage_Elements;
with VGA.Sequencer;

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
      --  Logger.Log_Info ("Handling syscall number: " & number'Image);
      x86.vmm.Load_Kernel_Mapping;
      x86.vmm.Enable_Paging;
      case number is
         when SYSCALL_READ =>
            Read_Syscall (arg1, System.Address (arg2), Storage_Count (arg3), process, result);

         when SYSCALL_WRITE =>
            Write_Syscall (arg1, System.Address (arg2), Storage_Count (arg3), process, result);

         when SYSCALL_OPEN =>
            Open_Syscall (System.Address (arg1), arg2, process, result);

         when SYSCALL_CLOSE =>
            Close_Syscall (arg1, process, result);

         when SYSCALL_LSEEK =>
            Seek_Syscall (arg1, arg2, arg3, process, result);
         
         when SYSCALL_MMAP =>
            Mmap_Syscall (System.Address (arg1), Storage_Count (arg2), arg3, arg4, arg5, process, result);

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

      type byte_array is array (0 .. Integer (count) - 1) of aliased Unsigned_8
         with Pack => True;
      package Conversion is new System.Address_To_Access_Conversions (byte_array);

      function Write is new File_System.write (byte_array);
      kernel_buffer_access : access byte_array := null;

      fd : File_System.File_Descriptor;
   begin
      --  Logger.Log_Info
      --    ("Write_Syscall: fd=" & arg1'Image & " buffer=" & buffer'Image & " count=" & count'Image);

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
      --  Logger.Log_Info ("Write_Syscall'Result=" & result.Signed_Value'Image);
      x86.vmm.Unmap (Kernel_CR3, Kernel_Buffer, count, False);
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

      type byte_array is array (0 .. Integer (count) - 1) of aliased Unsigned_8
         with Pack => True;
      package Conversion is new System.Address_To_Access_Conversions (byte_array);

      function Read is new File_System.read (byte_array);
      kernel_buffer_access : access byte_array := null;

      fd : File_System.File_Descriptor;
   begin
      pragma Assert (byte_array'Size = count * 8);
      --  Logger.Log_Info
      --    ("Read_Syscall: arg1=" & arg1'Image & " buffer=" & buffer'Image & " count=" & count'Image);
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
      result.Signed_Value := Integer_32 (Read (fd, kernel_buffer_access));
      --  Logger.Log_Info ("Read_Syscall'Result=" & result.Signed_Value'Image);
      x86.vmm.Unmap (Kernel_CR3, Kernel_Buffer, count, False);
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
      Max_Length : constant := 256;
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

      x86.vmm.Unmap (Kernel_CR3, Kernel_Path, Max_Length, False);
   end Open_Syscall;

   -------------------
   -- Close_Syscall --
   -------------------
   procedure Close_Syscall
     (arg1      : in Unsigned_32;
      process   : in x86.vmm.CR3_register;
      result    : out Syscall_Result)
   is
      fd     : File_System.File_Descriptor;
   begin
      if not File_System.Is_File_Descriptor (Integer (arg1)) then
         Logger.Log_Error ("Close_Syscall - Invalid file descriptor: " & arg1'Image);
         result.Signed_Value := -1;
         return;
      end if;
      fd := File_System.File_Descriptor (arg1);

      result.Signed_Value := Integer_32 (File_System.close (fd));
   end Close_Syscall;

   ------------------
   -- Seek_Syscall --
   ------------------
   procedure Seek_Syscall (
      arg1 : Unsigned_32;
      arg2 : Unsigned_32;
      arg3 : Unsigned_32;
      process   : in x86.vmm.CR3_register;
      result    : out Syscall_Result)
   is
      fd     : File_System.File_Descriptor;
      offset : File_System.off_t := File_System.off_t (arg2);
      whence : File_System.whence;
   begin

      if not File_System.Is_File_Descriptor (Integer (arg1)) then
         Logger.Log_Error ("Seek_Syscall - Invalid file descriptor: " & arg1'Image);
         result.Signed_Value := -1;
         return;
      end if;
      fd := File_System.File_Descriptor (arg1);


      if not File_System.Is_Valid_Whence (Integer (arg3)) then
         Logger.Log_Error (arg3'Image & "not in SEEK_SET .. SEEK_END");
         result.Signed_Value := -1;
      end if;
      whence := File_System.whence'Enum_Val (arg3);

      result.Signed_Value := Integer_32 (File_System.seek (fd, offset, whence));
   end Seek_Syscall;

   ------------------
   -- Mmap_Syscall --
   ------------------
   procedure Mmap_Syscall
   (
      addr   : System.Address;
      length : Storage_Count;
      prot   : Unsigned_32;
      flags  : Unsigned_32;
      arg5   : Unsigned_32;
      --  offset : Unsigned_32;
      process   : in x86.vmm.CR3_register;
      result    : out Syscall_Result)
   is
      use all type System.Address;

      fd : File_System.File_Descriptor;
      File_Buffer : System.Address := System.Null_Address;
      Kernel_CR3  : constant x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
   begin
      if not File_System.Is_File_Descriptor (Integer (arg5)) then
         Logger.Log_Error ("Mmap_Syscall - Invalid file descriptor: " & arg5'Image);
         result.Signed_Value := -1;
         return;
      end if;
      fd := File_System.File_Descriptor (arg5);

      File_Buffer := File_System.mmap (fd, length);
      if File_Buffer = System.Null_Address then
         Logger.Log_Error ("Mmap_Syscall - Unable to retrieve File_Buffer for fd " & fd'Image);
         result.Signed_Value := -1;
         return;
      end if;

      result.Unsigned_Value := Unsigned_32 (x86.vmm.Process_To_Process_Map
        (Source_CR3     => Kernel_CR3,
         Source_Address => File_Buffer,
         Dest_CR3       => process,
         Size           => length));
      Logger.Log_Info ("Buffer mapped at " & result.Unsigned_Value'Image);

   end Mmap_Syscall;

end Syscall;
