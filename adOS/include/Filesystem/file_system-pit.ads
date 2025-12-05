with Interfaces;   use Interfaces;
with Interfaces.C; use Interfaces.C;
with System;
with System.Address_To_Access_Conversions;
with Ados;
with Atapi;
with System.Storage_Elements; use System.Storage_Elements;
with Programmable_Interval_Timer;

with File_System;


package file_system.PIT
  with Preelaborate
is

   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error;

   generic
      type Read_Type is private;
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer;
   function close (fd : Driver_File_Descriptor) return Integer;
private
   SYSTICK_FD  : constant Driver_File_Descriptor := Driver_File_Descriptor'First;

end file_system.PIT;
