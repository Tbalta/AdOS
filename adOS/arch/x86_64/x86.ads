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
   use all type System.Address;

   type Physical_Address is new System.Address;
   type Virtual_Address is new  System.Address range 0 .. System.Address (2**48 - 1);

   CANONICAL_ADDRESS_MASK : constant System.Address := 16#FFFF_FFFF_FFFF#;

   function To_Virtual_Address (Address : System.Address) return Virtual_Address is (Virtual_Address (Address and CANONICAL_ADDRESS_MASK));
   function To_Address (Address : Virtual_Address) return System.Address;
   function To_Integer (Address : Physical_Address) return Integer_Address;
   --  function To_Integer (Address : Virtual_Address) return Integer_Address;
   function "+"(Address : Physical_Address; SC : Storage_Count) return Physical_Address is (Physical_Address (Storage_Count (Address) + SC));

   function "+"(Address : Virtual_Address; SC : Storage_Count) return Virtual_Address is (Virtual_Address (Storage_Count (Address) + SC));
   function "-"(A,B : Physical_Address) return Storage_Count;
   function "-"(A : Virtual_Address; B : Storage_Offset) return Virtual_Address is (Virtual_Address (Storage_Count (A) - Storage_Count (B)));

end x86;
