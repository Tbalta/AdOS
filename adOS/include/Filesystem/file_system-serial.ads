with Interfaces;   use Interfaces;
with Interfaces.C; use Interfaces.C;
with System;
with System.Address_To_Access_Conversions;
with Ados;
with Atapi;

with File_System;


package file_system.SERIAL
  with Preelaborate
is

   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error;

   generic
      type Read_Type is private;
   function read (fd : Driver_File_Descriptor; Buffer : out Read_Type) return Integer;
   generic
      type Write_Type is private;
   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer;
   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t;
   function close (fd : Driver_File_Descriptor) return Integer;
   procedure init;
   procedure list_file (Atapi_Device : Atapi.Atapi_Device_id; dir_lba, dir_size_param : in Natural);


private
   
   type File_Information is record
      used : Boolean := False;
      tty  : Positive;
   end record;

   type SERIAL_File_Info_Array is array (Driver_File_Descriptor) of File_Information;
   Descriptors : SERIAL_File_Info_Array := (others => <>);


end file_system.SERIAL;
