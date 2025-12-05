with File_System; use File_System;
with Interfaces; use Interfaces;
with Log;

package body VGA.DAC is
   package Logger renames Log.Serial_Logger;
   procedure load_color (C : Palette_Color) is
   begin
      Write_Palette_Data_Register (C.Red);
      Write_Palette_Data_Register (C.Green);
      Write_Palette_Data_Register (C.Blue);
   end load_color;

   procedure load_default_palette is
   begin
      Write_Address (0);

      for C of Default_Palette loop
         load_color (C);
      end loop;
   end load_default_palette;

   procedure load_palette (p : Path) is
      type palette_file_color is record
         Red : String (1 .. 2);
         Green : String (1 .. 2);
         Blue : String (1 .. 2);
      end record;

      for palette_file_color use record
         Red at 0 range 0 .. 15;
         Green at 2 range 0 .. 15;
         Blue at 4 range 0 .. 15;
      end record;

      function To_Palette_Color (c : palette_file_color) return Palette_Color
      is
      begin
         return (RED => Color (Shift_Right (Unsigned_8'Value ("16#" & c.Red &"#"), 2)),
               Green => Color (Shift_Right (Unsigned_8'Value ("16#" & c.Green &"#"), 2)),
               Blue => Color (Shift_Right (Unsigned_8'Value ("16#" & c.Blue &"#"), 2)));
      end;
      function Palette_Read is new read (palette_file_color);
      fd : File_Descriptor_With_Error;

      palette_color : aliased palette_file_color;
   begin
      fd := open (p, 0);
      Write_Address (0);
      while Palette_Read (fd, palette_color'Access) > 0 loop
         load_color (To_Palette_Color (palette_color));
         seek (fd, 1, SEEK_CUR);
      end loop;

      close (fd);
   end load_palette;

end VGA.DAC;
