------------------------------------------------------------------------------
--                                   ADOS                                   --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

package Ados
  with Preelaborate
is
   type Ados_Driver is (SERIAL_DRIVER, ATAPI_DRIVER, RAMDISK_DRIVER);
   procedure Stack_Check_Fail;
   pragma Export (C, Stack_Check_Fail, "__stack_chk_fail");
end Ados;
