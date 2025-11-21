with File_System;
with Log;
with SERIAL;
with System.Address_To_Access_Conversions;
with Interfaces.C;
with System.Secondary_Stack;
package body Syscall is
   package Logger renames Log.Serial_Logger;
   procedure Handle_Syscall
     (number   : in Unsigned_32;
      arg1     : in Unsigned_32;
      arg2     : in Unsigned_32;
      arg3     : in Unsigned_32;
      arg4     : in Unsigned_32;
      arg5     : in Unsigned_32;
      process  : in x86.vmm.CR3_register;
      result   : out Unsigned_32)
   is
   begin
      Logger.Log_Info ("Handling syscall number: " & number'Image);
      x86.vmm.Load_Kernel_Mapping;
      Logger.Log_Info ("Kernel mapping loaded for syscall handling");
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
            result := Unsigned_32'(-1); -- unknown syscall
      end case;
   end Handle_Syscall;


   procedure Write_Syscall
     (fd       : in Unsigned_32;
      buffer   : in System.Address;
      count    : in Storage_Count;
      process  : in x86.vmm.CR3_register;
      result   : out Unsigned_32)
   is
      Kernel_CR3    : constant x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Kernel_Buffer : constant System.Address := x86.vmm.Process_To_Process_Map
        (process, buffer, Kernel_CR3, count);
   begin
      SERIAL.send_line
        ("Write_Syscall: fd=" & fd'Image & " buffer=" & buffer'Image & " count=" & count'Image);
      --  SERIAL.send_line
      --    ("Mapped user buffer "& buffer'Image &" to kernel address: " & Kernel_Buffer'Image);
      SERIAL.send_raw_buffer (Kernel_Buffer, count);
      result := Unsigned_32 (count);
      x86.vmm.Unmap(Kernel_CR3, Kernel_Buffer, count);
   end Write_Syscall;
   

   procedure Read_Syscall
      (fd       : in Unsigned_32;
       buffer   : in System.Address;
       count    : in Storage_Count;
       process  : in x86.vmm.CR3_register;
       result   : out Unsigned_32)
   is
      Kernel_CR3    : constant x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Kernel_Buffer : constant System.Address := x86.vmm.Process_To_Process_Map
        (process, buffer, Kernel_CR3, count);
      
      type byte_array is array (0 .. Integer (count) - 1) of Interfaces.C.char;
      package Conversion is new System.Address_To_Access_Conversions (byte_array);
      kernel_buffer_access : access byte_array := Conversion.To_Pointer (Kernel_Buffer);

      function Read is new File_System.read (byte_array);
   begin
      -- Placeholder implementation
      SERIAL.send_line
        ("Write_Syscall: fd=" & fd'Image & " buffer=" & buffer'Image & " count=" & count'Image);
      result := Unsigned_32 (Read (File_System.File_Descriptor (fd), kernel_buffer_access.all));
      x86.vmm.Unmap(Kernel_CR3, Kernel_Buffer, count);
   end Read_Syscall;

   procedure Open_Syscall
      (File_Path : in System.Address;
       flag     : in Unsigned_32;
       process  : in x86.vmm.CR3_register;
       result   : out Unsigned_32)
   is
      Max_Length    : constant := 256;
      Kernel_CR3 : constant x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Kernel_Path   : constant System.Address := x86.vmm.Process_To_Process_Map (process, File_Path, Kernel_CR3, Max_Length);

      use File_System;
      function Retrieve_Path (addr : System.Address) return String is
         function strlen (s : System.Address) return Integer;
         pragma Import (C, strlen, "strlen");

         length : Integer := strlen (addr);

         subtype path_array is String (1 .. length);
         package Conversion is new System.Address_To_Access_Conversions (path_array);
         path_access : access path_array := Conversion.To_Pointer (addr);
      begin
         Logger.Log_Info ("Addr: " & addr'Image);
         Logger.Log_Info ("Retrieve_Path: path=" & String (path_access (1 .. length)));
         Logger.Log_Info ("Retrieve_Path: length=" & length'Image);
         return path_access.all;
      end Retrieve_Path;

      Path_String : String := Retrieve_Path (Kernel_Path);
      FD          : File_Descriptor_With_Error := open (File_System.Path (Path_String), Integer (flag));
   begin
      Logger.Log_Info ("Open_Syscall: Opening file: " & Path_String);
      Logger.Log_Info ("Mapped user file path " & File_Path'Image & " to kernel address: " & Kernel_Path'Image);
      if FD = File_System.FD_ERROR then
         result := Unsigned_32'(-1);
      else
         result := Unsigned_32 (FD);
      end if;
   end Open_Syscall;

end Syscall;