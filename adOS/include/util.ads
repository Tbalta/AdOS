with System;

package Util is
   pragma Preelaborate;

   function Read_String_From_Address (addr : System.Address) return String;

   function Round (val : Integer; Alignment : Integer) return Integer;

   function sqrt (val : Float) return Float;

end Util;
