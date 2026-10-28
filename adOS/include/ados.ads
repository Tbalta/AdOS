package Ados
  with Preelaborate
is
   type Ados_Driver is (SERIAL_DRIVER, ATAPI_DRIVER, RAMDISK_DRIVER);
   procedure Stack_Check_Fail;
   pragma Export (C, Stack_Check_Fail, "__stack_chk_fail");
end Ados;
