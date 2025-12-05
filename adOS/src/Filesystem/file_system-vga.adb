with VGA;

with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.SERIAL;
with Log;
with Ada.Unchecked_Conversion;

with VGA; use VGA;

package body File_System.VGA is
   package Logger renames Log.Serial_Logger;

   ----------
   -- Open --
   ----------
   procedure Start_VGA (File : File_Information) is
   begin
      Logger.Log_Info ("Starting: " & File'Image);
      if File.Graphic_Mode then
         Set_Graphic_Mode (Width => Integer (File.Width), Height => Integer (File.Height), Color_Depth => Integer (File.Color_Depth));
      else
         Set_Text_Mode (Width => Integer (File.Width), Height => Integer (File.Height), Color_Depth => Integer (File.Color_Depth));
      end if;
   end Start_VGA;

   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      if File_Path = "vga_frame_buffer" then
         if not Descriptors (FRAME_BUFFER_FD).used then
            Logger.Log_Info ("vga_file opened");
            Descriptors (FRAME_BUFFER_FD).used   := True;
            Descriptors (FRAME_BUFFER_FD).offset := 0;
            Start_VGA (Descriptors (FRAME_BUFFER_FD));
            return FRAME_BUFFER_FD;
         end if;
      elsif File_Path = "vga_width" then
            return WIDTH_FD;
      elsif File_Path = "vga_height" then
            return HEIGHT_FD;
      elsif File_Path = "vga_color_depth" then
            return COLORS_FD;
      elsif File_Path = "vga_mode" then
            return MODE_FD;
      end if;

      return DRIVER_FD_ERROR;
   end open;


   ----------
   -- Read --
   ----------
   function read (fd : Driver_File_Descriptor; Buffer : out Read_Type) return Integer is
   begin
      return -1;
   end read;

   ------------------------
   -- Frame_Buffer_Write --
   ------------------------
   function Frame_Buffer_Write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer
      is
         count : constant Storage_Count := Write_Type'Size / Storage_Unit;
         package Conversion is new System.Address_To_Access_Conversions (Write_Type);

         Buffer_Address : System.Address := Conversion.To_Address (Conversion.Object_Pointer (Buffer));

         Frame_Buffer : System.Address := Standard.VGA.Get_Frame_Buffer;

         VGA_FILE : File_Information renames Descriptors (FRAME_BUFFER_FD);
         Vga_Size : Storage_Count := Storage_Count (VGA_FILE.Height * VGA_FILE.Width);
         Write_Size : Storage_Offset := Storage_Offset (Min (Integer (Vga_Size) - Integer (VGA_FILE.offset), Integer (count)));

         procedure memcpy (dst, src : System.Address; count : Storage_Count);
         pragma Import (C, memcpy, "memcpy");
      begin
         if fd /= FRAME_BUFFER_FD or not VGA_FILE.used then
            return -1;
         end if;

         if Write_Size < 0 then
            return -1;
         end if;

         memcpy (Frame_Buffer + Storage_Offset (VGA_FILE.offset), Buffer_Address, Write_Size);

         VGA_FILE.offset := VGA_FILE.offset + Storage_Offset (Write_Size);

         return Integer (Write_Size);
      end Frame_Buffer_Write;
   
   ---------------------
   -- Attribute_Write --
   ---------------------
   function Attribute_Write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer
   is
   begin
      if Descriptors (FRAME_BUFFER_FD).used then
         Logger.Log_Error ("VGA attributes cannot be set while frame_buffer is open");
         return -1;
      end if;

      if Write_Type'Size /= Unsigned_32'Size then
         Logger.Log_Error ("Invalid write size expected: " & Integer (Unsigned_32'Size)'Image & "bits got: " & Integer (Write_Type'Size)'Image);
         return -1;
      end if;

      pragma Assert (Write_Type'Size = Unsigned_32'Size);
      declare
         function To_U32 is new Ada.Unchecked_Conversion(Source => Write_Type, Target => Unsigned_32);
      begin
         case fd is
            when WIDTH_FD =>
               Descriptors (FRAME_BUFFER_FD).Width := Pixel_Count (To_U32 (Buffer.all));
            when HEIGHT_FD =>
               Descriptors (FRAME_BUFFER_FD).Height := Scan_Line_Count (To_U32 (Buffer.all));
            when COLORS_FD =>
               Descriptors (FRAME_BUFFER_FD).Color_Depth := To_U32 (Buffer.all);
            when MODE_FD =>
               Descriptors (FRAME_BUFFER_FD).Graphic_Mode := To_U32 (Buffer.all) = 1;
            when others =>
               Logger.Log_Error ("Invalid fd " & fd'Image);
         end case;
      end;

      return Write_Type'Size / Storage_Unit;
   end Attribute_Write;

   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer is
      function FB_Write is new Frame_Buffer_Write (Write_Type);
      function E_Write is new Attribute_Write (Write_Type);
   begin
      case fd is
         when FRAME_BUFFER_FD =>
            return FB_Write (fd, Buffer);
         when HEIGHT_FD | WIDTH_FD | COLORS_FD | MODE_FD =>
            return E_Write (fd, Buffer);
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

      f_size : Storage_Count := Storage_Count (VGA_FILE.Height * VGA_FILE.Width);
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
            f_offset := f_size + Storage_Offset (offset);
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
   
   function mmap (fd : Driver_File_Descriptor; size : Storage_Count) return System.Address
   is
      VGA_FILE : File_Information renames Descriptors (FRAME_BUFFER_FD);

      f_size : Storage_Count := Storage_Count (VGA_FILE.Height * VGA_FILE.Width);
   begin
      if fd /= FRAME_BUFFER_FD or not Descriptors (FRAME_BUFFER_FD).used then
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
