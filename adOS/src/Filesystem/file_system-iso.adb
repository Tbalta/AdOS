with SERIAL;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.ISO;

package body File_System.ISO is
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

   function Find_Free_FD return Driver_File_Descriptor_With_Error is
   begin
      for i in Descriptors'Range loop
         if not Descriptors (i).used then
            return i;
         end if;
      end loop;
      return DRIVER_FD_ERROR;
   end Find_Free_FD;

   function Atapi_Open
     (Driver_id : Device_Driver.Driver_id; File_Path : Path; flag : Integer)
      return Driver_File_Descriptor_With_Error
   is
      use ISO_FILE_DESC_CONVERTER;
      file_buffer : System.Address := Atapi_Buffer'Address;
      count       : Natural;

      Atapi_Device : Atapi.Atapi_Device_id := Drivers (Driver_id).Atapi_Device;
      root_lba     : Natural := Drivers (Driver_id).root_lba;
      root_dirsize : Unsigned_32 := Drivers (Driver_id).root_dirsize;

      function Next_File (current_file : iso_dir_ptr) return iso_dir_ptr is
      begin
         return To_Pointer (To_Address (current_file) + Storage_Offset (current_file.dir_size));
      end Next_File;

      function Idf_Start (current_file : iso_dir_ptr) return System.Address is
      begin
         return To_Address (current_file) + Storage_Offset (iso_dir'Size / 8);  -- 34 bytes offset
      end Idf_Start;
      -- Local Functions --
      function Locate_File
        (str : String; lba_param : Natural; dir_size_param : Unsigned_32) return iso_dir_ptr
      is
         current_file   : iso_dir_ptr;
         lba            : Natural := lba_param;
         dir_size       : Unsigned_32 := dir_size_param;
         path_sep_index : Positive := IndexOfString (str, '/');
         searched_file  : String := str (str'First .. Min (path_sep_index - 1, str'Last));
      begin
         count := Atapi.read_block (Atapi_Device, lba, Atapi_Buffer);
         file_buffer := Atapi_Buffer'Address;
         current_file := iso_dir_ptr (To_Pointer (file_buffer));

         -- Skip . and .. entries
         for I in 1 .. 2 loop
            current_file := Next_File (current_file);
         end loop;

         while dir_size > 0 loop
            while current_file.dir_size /= 0 and current_file.idf_len >= 0 loop
               declare
                  subtype current_file_name is char_array (0 .. size_t (current_file.idf_len) - 1);
                  package To_Ada_Conversions is new
                    System.Address_To_Access_Conversions (current_file_name);
                  file_name_char_array : access current_file_name :=
                    To_Ada_Conversions.To_Pointer (Idf_Start (current_file));
                  file_name            : String :=
                    To_Upper (To_Ada (file_name_char_array.all, False));
                  stripped_file_name   : String :=
                    file_name
                      (file_name'First .. Min (IndexOfString (file_name, ';') - 1, file_name'Last));
               begin
                  --  SERIAL.send_line ("File: " & stripped_file_name & " Searched: " & searched_file);
                  if searched_file = stripped_file_name then
                     if current_file.flags (Directory) then
                        SERIAL.send_line ("Directory found: " & stripped_file_name);
                        return
                          Locate_File
                            (str (path_sep_index + 1 .. str'Last),
                             Natural (current_file.data_blk.le),
                             current_file.file_size.le);
                     end if;
                     return current_file;
                  end if;
                  current_file := Next_File (current_file);
               end;
            end loop;
            dir_size := dir_size - BLOCK_SIZE;
            lba := lba + 1;
            file_buffer := Atapi_Buffer'Address;
            count := Atapi.Read_Block (Atapi_Device, lba, Atapi_Buffer);

            current_file := iso_dir_ptr (To_Pointer (file_buffer));
         end loop;
         return null;
      end Locate_File;

      file : iso_dir_ptr := Locate_File (To_Upper (String (File_Path)), root_lba, root_dirsize);

      FD : Driver_File_Descriptor_With_Error;
   begin
      if file = null then
         return DRIVER_FD_ERROR;
      end if;

      FD := Find_Free_FD;

      if FD = DRIVER_FD_ERROR then
         return DRIVER_FD_ERROR;
      end if;

      Descriptors (FD).lba := Integer (file.data_blk.le);
      Descriptors (FD).driver := Driver_id;
      Descriptors (FD).used := True;
      Descriptors (FD).size := Integer (file.file_size.le);
      Descriptors (FD).offset := 0;

      SERIAL.send_line ("FD: " & FD'Image);
      return FD;
   end Atapi_Open;

   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      for i in Drivers'Range loop
         if Drivers (i).Present then
            case Drivers (i).Driver_Type is
               when Ados.ATAPI_DRIVER =>
                  FD := Atapi_Open (i, File_Path, Flag);

               when others =>
                  raise Program_Error with "Unexpected Driver_Type";
            end case;
         end if;
         exit when FD /= DRIVER_FD_ERROR;
      end loop;

      return FD;
   end open;

   --------------------
   -- ISO 9660 Read --
   --------------------
   function read (fd : Driver_File_Descriptor; Buffer : out Read_Type) return Integer is
      f_lba    : Natural renames Descriptors (fd).lba;
      f_offset : Integer renames Descriptors (fd).offset;
      f_size   : Natural renames Descriptors (fd).size;
      f_used   : Boolean renames Descriptors (fd).used;

      Atapi_Driver : Device_Driver.Driver_id renames Descriptors (fd).driver;
      Atapi_Device : Atapi.Atapi_Device_id := Drivers (Atapi_Driver).Atapi_Device;

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
         read_buffer := Atapi_Buffer'Address;
         count := Atapi.Read_Block (Atapi_Device, lba, Atapi_Buffer);
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

   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t is
      f_offset : Natural renames Descriptors (fd).offset;
      f_size   : Natural renames Descriptors (fd).size;
      f_used   : Boolean renames Descriptors (fd).used;
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
   function close (fd : Driver_File_Descriptor) return Integer is
      f_used : Boolean renames Descriptors (fd).used;
   begin
      if (not f_used) then
         return -1;
      end if;
      Descriptors (fd).used := False;
      return 0;
   end close;

   -------------------
   -- ISO 9660 Init --
   -------------------
   function Has_Iso_Filesystem
     (Atapi_Device : Atapi.Atapi_Device_id; primary_descriptor : out iso_prim_voldesc)
      return Boolean
   is
      use ISO_PRIM_DESC_CONVERTER;
      init_buffer : System.Address;
      Count       : Natural := 0;
   begin
      SERIAL.send_line ("Checking for ISO filesystem on device " & Atapi_Device'Image);
      Count := Atapi.Read_Block (Atapi_Device, 16, Atapi_Buffer);
      init_buffer := Atapi_Buffer'Address;
      primary_descriptor := iso_prim_voldesc_ptr (To_Pointer (init_buffer)).all;
      SERIAL.send_line ("Identifier (should be CD001)" & To_Ada (primary_descriptor.vol_id, False));
      return To_Ada (primary_descriptor.vol_id, False) = "CD001";
   end Has_Iso_Filesystem;

   procedure Add_Atapi_Driver
     (Device : Atapi.Atapi_Device_id; iso_volume_descriptor : iso_prim_voldesc) is
   begin
      for I in Drivers'Range loop
         if not Drivers (I).Present then
            Drivers (I) :=
              (Driver_Type  => Ados.ATAPI_DRIVER,
               Present      => True,
               root_lba     => Natural (iso_volume_descriptor.root_dir.data_blk.le),
               root_dirsize => iso_volume_descriptor.root_dir.file_size.le,
               Atapi_Device => Device);
            return;
         end if;
      end loop;
   end Add_Atapi_Driver;

   procedure init is
      Volume_Descriptor : iso_prim_voldesc;
   begin
      SERIAL.send_line ("Initializing ISO filesystem");
      for Atapi_Device in Atapi.Atapi_Device_id'range loop
         if Atapi.Is_Present (Atapi_Device)
           and then Has_Iso_Filesystem (Atapi_Device, Volume_Descriptor)
         then
            Add_Atapi_Driver (Atapi_Device, Volume_Descriptor);
         end if;
      end loop;
   end init;

   ------------------------
   -- ISO 9660 List_File --
   ------------------------
   procedure list_file (Atapi_Device : Atapi.Atapi_Device_id; dir_lba, dir_size_param : in Natural)
   is
      file_buffer  : System.Address := Atapi_Buffer'Address;
      use ISO_FILE_DESC_CONVERTER;
      current_file : iso_dir_ptr := iso_dir_ptr (To_Pointer (file_buffer));
      lba          : Natural := dir_lba;
      dir_size     : Natural := dir_size_param;
      count        : Natural;
   begin
      file_buffer := Atapi_Buffer'Address;
      count := Atapi.Read_Block (Atapi_Device, dir_lba, Atapi_Buffer);

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
                 To_Ada_Conversions.To_Pointer
                   (current_file'Address + Storage_Offset (current_file'Size / 8));
            begin
               SERIAL.send_line ("File: " & To_Ada (file_name.all, False));
               if current_file.flags (Directory) then
                  list_file
                    (Atapi_Device,
                     Natural (current_file.data_blk.le),
                     Natural (current_file.file_size.le));
                  file_buffer := Atapi_Buffer'Address;
                  count := Atapi.Read_Block (Atapi_Device, Integer (lba), Atapi_Buffer);
               end if;
               current_file :=
                 To_Pointer (To_Address (current_file) + Storage_Offset (current_file.dir_size));
               --  dir_size     := dir_size - Integer (current_file.dir_size);
            end;
         end loop;
         dir_size := dir_size - BLOCK_SIZE;
         lba := lba + 1;
         file_buffer := Atapi_Buffer'Address;
         count := Atapi.Read_Block (Atapi_Device, lba, Atapi_Buffer);
         current_file := iso_dir_ptr (To_Pointer (file_buffer));

      end loop;

   end list_file;

end File_System.ISO;
