with SERIAL;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.ISO;
with System.Address_To_Access_Conversions;
with Loggers;
with Ramdisk;

package body File_System.ISO is
   package Logger renames Loggers.Serial_Logger;

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

   function Open
     (Driver_Id : Device_Driver.Driver_id; File_Path : Path; flag : Integer)
      return Driver_File_Descriptor_With_Error
   is
      use ISO_FILE_DESC_CONVERTER;
      file_buffer : System.Address := Atapi_Buffer'Address;
      count       : Natural;

      root_lba     : Natural := Drivers (Driver_Id).root_lba;
      root_dirsize : Unsigned_32 := Drivers (Driver_Id).root_dirsize;

      -- Local Functions --
      function Next_File (current_file : iso_dir_ptr) return iso_dir_ptr is
      begin
         return To_Pointer (To_Address (current_file) + Storage_Offset (current_file.dir_size));
      end Next_File;

      function Idf_Start (current_file : iso_dir_ptr) return System.Address is
      begin
         return To_Address (current_file) + Storage_Offset (iso_dir'Size / 8);  -- 34 bytes offset
      end Idf_Start;
      function Locate_File
        (str : String; lba_param : Natural; dir_size_param : Unsigned_32) return iso_dir_ptr
      is
         current_file   : iso_dir_ptr;
         lba            : Natural := lba_param;
         dir_size       : Unsigned_32 := dir_size_param;
         path_sep_index : Positive := IndexOfString (str, '/');
         searched_file  : String := str (str'First .. Min (path_sep_index - 1, str'Last));
      begin
         count := Read_Iso_Block (Drivers (Driver_Id), lba, Atapi_Buffer);
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
                  --  Logger.Log_Info ("Searching for: " & searched_file & " Current: " & stripped_file_name);
                  --  SERIAL.send_line ("File: " & stripped_file_name & " Searched: " & searched_file);
                  if searched_file = stripped_file_name then
                     if current_file.flags (Directory) then
                        Logger.Log_Info ("Directory found: " & stripped_file_name);
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
            count := Read_Iso_Block (Drivers (Driver_Id), lba, Atapi_Buffer);

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
      return FD;
   end Open;

   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      for i in Drivers'Range loop
         if Drivers (i).Present then
            FD := Open (i, File_Path, Flag);
         end if;
         exit when FD /= DRIVER_FD_ERROR;
      end loop;

      return FD;
   end open;

   --------------------
   -- ISO 9660 Read --
   --------------------
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer is
      f_lba    : Natural renames Descriptors (fd).lba;
      f_offset : Integer renames Descriptors (fd).offset;
      f_size   : Natural renames Descriptors (fd).size;
      f_used   : Boolean renames Descriptors (fd).used;
   begin
      if not f_used then
         return -1;
      end if;

      if f_offset = f_size then
         return 0;
      end if;

      if Read_Type'Size <= 0 then
         Logger.Log_Error ("Invalid read size:" & Read_Type'Size'Image);
      end if;
      declare
         Atapi_Driver : Device_Driver.Driver_id renames Descriptors (fd).driver;

         package Conversion is new System.Address_To_Access_Conversions (Read_Type);

         out_buffer     : System.Address :=
           Conversion.To_Address (Conversion.Object_Pointer (Buffer));
         read_buffer    : System.Address;
         base_lba       : Natural := (f_offset / BLOCK_SIZE) + f_lba;
         cnt            : Natural := Read_Type'Size / Storage_Unit;
         Current_Offset : Storage_Offset := Storage_offset (f_offset) mod BLOCK_SIZE;
         read_size      : Natural := Min (cnt, f_size - f_offset);
         sectors_count  : Natural :=
           ((read_size + Natural (Current_Offset) + BLOCK_SIZE - 1) / BLOCK_SIZE);
         count          : Natural;
         procedure memcpy (dest : System.Address; src : System.Address; size : Natural);
         pragma Import (C, memcpy, "memcpy");
      begin
         -- Adjust the offset of the lba
         --  Logger.Log_Info ("Reading: " & base_lba'Image & " + " & Current_Offset'Image & " .. " & Integer (base_lba + sectors_count - 1)'Image);
         for lba in base_lba .. (base_lba + sectors_count - 1) loop
            read_buffer := Atapi_Buffer'Address;
            count := Read_Iso_Block (Drivers (Atapi_Driver), lba, Atapi_Buffer);
            memcpy
              (out_buffer,
               read_buffer + Current_Offset,
               Min (cnt, BLOCK_SIZE - Integer (Current_Offset)));
            out_buffer :=
              out_buffer + Storage_Offset (Min (cnt, BLOCK_SIZE - Integer (Current_Offset)));
            cnt := cnt - Min (cnt, BLOCK_SIZE - Integer (Current_Offset));
            Current_Offset := 0;
         end loop;

         -- Update the offset
         f_offset := f_offset + read_size;
         return read_size;
      end;
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

            f_offset := Natural'Min (f_offset + Natural (offset), f_size);

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
   function Read_Iso_Block (Driver : Device_Driver.Driver; lba : Natural; buffer : out Atapi.SECTOR_BUFFER)
      return Integer
   is
   begin
      case Driver.Driver_Type is
         when Ados.ATAPI_DRIVER =>
            return Atapi.Read_Block (Driver.Atapi_Device, lba, buffer);
         
         when Ados.RAMDISK_DRIVER =>
            return Ramdisk.Read_Block (Driver.Address, lba, buffer);

         when others =>
            raise Program_Error with "Unexpected Driver_Type in Read_Iso_Block";
      end case;
   end Read_Iso_Block;

   function Has_Iso_Filesystem
     (Driver : Device_Driver.Driver; primary_descriptor : out iso_prim_voldesc)
      return Boolean
   is
      use ISO_PRIM_DESC_CONVERTER;
      init_buffer : System.Address;
      Count       : Natural := 0;
   begin
      Logger.Log_Info ("Checking for ISO filesystem on device " & Driver'Image);
      Count := Read_Iso_Block (Driver, 16, Atapi_Buffer);
      init_buffer := Atapi_Buffer'Address;
      primary_descriptor := iso_prim_voldesc_ptr (To_Pointer (init_buffer)).all;
      Logger.Log_Info ("Identifier (should be CD001)" & To_Ada (primary_descriptor.vol_id, False));
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

   procedure Add_Ramdisk_Driver
     (Address : System.Address; iso_volume_descriptor : iso_prim_voldesc) is
   begin
      for I in Drivers'Range loop
         if not Drivers (I).Present then
            Drivers (I) :=
              (Driver_Type  => Ados.RAMDISK_DRIVER,
               Present      => True,
               root_lba     => Natural (iso_volume_descriptor.root_dir.data_blk.le),
               root_dirsize => iso_volume_descriptor.root_dir.file_size.le,
               Address      => Address);
            return;
         end if;
      end loop;
   end Add_Ramdisk_Driver;

   procedure init is
      Volume_Descriptor : iso_prim_voldesc;
      Ramdisk_Start : System.Address;
      pragma Import (C, Ramdisk_Start, "_binary_ramdisk_iso_start");
   begin
      Logger.Log_Info ("Initializing ISO filesystem");
      --  for Atapi_Device in Atapi.Atapi_Device_id'range loop
      --     if Atapi.Is_Present (Atapi_Device)
      --       and then Has_Iso_Filesystem ((Driver_Type => Ados.ATAPI_DRIVER, Present => True,
      --                                    Atapi_Device => Atapi_Device, others => <>),
      --                                   Volume_Descriptor)
      --     then
      --        Add_Atapi_Driver (Atapi_Device, Volume_Descriptor);
      --     end if;
      --  end loop;
      if Has_Iso_Filesystem (
           (Driver_Type => Ados.RAMDISK_DRIVER, Present => True, Address => Ramdisk_Start'Address, others => <>),
           Volume_Descriptor)
      then
         Add_Ramdisk_Driver (Ramdisk_Start'Address, Volume_Descriptor);
         Logger.Log_Ok ("Found Ramdisk fs");
      else
         Logger.Log_Error ("No Ramdisk driver found");
      end if;
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
      Logger.Log_Info ("Directory size: " & Integer'Image (dir_size));
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
               Logger.Log_Info ("File: " & To_Ada (file_name.all, False));
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
