with VGA;

with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.SERIAL;
with Log;

package body File_System.VGA is
   package Logger renames Log.Serial_Logger;

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

   ----------
   -- Open --
   ----------
   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      if File_Path = "vga" and then not Descriptors (VGA_FD).used then
         Logger.Log_Info ("vga_file opened");
         Descriptors (VGA_FD).used   := True;
         Descriptors (VGA_FD).Width  := 320;
         Descriptors (VGA_FD).Height := 200;
         Descriptors (VGA_FD).offset := 0;
         return VGA_FD;
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

      Buffer_Address : System.Address := Conversion.To_Address (Conversion.Object_Pointer (Buffer));

      Frame_Buffer : System.Address := Standard.VGA.Get_Frame_Buffer;

      VGA_FILE : File_Information renames Descriptors (VGA_FD);
      Vga_Size : Storage_Count := Storage_Count (VGA_FILE.Height * VGA_FILE.Width);
      Write_Size : Storage_Offset := Storage_Offset (Min (Integer (Vga_Size) - Integer (VGA_FILE.offset), Integer (count)));

      procedure memcpy (dst, src : System.Address; count : Storage_Count);
      pragma Import (C, memcpy, "memcpy");
   begin
      if fd /= VGA_FD or not VGA_FILE.used then
         return -1;
      end if;

      if Write_Size < 0 then
         return -1;
      end if;

      memcpy (Frame_Buffer + Storage_Offset (VGA_FILE.offset), Buffer_Address, Write_Size);

      VGA_FILE.offset := VGA_FILE.offset + Storage_Offset (Write_Size);

      return Integer (Write_Size);
   end write;

   -------------------
   -- SERIAL Seek --
   -------------------
   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t is
      VGA_FILE : File_Information renames Descriptors (VGA_FD);
      f_offset : Storage_Offset renames Descriptors (VGA_FD).offset;

      f_size : Storage_Count := Storage_Count (VGA_FILE.Height * VGA_FILE.Width);
   begin
      if fd /= VGA_FD or not VGA_FILE.used then
         return -1;
      end if;

      case wh is
         when SEEK_SET =>
            if offset < 0 then
               return -1;
            end if;
            f_offset := Storage_Offset (offset);

         when SEEK_CUR =>
            if (off_t (f_offset) + offset) < 0 then
               return -1;
            end if;
            f_offset := f_offset + Storage_Offset (offset);

         when SEEK_END =>
            if (off_t (f_size) + offset) < 0 then
               return -1;
            end if;
            f_offset := f_size + Storage_Offset (offset);
      end case;
      return off_t (f_offset);
   end seek;

   ------------------
   -- SERIAL Close --
   ------------------
   function close (fd : Driver_File_Descriptor) return Integer is
   begin
      if fd /= VGA_FD or not Descriptors (VGA_FD).used then
         return -1;
      end if;

      Descriptors (VGA_FD).used := False;
      return 0;
   end close;
   
   function mmap (fd : Driver_File_Descriptor; size : Storage_Count) return System.Address
   is
      VGA_FILE : File_Information renames Descriptors (VGA_FD);

      f_size : Storage_Count := Storage_Count (VGA_FILE.Height * VGA_FILE.Width);
   begin
      if fd /= VGA_FD or not Descriptors (VGA_FD).used then
         return System.Null_Address;
      end if;

      if size /= f_size then
         return System.Null_Address;
      end if;

      return Standard.VGA.Get_Frame_Buffer;
   end mmap;

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

end File_System.VGA;
