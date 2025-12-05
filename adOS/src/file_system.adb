with File_System.ISO;
with File_System.SERIAL;
with File_System.VGA;
with System.Storage_Elements; use System.Storage_Elements;
package body File_System is

   function Is_File_Descriptor (fd : Integer) return Boolean is
   begin
      return fd in Integer (File_Descriptor'First) .. Integer (File_Descriptor'Last);
   end Is_File_Descriptor;

   function Is_Valid_Whence (wh : Integer) return Boolean is
   begin
      return Integer'Pos (wh) in whence'Pos (SEEK_SET) .. whence'Pos (SEEK_END);
   end Is_Valid_Whence;

   function Add_File
     (File_System : File_System_Type; File_System_Decriptor : Driver_File_Descriptor_With_Error)
      return File_Descriptor is
   begin
      for i in Descriptors'Range loop
         if not Descriptors (i).Valid then
            Descriptors (i).Valid := True;
            Descriptors (i).File_System := File_System;
            Descriptors (i).File_System_Decriptor := File_System_Decriptor;
            return i;
         end if;
      end loop;
      return FD_ERROR;
   end Add_File;

   function open
     (FS : File_System_Type; File_Path : Path; flag : Integer)
      return Driver_File_Descriptor_With_Error is
   begin
      case FS is
         when SERIAL_FS =>
            return File_System.SERIAL.open (File_Path, flag);

         when ISO_FS =>
            return File_System.ISO.open (File_Path, flag);

         when VGA_FS =>
            return File_System.VGA.open (File_Path, flag);

         when others =>
            return DRIVER_FD_ERROR;
      end case;
   end open;

   function open (file_path : Path; flag : Integer) return File_Descriptor_With_Error is
      Driver_FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
      FD        : File_Descriptor_With_Error := FD_ERROR;
   begin

      for File_System in SERIAL_FS .. VGA_FS loop
         Driver_FD := Open (File_System, File_Path, Flag);

         if (Driver_FD /= DRIVER_FD_ERROR) then
            FD := Add_File (File_System, Driver_FD);
         end if;

         exit when FD /= FD_ERROR;
      end loop;

      return FD;

   end open;

   function read (fd : File_Descriptor; Buffer : access Read_Type) return Integer is
      Result : Integer := -1;
      File   : VFS_File;

      function Iso_Read is new File_System.ISO.read (Read_Type);
   begin
      File := Descriptors (fd);
      if not File.Valid then
         return -1;
      end if;

      case File.File_System is
         when SERIAL_FS =>
            Result := -1; -- File_System.SERIAL.read (File.File_System_Decriptor, Buffer);

         when ISO_FS =>
            Result := Iso_Read (File.File_System_Decriptor, Buffer);

         when others =>
            Result := -1;
      end case;

      return Result;
   end read;

   function write (fd : File_Descriptor; Buffer : access Write_Type) return Integer is
      function Serial_Write is new File_System.SERIAL.write (Write_Type);
      function VGA_Write is new File_System.VGA.write (Write_Type);

      File : VFS_File := Descriptors (fd);
   begin
      if not File.Valid then
         return -1;
      end if;

      case File.File_System is
         when SERIAL_FS =>
            return Serial_Write (File.File_System_Decriptor, Buffer);

         when ISO_FS =>
            return -1;

         when VGA_FS =>
            return VGA_Write (File.File_System_Decriptor, Buffer);

         when others =>
            return -1;
      end case;
   end write;

   function seek (fd : File_Descriptor; offset : off_t; wh : whence) return off_t is
      Result : off_t := -1;
      File   : constant VFS_File := Descriptors (fd);
   begin
      if not File.Valid then
         return -1;
      end if;

      case File.File_System is
         when SERIAL_FS =>
            Result := -1; -- File_System.SERIAL.seek (File.File_System_Decriptor, offset, wh);

         when ISO_FS =>
            Result := File_System.ISO.seek (File.File_System_Decriptor, offset, wh);

         when others =>
            Result := -1;
      end case;
      return Result;
   end seek;

   procedure seek (fd : File_Descriptor; offset : off_t; wh : whence) is
      Result : off_t := -1;
      pragma Unreferenced (Result);
   begin
      Result := seek (fd, offset, wh);
   end seek;

   function close (fd : File_Descriptor) return Integer is
      Result : Integer := -1;
      File   : constant VFS_File := Descriptors (fd);
   begin
      if not File.Valid then
         return -1;
      end if;

      case File.File_System is
         when SERIAL_FS =>
            Result := -1; -- File_System.SERIAL.close (File.File_System_Decriptor);

         when ISO_FS =>
            Result := File_System.ISO.close (File.File_System_Decriptor);
         
         when VGA_FS =>
            Result := File_System.VGA.close (File.File_System_Decriptor);


         when others =>
            Result := -1;
      end case;

      if Result = 0 then
         Descriptors (fd).Valid := False;
      end if;

      return Result;
   end close;

   procedure close (fd : File_Descriptor) is 
      Result : Integer;
      pragma Unreferenced (Result);
   begin
      Result := close (fd);
   end close;


   function mmap (fd : File_Descriptor; size : Storage_Count) return System.Address is
      File : VFS_File := Descriptors (fd);
   begin
      if not File.Valid then
         return System.Null_Address;
      end if;

      case File.File_System is
         when SERIAL_FS =>
            return System.Null_Address;

         when ISO_FS =>
            return System.Null_Address;

         when VGA_FS =>
            return File_System.VGA.mmap (File.File_System_Decriptor, size);

         when others =>
            return System.Null_Address;
      end case;

   end mmap;


end File_System;
