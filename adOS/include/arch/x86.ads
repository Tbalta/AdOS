-------------------------------------------------------------------------------
--  X86
--
--  Purpose:
--    This package contains support code for the x86 system.
-------------------------------------------------------------------------------
with System;

package x86 is
   pragma Pure;

   subtype Physical_Address is System.Address;
   subtype Virtual_Address is System.Address;

end x86;
