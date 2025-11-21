with SERIAL;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.SERIAL;
 
package body File_System.SERIAL is
   function To_Upper (str : String) return String is
      result : String := str;
   begin
      for I in result'Range loop
         if result (I) in 'a' .. 'z' then
            result (I) := Character'Val (Character'Pos (result (I)) - 32);
         end if;
      end loop;
      return result;
   end To_Upper;

   function IndexOfString (str : String; c : Character) return Positive is
      i : Positive := str'First;
   begin
      while i in str'Range and then str (i) /= c and then str (i) /= Character'Val (0) loop
         i := i + 1;
      end loop;
      return i;
   end IndexOfString;

   function Min (a, b : Integer) return Integer
   is (if (a < b) then a else b);

   -------------------
   -- SERIAL Open --
   -------------------
   function Find_Free_FD return Driver_File_Descriptor_With_Error is
   begin
      for i in Descriptors'Range loop
         if not Descriptors (i).used then
            return i;
         end if;
      end loop;
      return DRIVER_FD_ERROR;
   end Find_Free_FD;


   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      if File_Path = "tty0" then
         return Find_Free_FD;
      end if;

      return DRIVER_FD_ERROR;
   end open;

   -----------------
   -- SERIAL Read --
   -----------------
   function read (fd : Driver_File_Descriptor; Buffer : out Read_Type) return Integer is
   begin
      return -1;
   end read;

   -----------------
   -- SERIAL Write --
   -----------------
   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer is
      count : constant Storage_Count := Write_Type'Size / Storage_Unit;
      package Conversion is new System.Address_To_Access_Conversions (Write_Type);
   begin
      Standard.SERIAL.send_raw_buffer (Conversion.To_Address (Conversion.Object_Pointer (Buffer)), count);
      return Integer (count);
   end write;

   -------------------
   -- SERIAL Seek --
   -------------------
   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t is
      pragma Unreferenced (fd, offset, wh);
   begin
      return -1;
   end seek;

   ------------------
   -- SERIAL Close --
   ------------------
   function close (fd : Driver_File_Descriptor) return Integer is
      pragma Unreferenced (fd);
   begin
      return 0;
   end close;

   -------------------
   -- SERIAL Init --
   -------------------
   procedure init is
   begin
      null;
   end init;

   ----------------------
   -- SERIAL List_File --
   ----------------------
   procedure list_file (Atapi_Device : Atapi.Atapi_Device_id; dir_lba, dir_size_param : in Natural)
      is
   begin
      null;
   end list_file;

end File_System.SERIAL;
