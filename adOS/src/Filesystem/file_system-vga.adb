with VGA;

with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.SERIAL;
with Log;
with Ada.Unchecked_Conversion;

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
      if File_Path = "vga_frame_buffer" then
         if not Descriptors (FRAME_BUFFER_FD).used then
            Logger.Log_Info ("vga_file opened");
            Descriptors (FRAME_BUFFER_FD).used   := True;
            Descriptors (FRAME_BUFFER_FD).Width  := 320;
            Descriptors (FRAME_BUFFER_FD).Height := 200;
            Descriptors (FRAME_BUFFER_FD).offset := 0;
            return FRAME_BUFFER_FD;
         end if;
      elsif File_Path = "vga_height" then
            return HEIGHT_FD;
      elsif File_Path = "vga_width" then
            return WIDTH_FD;
      elsif File_Path = "vga_graphic_mode" then
            return GRAPHIC_FD;
      elsif File_Path = "vga_enable" then
            return ENABLE_FD;
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

   -----------
   -- Write --
   -----------

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
   
      function Height_Write (fd : Driver_File_Descriptor; Height : access Write_Type) return Integer
      is
         function To_U32 is new Ada.Unchecked_Conversion(Source => Write_Type, Target => Unsigned_32);
      begin
         if Descriptors (FRAME_BUFFER_FD).used then
            Logger.Log_Error ("Height cannot be written while frame_buffer is open");
            return -1;
         end if;

         if Write_Type'Size /= Unsigned_32'Size then
            Logger.Log_Error ("Invalid write size expected: " & Integer (Unsigned_32'Size)'Image & "bits got: " & Integer (Write_Type'Size)'Image);
            return -1;
         end if;

         Logger.Log_Info ("Height: " & To_U32 (Height.all)'Image);
         Descriptors (FRAME_BUFFER_FD).Height := Standard.VGA.Scan_Line_Count (To_U32 (Height.all));

         return Write_Type'Size / Storage_Unit;
      end Height_Write;
   


      function Width_Write (fd : Driver_File_Descriptor; Width : access Write_Type) return Integer
            is
         function To_U32 is new Ada.Unchecked_Conversion(Source => Write_Type, Target => Unsigned_32);
      begin
         if Descriptors (FRAME_BUFFER_FD).used then
            Logger.Log_Error ("Width cannot be written while frame_buffer is open");
            return -1;
         end if;

         if Write_Type'Size /= Unsigned_32'Size then
            Logger.Log_Error ("Invalid write size expected: " & Integer (Unsigned_32'Size)'Image & "bits got: " & Integer (Write_Type'Size)'Image);
            return -1;
         end if;

         Descriptors (FRAME_BUFFER_FD).Width := Standard.VGA.Character_Count (To_U32 (Width.all));
         return Write_Type'Size / Storage_Unit;
      end Width_Write;
   
   
   function Graphic_Write (fd : Driver_File_Descriptor; Mode : access Write_Type) return Integer
         is
      function To_U32 is new Ada.Unchecked_Conversion(Source => Write_Type, Target => Unsigned_32);
   begin
      if Descriptors (FRAME_BUFFER_FD).used then
         Logger.Log_Error ("Graphic mode cannot be set while frame_buffer is open");
         return -1;
      end if;

      if Write_Type'Size /= Unsigned_32'Size then
         Logger.Log_Error ("Invalid write size expected: " & Integer (Unsigned_32'Size)'Image & "bits got: " & Integer (Write_Type'Size)'Image);
         return -1;
      end if;

      if To_U32 (Mode.all) = 0 then
         Descriptors (FRAME_BUFFER_FD).Graphic_Mode := False;
      else
         Descriptors (FRAME_BUFFER_FD).Graphic_Mode := True;
         Descriptors (FRAME_BUFFER_FD).Color_Depth := To_U32 (Mode.all);
         Logger.Log_Info ("Color: " & To_U32 (Mode.All)'image);
      end if;
      return Write_Type'Size / Storage_Unit;
   end Graphic_Write;


   function Enable_Write (fd : Driver_File_Descriptor; Mode : access Write_Type) return Integer
   is
      VGA_FILE : File_Information renames Descriptors (FRAME_BUFFER_FD);
      function To_U32 is new Ada.Unchecked_Conversion(Source => Write_Type, Target => Unsigned_32);
   begin
      if Descriptors (FRAME_BUFFER_FD).used then
         Logger.Log_Error ("Enable cannot be set while frame_buffer is open");
         return -1;
      end if;

      if Write_Type'Size /= Unsigned_32'Size then
         Logger.Log_Error ("Invalid write size expected: " & Integer (Unsigned_32'Size)'Image & " bits got: " & Integer (Write_Type'Size)'Image);
         return -1;
      end if;

      if To_U32 (Mode.all) = 1 and then VGA_FILE.Graphic_Mode then
         Standard.VGA.Set_Graphic_Mode (VGA_FILE.Width, VGA_FILE.Height, Integer (VGA_FILE.Color_Depth));
      end if;

      return Write_Type'Size / Storage_Unit;
   end Enable_Write;

   function write (fd : Driver_File_Descriptor; Buffer : access Write_Type) return Integer is
      function FB_Write is new Frame_Buffer_Write (Write_Type);
      function H_Write is new Height_Write (Write_Type);
      function W_Write is new Width_Write (Write_Type);
      function G_Write is new Graphic_Write (Write_Type);
      function E_Write is new Enable_Write (Write_Type);

   begin
      case fd is
         when FRAME_BUFFER_FD =>
            return FB_Write (fd, Buffer);
         when HEIGHT_FD =>
            return H_Write (fd, Buffer);
         when WIDTH_FD =>
            return W_Write (fd, Buffer);
         when GRAPHIC_FD =>
            return G_Write (fd, Buffer);
         when ENABLE_FD =>
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
