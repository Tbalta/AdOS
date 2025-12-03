------------------------------------------------------------------------------
--                                   UTIL                                   --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with System;
with System.Address_To_Access_Conversions;
with Util;

package body Util is
   function Read_String_From_Address (addr : System.Address) return String is
      function strlen (s : System.Address) return Integer;
      pragma Import (C, strlen, "strlen");

      length : Integer := strlen (addr);

      subtype path_array is String (1 .. length);
      package Conversion is new System.Address_To_Access_Conversions (path_array);
      path_access : access path_array := Conversion.To_Pointer (addr);
   begin
      return path_access.all;
   end Read_String_From_Address;

   function Round (val : Integer; Alignment : Integer) return Integer is
   begin
      return ((val + Alignment - 1) / Alignment) * Alignment;
   end Round;

   function sqrt (val : Float) return Float is
      x : Float := 0.0;
   begin
      while x * x < val loop
         x := x + 1.0;
      end loop;

      return x;
   end sqrt;

   function Floor_Divide (a, b : Data_Type) return Data_Type is
   begin
      return (a + b - (b / b)) / b;
   end Floor_Divide;

end Util;
