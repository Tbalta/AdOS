with VGA;

with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.SERIAL;
with Loggers;
with Ada.Unchecked_Conversion;


package body File_System.Limine is

   ----------
   -- Read --
   ----------
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer is
   begin
         return -1;
   end read;

   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer is
   begin
      return -1;
   end write;

   -------------------
   -- SERIAL Init --
   -------------------
   procedure init is
   begin
      null;
   end init;

end File_System.Limine;
