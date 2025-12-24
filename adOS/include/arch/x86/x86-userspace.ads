------------------------------------------------------------------------------
--                              X86.USERSPACE                               --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with x86.vmm;

package x86.Userspace is
   pragma Preelaborate;

   procedure Jump_To_Userspace (Entry_Point : System.Address; CR3 : x86.vmm.CR3_register);

end x86.Userspace;
