with File_System;
with Log;
with SERIAL;
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
      case number is
         when SYSCALL_WRITE =>
            Write_Syscall (arg1, System.Address (arg2), Storage_Count (arg3), process, result);
         when SYSCALL_READ =>
            Read_Syscall (arg1, System.Address (arg2), arg3, result);
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
      x86.vmm.Enable_Paging;
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
       count    : in Unsigned_32;
       result   : out Unsigned_32)
   is
   begin
      -- Placeholder implementation
      result := count; -- pretend we read all bytes
   end Read_Syscall;
end Syscall;