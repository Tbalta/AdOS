------------------------------------------------------------------------------
--                              VGA-SEQUENCER                               --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with System;
with x86.Port_IO;

package VGA.Sequencer is
   pragma Preelaborate;

   ----------------------------
   -- Set_Sequencer_For_Mode --
   ----------------------------
   procedure Set_Sequencer_For_Mode (mode : VGA_mode);

private
end VGA.Sequencer;
