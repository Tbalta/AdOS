------------------------------------------------------------------------------
--                                   UTIL                                   --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with System;

package Util is
   pragma Preelaborate;

   function Read_String_From_Address (addr : System.Address) return String;

   function Round (val : Integer; Alignment : Integer) return Integer;

   function sqrt (val : Float) return Float;

   generic
      type Data_Type is(<>);
      with function "+" (Left, Right : Data_Type) return Data_Type is <>;
      with function "-" (Left, Right : Data_Type) return Data_Type is <>;
      with function "/" (Left, Right : Data_Type) return Data_Type is <>;
   function Floor_Divide (a, b : Data_Type) return Data_Type;

end Util;
