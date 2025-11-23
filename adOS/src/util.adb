with System;
with System.Address_To_Access_Conversions;

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


end Util;
