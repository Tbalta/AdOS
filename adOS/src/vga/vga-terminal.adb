------------------------------------------------------------------------------
--                               VGA-TERMINAL                               --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with VGA;
package body VGA.Terminal is


   function Parse_Attribute (Attr : in String) return Character_Attribute is
      Attribute : Character_Attribute;
   begin
      pragma Assert (Attr (Attr'First) = Character'Val (16#1B#));

      declare
         Current_Code : String := Attr (Attr'First + 2 .. Attr'Last);
      begin
         if Current_Code (Current_Code'First) = '3' then
            Attribute.Foreground := Unsigned_4'Value (Current_Code (Current_Code'First + 1 .. Current_Code'First + 1));
         elsif Current_Code (Current_Code'First) = '4' then
            Attribute.Background := Unsigned_4'Value (Current_Code (Current_Code'First + 1 .. Current_Code'First + 1));
         end if;
      end;
      return Attribute;
   end Parse_Attribute;

   procedure Sroll_Up is
      Buffer : access vga_buffer := Conversion.To_Pointer (VGA.Get_Frame_Buffer);
   begin
      Buffer (1 .. 80 * 24) := Buffer (81 .. 80 * 25);
      Buffer (80 * 24 + 1 .. 80 * 25) := (others => (c => ' ', attribute => (Foreground => 16#F#, Background => 0)));
   end Sroll_Up;

   procedure New_Line is
   begin
      if current_line = 25 then
         Sroll_Up;
      else
         current_line := current_line + 1;
      end if;
      current_column := 1;
   end New_Line;

   procedure Put_Char (Char : VGA_CHAR) is
      Buffer : access vga_buffer := Conversion.To_Pointer (VGA.Get_Frame_Buffer);
   begin
      Buffer ((current_line - 1) * 80 + current_column) := Char;
      
      if current_column = 80 then
         current_column := 1;
         New_Line;
      else
         current_column := current_column + 1;
      end if;
   end Put_Char;

   procedure Put_String (Str : in String) is
      Buffer : access vga_buffer := Conversion.To_Pointer (VGA.Get_Frame_Buffer);
      Attribute : Character_Attribute := (Foreground => 16#F#, Background => 0);
      I : Positive := Str'First;
   begin
      while I <= Str'Last loop
         if Str (I) = Character'Val (16#1B#) then
            Attribute := Parse_Attribute (Str (I .. Str'Last));
            while Str (I) /= 'm' loop
               I := I + 1;
            end loop;
         else
            Put_Char ((c => Str (I), attribute => Attribute));
         end if;
         I := I + 1;
      end loop;
      New_Line;

   end Put_String;

end VGA.Terminal;