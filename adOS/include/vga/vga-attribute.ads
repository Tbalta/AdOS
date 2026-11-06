------------------------------------------------------------------------------
--                              VGA-ATTRIBUTE                               --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with System;
with x86.Port_IO;
with Interfaces; use Interfaces;
with VGA;

package VGA.Attribute is
   pragma Preelaborate;

   ----------------------------
   -- Set_Attribute_For_Mode --
   ----------------------------
   procedure Set_Attribute_For_Mode (mode : VGA_Mode);


   ------------------------------
   -- Reset_Attribute_Register --
   ------------------------------
   procedure Reset_Attribute_Register;

private
end VGA.Attribute;
