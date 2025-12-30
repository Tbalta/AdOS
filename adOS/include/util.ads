------------------------------------------------------------------------------
--                                   UTIL                                   --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with System;

package Util is
   pragma Preelaborate;

   function Read_String_From_Address (addr : System.Address) return String;

   generic
      type Data_Type is (<>);
      with function "+" (Left, Right : Data_Type) return Data_Type is <>;
      with function "-" (Left, Right : Data_Type) return Data_Type is <>;
      with function "/" (Left, Right : Data_Type) return Data_Type is <>;
      with function "*" (Left, Right : Data_Type) return Data_Type is <>;
      function Round (val : Data_Type; Alignment : Data_Type) return Data_Type;

   function sqrt (val : Float) return Float;

   generic
      type Data_Type is(<>);
      with function "+" (Left, Right : Data_Type) return Data_Type is <>;
      with function "-" (Left, Right : Data_Type) return Data_Type is <>;
      with function "/" (Left, Right : Data_Type) return Data_Type is <>;
   function Floor_Divide (a, b : Data_Type) return Data_Type;
   
   generic
      type Data_Type is(<>);
      with function "/" (Left, Right : Data_Type) return Data_Type is <>;
      with function "mod" (Left, Right : Data_Type) return Data_Type is <>;
   function To_Hex (a : Data_Type; Size : Natural := 0) return String;

end Util;
