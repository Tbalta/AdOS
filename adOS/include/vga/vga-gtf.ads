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

   type VGA_Timing is record
      Total_H        : Character_Count;
      Active_H_Chars : Character_Count;

      H_Blanking_Start    : Character_Count;
      H_Blanking_Duration : Character_Count;

      H_Retrace_Start    : Character_Count;
      H_Retrace_Duration : Character_Count;

      Total_V        : Scan_Line_Count;
      Active_V_Chars : Scan_Line_Count;

      V_Blanking_Start    : Scan_Line_Count;
      V_Blanking_Duration : Scan_Line_Count;

      V_Retrace_Start    : Scan_Line_Count;
      V_Retrace_Duration : Scan_Line_Count;
   end record;



   function Compute_Timing
     (H_PIXELS : Pixel_Count; V_LINES : Scan_Line_Count) return VGA_Timing;
private


end VGA.GTF;
