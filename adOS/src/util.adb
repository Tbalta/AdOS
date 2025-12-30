------------------------------------------------------------------------------
--                                   UTIL                                   --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with System;
with System.Address_To_Access_Conversions;
with Loggers;
package body Util is
   package Logger renames Loggers;

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

   function Round (val : Data_Type; Alignment : Data_Type) return Data_Type is
   begin
      return ((val + Alignment - (Alignment / Alignment)) / Alignment) * Alignment;
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

   function To_Hex (a : Data_Type; Size : Natural := 0) return String is
      hex_array : constant String := "0123456789ABCDEF";
      String_Length : Positive := 1;

      A_Param : Data_Type := A;
   begin
      if Size = 0 then
         while (A_Param / Data_Type'Val (16)) /= Data_Type'Val (0) loop
            String_Length := String_Length + 1;
            A_Param := A_Param / Data_Type'Val (16);
         end loop;
      else
         String_Length := Size;
      end if;


      A_Param := A;
      return Result : String (1 .. String_Length + 2) do
         Result := (others => '0');

         for I in reverse 3 .. Result'Last loop
            Result (I) := hex_array (Positive ((Data_Type'Pos (A_Param) mod 16) + 1));
            A_Param := A_Param / Data_Type'Val (16);
         end loop;
         Result (1 .. 2) := "0x";
      end return;
   end To_Hex;

end Util;
