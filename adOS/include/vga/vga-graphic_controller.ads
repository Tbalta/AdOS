------------------------------------------------------------------------------
--                          VGA-GRAPHIC_CONTROLLER                          --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    register definition for graphic controller registers                  --
------------------------------------------------------------------------------
with System;
with x86.Port_IO;

package VGA.Graphic_Controller is
   pragma Preelaborate;
   procedure Set_Graphic_Controller_For_Mode (mode : VGA_mode);
 
private
end VGA.Graphic_Controller;
