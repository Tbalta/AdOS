------------------------------------------------------------------------------
--                             VGA-ATTRIBUTE                                --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    register definition for attribute registers                           --
------------------------------------------------------------------------------
with System;
with x86.Port_IO;
with Interfaces; use Interfaces;
with VGA;

package VGA.Attribute is
   pragma Preelaborate;

   procedure Set_Attribute_For_Mode (mode : VGA_Mode);
   procedure Reset_Attribute_Register;

private
end VGA.Attribute;
