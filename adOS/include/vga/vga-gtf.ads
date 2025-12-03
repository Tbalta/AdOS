------------------------------------------------------------------------------
--                                 VGA-GTF                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    GTF computation for VGA.                                              --
------------------------------------------------------------------------------

package VGA.GTF is
   pragma Preelaborate;

   generic
      type Data_Type is(<>);
      with function "+" (Left, Right : Data_Type) return Data_Type is <>;
      with function "-" (Left, Right : Data_Type) return Data_Type is <>;
      with function "/" (Left, Right : Data_Type) return Data_Type is <>;
   function Round_Divide (a, b : Data_Type) return Data_Type;

   function Get_Configuration
     (H_PIXELS : Pixel_Count; V_LINES : Scan_Line_Count) return VGA_Configuration;
private


end VGA.GTF;
