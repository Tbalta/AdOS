with Interfaces;   use Interfaces;
with Interfaces.C; use Interfaces.C;
with System;
with System.Address_To_Access_Conversions;
with Ados;
with Atapi;
with System.Storage_Elements; use System.Storage_Elements;
with VGA;

with File_System;


package file_system.VGA
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
   function mmap (fd : Driver_File_Descriptor; size : Storage_Count) return System.Address;
   procedure init;

private
   VGA_FD : constant Driver_File_Descriptor := Driver_File_Descriptor'First;

   type File_Information is record
      used : Boolean := False;
      Width : Standard.VGA.Pixel_Count := 0;
      Height : Standard.VGA.Scan_Line_Count := 0;
      Graphic_Mode : Boolean := False;
      offset : Storage_Offset := 0;
   end record;

   type VGA_File_Info_Array is array (Driver_File_Descriptor range Driver_File_Descriptor'First .. Driver_File_Descriptor'First) of File_Information;
   Descriptors : VGA_File_Info_Array := (others => <>);


end file_system.VGA;
