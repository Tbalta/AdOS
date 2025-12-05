with System;
with System.Storage_Elements; use System.Storage_Elements;
package File_System
  with Preelaborate
is

   type File_System_Type is (SERIAL_FS, ISO_FS, VGA_FS, INVALID_FS);

   type File_Descriptor_With_Error is new Integer range -1 .. 255;
   subtype File_Descriptor is File_Descriptor_With_Error range 0 .. 255;

   type Driver_File_Descriptor_With_Error is new File_Descriptor_With_Error;
   subtype Driver_File_Descriptor is Driver_File_Descriptor_With_Error range 0 .. 255;

   FD_ERROR        : constant File_Descriptor_With_Error := -1;
   DRIVER_FD_ERROR : constant Driver_File_Descriptor_With_Error := -1;

   type whence is (SEEK_SET, SEEK_CUR, SEEK_END);
   for whence use (
      SEEK_SET => 0,
      SEEK_CUR => 1,
      SEEK_END => 2
   );
   subtype off_t is Integer;

   type Path is new String;

   generic
      type Read_Type is private;
   function read (fd : File_Descriptor; Buffer : access Read_Type) return Integer;
   generic
      type Write_Type is private;
   function write (fd : File_Descriptor; Buffer : access Write_Type) return Integer;
   function open (file_path : Path; flag : Integer) return File_Descriptor_With_Error;
   function seek (fd : File_Descriptor; offset : off_t; wh : whence) return off_t;
   procedure seek (fd : File_Descriptor; offset : off_t; wh : whence);
   function mmap (fd : File_Descriptor; size : Storage_Count) return System.Address;

   function close (fd : File_Descriptor) return Integer;
   procedure close (fd : File_Descriptor);

   function Is_File_Descriptor (fd : Integer) return Boolean;
   function Is_Valid_Whence    (wh : Integer) return Boolean;


private
   type VFS_File is record
      Valid                 : Boolean := False;
      File_System           : File_System_Type := INVALID_FS;
      File_System_Decriptor : Driver_File_Descriptor_With_Error := Driver_FD_ERROR;
   end record;

   type File_Descriptor_Array is array (File_Descriptor) of VFS_File;
   Descriptors : File_Descriptor_Array := (others => <>);

end File_System;
