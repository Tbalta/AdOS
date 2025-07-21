with SERIAL;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with VFS;                     use VFS;

package body VFS.ISO is
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
   -- ISO 9660 Open --
   -------------------
   function open (path : String; flag : Integer) return File_Descriptor_With_Error is
      use ISO_FILE_DESC_CONVERTER;
      file_buffer : System.Address := raw_buffer'Address;
      count       : Natural;

      -- Local Functions --
      function Locate_File (str : String; lba_param, dir_size_param : Natural) return iso_dir_ptr is
         current_file   : iso_dir_ptr;
         lba            : Natural := lba_param;
         dir_size       : Natural := dir_size_param;
         path_sep_index : Positive := IndexOfString (str, '/');
         searched_file  : String := str (str'First .. Min (path_sep_index - 1, str'Last));
      begin
         count := Read_Block (lba, raw_buffer);
         file_buffer := raw_buffer'Address;

         current_file := iso_dir_ptr (To_Pointer (file_buffer));
         for I in 1 .. 2 loop
            current_file :=
              To_Pointer (To_Address (current_file) + Storage_Offset (current_file.dir_size));
         end loop;

         while dir_size > 0 loop
            while current_file.dir_size /= 0 and current_file.idf_len >= 0 loop
               declare
                  subtype current_file_name is char_array (0 .. size_t (current_file.idf_len));
                  package To_Ada_Conversions is new
                    System.Address_To_Access_Conversions (current_file_name);
                  file_name_char_array : access current_file_name :=
                    To_Ada_Conversions.To_Pointer (current_file.idf'Address);
                  file_name            : String :=
                    To_Upper (To_Ada (file_name_char_array.all, False));
                  stripped_file_name   : String :=
                    file_name
                      (file_name'First .. Min (IndexOfString (file_name, ';') - 1, file_name'Last));
               begin
                  SERIAL.send_line ("File: " & stripped_file_name & " Searched: " & searched_file);
                  if searched_file = stripped_file_name then
                     SERIAL.send_line ("Directory found: " & stripped_file_name);
                     if current_file.flags (Directory) then
                        return
                          Locate_File
                            (str (path_sep_index + 1 .. str'Last),
                             Integer (current_file.data_blk.le),
                             Integer (current_file.file_size.le));
                     end if;
                     return current_file;
                  end if;
                  current_file :=
                    To_Pointer (To_Address (current_file) + Storage_Offset (current_file.dir_size));
               end;
            end loop;
            dir_size := dir_size - BLOCK_SIZE;
            lba := lba + 1;
            file_buffer := raw_buffer'Address;
            count := Read_Block (lba, raw_buffer);

            current_file := iso_dir_ptr (To_Pointer (file_buffer));
         end loop;
         return null;
      end Locate_File;

      file : iso_dir_ptr := Locate_File (To_Upper (path), root_lba, root_dirsize);

      FD : File_Descriptor_With_Error;
   begin
      if file = null then
         return FD_ERROR;
      end if;

      FD := VFS.Add_File (name => path, size => Integer (file.file_size.le), offset => 0);

      if FD = FD_ERROR then
         return FD_ERROR;
      end if;

      ISO_Descriptors (FD).lba := Integer (file.data_blk.le);

      SERIAL.send_line ("FD: " & FD'Image);
      return FD;
   end open;

   --------------------
   -- ISO 9660 Read --
   --------------------
   function read (fd : File_Descriptor; Buffer : out Read_Type) return Integer is
      f_lba    : Natural renames ISO_Descriptors (fd).lba;
      f_offset : Integer renames Descriptors (fd).offset;
      f_size   : Natural renames Descriptors (fd).size;
      f_used   : Boolean renames Descriptors (fd).Valid;

      Temporary_Object : Read_Type;
      out_buffer       : System.Address := Temporary_Object'Address;
      read_buffer      : System.Address;
      base_lba         : Natural := (f_offset / BLOCK_SIZE) + f_lba;
      cnt              : Natural := Read_Type'Size / Storage_Unit;
      read_size        : Natural := Min (cnt, f_size - f_offset);
      sectors_count    : Natural := ((read_size + BLOCK_SIZE - 1) / BLOCK_SIZE);
      count            : Natural;
      procedure memcpy (dest : System.Address; src : System.Address; size : Natural);
      pragma Import (C, memcpy, "memcpy");
   begin
      if (not f_used) then
         return -1;
      end if;
      -- Adjust the offset of the lba
      for lba in base_lba .. (base_lba + sectors_count - 1) loop
         read_buffer := raw_buffer'Address;
         count := Read_Block (lba, raw_buffer);
         memcpy (out_buffer, read_buffer + Storage_Offset (f_offset), Min (cnt, BLOCK_SIZE));
         out_buffer := out_buffer + Storage_Offset (Min (cnt, BLOCK_SIZE));
         cnt := cnt - Min (cnt, BLOCK_SIZE);
      end loop;

      Buffer := Temporary_Object;

      -- Update the offset
      f_offset := f_offset + read_size;

      return read_size;
   end read;

   -------------------
   -- ISO 9660 Seek --
   -------------------
   procedure seek (fd : File_Descriptor; offset : off_t; wh : whence) is
   begin
      Descriptors (fd).offset := Natural (seek (fd, offset, wh));
   end seek;

   function seek (fd : File_Descriptor; offset : off_t; wh : whence) return off_t is
      f_offset : Natural renames Descriptors (fd).offset;
      f_size   : Natural renames Descriptors (fd).size;
      f_used   : Boolean renames Descriptors (fd).Valid;
   begin
      if (not f_used) then
         return -1;
      end if;
      case wh is
         when SEEK_SET =>
            if offset < 0 then
               return -1;
            end if;
            f_offset := Natural (offset);

         when SEEK_CUR =>
            if (off_t (f_offset) + offset) < 0 then
               return -1;
            end if;
            f_offset := f_offset + Natural (offset);

         when SEEK_END =>
            if (off_t (f_size) + offset) < 0 then
               return -1;
            end if;
            f_offset := f_size + Natural (offset);
      end case;
      return off_t (f_offset);
   end seek;

   --------------------
   -- ISO 9660 Close --
   --------------------
   function close (fd : File_Descriptor) return Integer is
      f_used : Boolean renames Descriptors (fd).Valid;
   begin
      if (not f_used) then
         return -1;
      end if;
      Descriptors (fd).Valid := False;
      return 0;
   end close;

   -------------------
   -- ISO 9660 Init --
   -------------------
   procedure init is
      use ISO_PRIM_DESC_CONVERTER;
      init_buffer        : System.Address;
      primary_descriptor : iso_prim_voldesc_ptr;
      Count              : Natural := 0;
   begin
      Count := Read_Block (16, raw_buffer);
      init_buffer := raw_buffer'Address;
      primary_descriptor := iso_prim_voldesc_ptr (To_Pointer (init_buffer));
      SERIAL.send_line ("Identifier (should be CD001)" & To_Ada (primary_descriptor.vol_id, False));
      root_lba := Natural (primary_descriptor.root_dir.data_blk.le);
      root_dirsize := Natural (primary_descriptor.root_dir.file_size.le);
   end init;

   ------------------------
   -- ISO 9660 List_File --
   ------------------------
   procedure list_file (dir_lba, dir_size_param : in Natural) is
      file_buffer  : System.Address := raw_buffer'Address;
      use ISO_FILE_DESC_CONVERTER;
      current_file : iso_dir_ptr := iso_dir_ptr (To_Pointer (file_buffer));
      lba          : Natural := dir_lba;
      dir_size     : Natural := dir_size_param;
      count        : Natural;
   begin
      file_buffer := raw_buffer'Address;
      count := Read_Block (dir_lba, raw_buffer);

      for I in 1 .. 2 loop
         current_file :=
           To_Pointer (To_Address (current_file) + Storage_Offset (current_file.dir_size));
      end loop;
      SERIAL.send_line ("Directory size: " & Integer'Image (dir_size));
      while dir_size > 0 loop
         while current_file.dir_size /= 0 and current_file.idf_len >= 0 loop
            declare
               subtype current_file_name is char_array (0 .. size_t (current_file.idf_len));
               package To_Ada_Conversions is new
                 System.Address_To_Access_Conversions (current_file_name);
               file_name : access current_file_name :=
                 To_Ada_Conversions.To_Pointer (current_file.idf'Address);
            begin
               SERIAL.send_line ("File: " & To_Ada (file_name.all, False));
               if current_file.flags (Directory) then
                  list_file
                    (Natural (current_file.data_blk.le), Natural (current_file.file_size.le));
                  file_buffer := raw_buffer'Address;
                  count := Read_Block (Integer (lba), raw_buffer);
               end if;
               current_file :=
                 To_Pointer (To_Address (current_file) + Storage_Offset (current_file.dir_size));
               --  dir_size     := dir_size - Integer (current_file.dir_size);
            end;
         end loop;
         dir_size := dir_size - BLOCK_SIZE;
         lba := lba + 1;
         file_buffer := raw_buffer'Address;
         count := Read_Block (lba, raw_buffer);
         current_file := iso_dir_ptr (To_Pointer (file_buffer));

      end loop;

   end list_file;

end VFS.ISO;
