------------------------------------------------------------------------------
--                               VGA-TERMINAL                               --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
--                                                                          --
------------------------------------------------------------------------------

with System.Address_To_Access_Conversions;
with System.Storage_Elements; use System.Storage_Elements;
package VGA.Terminal is
   pragma Preelaborate;

   procedure Put_String (Str : in String);
   procedure Send_Raw_Buffer (Buffer : System.Address; size : Storage_Count);


private
   procedure Sroll_Up;
   type Character_Attribute is record
      Foreground : Unsigned_4 := 16#F#;
      Background : Unsigned_4 := 0;
   end record;
   for Character_Attribute use
         record
            Foreground at 0 range 0 .. 3;
            Background at 0 range 4 .. 7;
         end record;
   type VGA_CHAR is record
         c         : Character;
         attribute : Character_Attribute;
   end record;
   for VGA_CHAR use
        record
          c at 0 range 0 .. 7;
          attribute at 1 range 0 .. 7;
        end record;

   type vga_buffer is array (Positive range 1 .. 80 * 25) of aliased VGA_CHAR with Pack => True;
   package Conversion is new System.Address_To_Access_Conversions (vga_buffer);

   current_line : Positive range 1 .. 25 := 1;
   current_column : Positive range 1 .. 80 := 1;

end VGA.Terminal;