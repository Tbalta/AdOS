with VGA;

with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.SERIAL;
with Loggers;
with Ada.Unchecked_Conversion;

with VGA; use VGA;
with VGA.DAC;
with Limine;

package body File_System.Limine is
   package Logger renames Loggers.Serial_Logger;

   ----------
   -- Open --
   ----------
   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      if File_Path = "framebuffer" then
         if not Descriptors (FRAME_BUFFER_FD).used then
            Logger.Log_Info ("vga_file opened");
            Descriptors (FRAME_BUFFER_FD).used := True;
            Descriptors (FRAME_BUFFER_FD).offset := 0;
            Descriptors (FRAME_BUFFER_FD).framebuffer := Standard.Limine.framebuffer_response.framebuffers (1);
            return FRAME_BUFFER_FD;
         end if;
      elsif File_Path = "info" then
         return INFO_FD;
      end if;

      return DRIVER_FD_ERROR;
   end open;


   ----------
   -- Read --
   ----------
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer is
      function To_Read_Type is new Ada.Unchecked_Conversion (Source => Frame_Buffer_Information, Target => Read_Type);
      FD_File : File_Information renames Descriptors (FRAME_BUFFER_FD);
   begin
      case fd is
         when INFO_FD =>
            pragma Assert (Read_Type'Size = Frame_Buffer_Information'Size);
            Buffer.all := To_Read_Type ((
               width => FD_File.framebuffer.width,
               height => FD_File.framebuffer.height,
               pitch => FD_File.framebuffer.pitch,
               bpp => FD_File.framebuffer.bpp,
               red_mask_size => FD_File.framebuffer.red_mask_size,
               red_mask_shift => FD_File.framebuffer.red_mask_shift,
               green_mask_size => FD_File.framebuffer.green_mask_size,
               green_mask_shift => FD_File.framebuffer.green_mask_shift,
               blue_mask_size => FD_File.framebuffer.blue_mask_size,
               blue_mask_shift => FD_File.framebuffer.blue_mask_shift));
            return Read_Type'Size / Storage_Unit;
         when others =>
            return -1;
      end case;
   end read;

   ------------------------
   -- Frame_Buffer_Write --
   ------------------------
   function Frame_Buffer_Write
     (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer
   is
      count : constant Storage_Count := Write_Type'Size / Storage_Unit;
      package Conversion is new System.Address_To_Access_Conversions (Write_Type);

      Buffer_Address : System.Address := Conversion.To_Address (Conversion.Object_Pointer (Buffer));


      FB_File   : File_Information renames Descriptors (FRAME_BUFFER_FD);
      f_height : Storage_Count renames  Storage_Count (FB_File.framebuffer.Height);
      f_width : Storage_Count renames  Storage_Count (FB_File.framebuffer.Width);
      f_bpp : Storage_Count renames  Storage_Count (FB_File.framebuffer.Bpp);

      Frame_Buffer : System.Address := FB_File.framebuffer.Address;
      f_size : Storage_Count := Storage_Count (f_height * f_width * (f_bpp / 8));
      Write_Size : Storage_Count :=
        Storage_Count (Min (Integer (f_size) - Integer (FB_File.offset), Integer (count)));

      procedure memcpy (dst, src : System.Address; count : Storage_Count);
      pragma Import (C, memcpy, "memcpy");
   begin
      if fd /= FRAME_BUFFER_FD or not FB_File.used then
         return -1;
      end if;

      if Write_Size < 0 then
         return -1;
      end if;

      memcpy (Frame_Buffer + Storage_Offset (FB_File.offset), Buffer_Address, Write_Size);

      FB_File.offset := FB_File.offset + Storage_Offset (Write_Size);

      return Integer (Write_Size);
   end Frame_Buffer_Write;


   

   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer is
      function FB_Write is new Frame_Buffer_Write (Write_Type);
   begin
      case fd is
         when FRAME_BUFFER_FD =>
            return FB_Write (fd, Buffer);
         when others =>
            return -1;
      end case;
   end write;

   -------------------
   -- SERIAL Seek --
   -------------------
   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t is
      VGA_FILE : File_Information renames Descriptors (FRAME_BUFFER_FD);
      f_offset : Storage_Offset renames Descriptors (FRAME_BUFFER_FD).offset;
      f_height : Storage_Count renames  Storage_Count (VGA_FILE.framebuffer.Height);
      f_width : Storage_Count renames  Storage_Count (VGA_FILE.framebuffer.Width);
      f_bpp : Storage_Count renames  Storage_Count (VGA_FILE.framebuffer.Bpp);

      f_size : Storage_Count := Storage_Count (f_height * f_width * (f_bpp / 8));
   begin
      if fd /= FRAME_BUFFER_FD or not VGA_FILE.used then
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
            f_offset := Storage_Offset (f_size) + Storage_Offset (offset);
      end case;
      return off_t (f_offset);
   end seek;

   ------------------
   -- SERIAL Close --
   ------------------
   function close (fd : Driver_File_Descriptor) return Integer is
   begin
      if fd /= FRAME_BUFFER_FD or not Descriptors (FRAME_BUFFER_FD).used then
         return -1;
      end if;

      Descriptors (FRAME_BUFFER_FD).used := False;
      return 0;
   end close;

   function mmap (fd : Driver_File_Descriptor; size : Storage_Count) return System.Address is
      FB_File : File_Information renames Descriptors (FRAME_BUFFER_FD);
      f_height : Storage_Count renames  Storage_Count (FB_File.framebuffer.Height);
      f_width : Storage_Count renames  Storage_Count (FB_File.framebuffer.Width);
      f_bpp : Storage_Count renames  Storage_Count (FB_File.framebuffer.Bpp);
      f_size : Storage_Count := Storage_Count (f_height * f_width * (f_bpp / 8));
   begin
      if fd /= FRAME_BUFFER_FD or not FB_File.used then
         Logger.Log_Error ("Invalid framebuffer fd");
         return System.Null_Address;
      end if;

      if size /= f_size then
         Logger.Log_Error ("Size mismatch");
         return System.Null_Address;
      end if;

      return FB_File.framebuffer.Address;
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

end File_System.Limine;
