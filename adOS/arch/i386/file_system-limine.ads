with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System;
with System.Address_To_Access_Conversions;
with Ados;
with Atapi;
with System.Storage_Elements; use System.Storage_Elements;
with VGA;

with File_System;

package file_system.Limine
  with Preelaborate
is

   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is (DRIVER_FD_ERROR);

   generic
      type Read_Type is private;
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer;
   generic
      type Write_Type is private;
   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer;
   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t is (-1);
   function close (fd : Driver_File_Descriptor) return Integer is (-1);
   function mmap (fd : Driver_File_Descriptor; size : Storage_Count) return System.Address is (System.Null_Address);
   procedure init;
end file_system.Limine;
