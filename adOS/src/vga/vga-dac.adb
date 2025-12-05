------------------------------------------------------------------------------
--                                 VGA-DAC                                  --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with File_System; use File_System;
with Interfaces; use Interfaces;
with Log;

package body VGA.DAC is
   package Logger renames Log.Serial_Logger;

   ----------------
   -- Load_Color --
   ----------------
   procedure Load_Color (C : Palette_Color) is
   begin
      Write_Palette_Data_Register (C.Red);
      Write_Palette_Data_Register (C.Green);
      Write_Palette_Data_Register (C.Blue);
   end Load_Color;

   --------------------------
   -- Load_Default_Palette --
   --------------------------
   procedure Load_Default_Palette is
   begin
      Write_Address (0);

      for C of Default_Palette loop
         Load_Color (C);
      end loop;
   end Load_Default_Palette;

   ---------------
   -- Load_File --
   ---------------
   procedure Load_File (file : Path) is
      type File_Entry is record
         Red : String (1 .. 2);
         Green : String (1 .. 2);
         Blue : String (1 .. 2);
      end record;

      for File_Entry use record
         Red at 0 range 0 .. 15;
         Green at 2 range 0 .. 15;
         Blue at 4 range 0 .. 15;
      end record;

      function To_Palette_Color (c : File_Entry) return Palette_Color
      is
      begin
         return (RED => Color (Shift_Right (Unsigned_8'Value ("16#" & c.Red &"#"), 2)),
               Green => Color (Shift_Right (Unsigned_8'Value ("16#" & c.Green &"#"), 2)),
               Blue => Color (Shift_Right (Unsigned_8'Value ("16#" & c.Blue &"#"), 2)));
      end;
      function Palette_Read is new read (File_Entry);
      fd : File_Descriptor_With_Error;

      palette_color : aliased File_Entry;
   begin

      fd := open (file, 0);
      if fd = FD_ERROR then
         Logger.Log_Error ("Unable to open palette file " & String (file));
         return;
      end if;


      Write_Address (0);
      while Palette_Read (fd, palette_color'Access) > 0 loop
         Load_Color (To_Palette_Color (palette_color));
         seek (fd, 1, SEEK_CUR);
      end loop;

      close (fd);
   end Load_File;

end VGA.DAC;
