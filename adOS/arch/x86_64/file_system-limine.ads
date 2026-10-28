with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System;
with System.Address_To_Access_Conversions;
with Ados;
with Atapi;
with System.Storage_Elements; use System.Storage_Elements;
with VGA;

with File_System;

with Limine; use Limine;
package file_system.Limine
  with Preelaborate
is

   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error;

   generic
      type Read_Type is private;
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer;
   generic
      type Write_Type is private;
   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer;
   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t;
   function close (fd : Driver_File_Descriptor) return Integer;
   function mmap (fd : Driver_File_Descriptor; size : Storage_Count) return System.Address;
   procedure init;

private
   FRAME_BUFFER_FD : constant Driver_File_Descriptor := Driver_File_Descriptor'First;
   INFO_FD        : constant Driver_File_Descriptor := FRAME_BUFFER_FD + 1;

   --  generic
   --     type Read_Type is private;
   --  function read (fd : Driver_File_Descriptor; Buffer : out Read_Type) return Integer;
   generic
      type Write_Type is private;
   function Frame_Buffer_Write
     (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer;

   type Frame_Buffer_Information is record
      width : aliased Unsigned_64;
      height : aliased Unsigned_64;
      pitch : aliased Unsigned_64;
      bpp : aliased Unsigned_16;
      red_mask_size : aliased Unsigned_8;
      red_mask_shift : aliased Unsigned_8;
      green_mask_size : aliased Unsigned_8;
      green_mask_shift : aliased Unsigned_8;
      blue_mask_size : aliased Unsigned_8;
      blue_mask_shift : aliased Unsigned_8;
   end record
      with Pack => True,
           Convention => C_Pass_By_Copy;

   type File_Information is record
      used         : Boolean := False;
      framebuffer  : standard.Limine.Framebuffer_Access := null;
      offset       : Storage_Offset := 0;
   end record;

   Palette_Index : Natural := 0;
   type VGA_File_Info_Array is
     array (Driver_File_Descriptor
              range Driver_File_Descriptor'First .. Driver_File_Descriptor'First)
     of File_Information;
   Descriptors : VGA_File_Info_Array := (others => <>);


end file_system.Limine;
