-------------------------------------------------------------------------------
--  X86
--
--  Purpose:
--    This package contains support code for the x86 system.
-------------------------------------------------------------------------------
with System;
with System.Storage_Elements; use System.Storage_Elements;
package x86 is
   pragma Pure;

   type Physical_Address is new System.Address;
   subtype Virtual_Address is  System.Address;


   function To_Integer (Address : Physical_Address) return Integer_Address;
   --  function To_Integer (Address : Virtual_Address) return Integer_Address;
   function "+" (Address : Physical_Address; SC : Storage_Count) return Physical_Address;
   function "-"(A,B : Physical_Address) return Storage_Count;

end x86;
