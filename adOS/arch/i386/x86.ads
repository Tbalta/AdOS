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
   type Virtual_Address is new System.Address;

   function To_Integer (Address : Physical_Address) return Integer_Address;
   function To_Address (Address : Virtual_Address) return System.Address is (System.Address (Address));
   function To_Virtual_Address (Address : System.Address) return Virtual_Address is (Virtual_Address (Address));
   function "+" (Address : Physical_Address; SC : Storage_Count) return Physical_Address;
   function "+"(Address : Virtual_Address; SC : Storage_Count) return Virtual_Address is (Virtual_Address (Storage_Count (Address) + SC));
   function "-"(A,B : Physical_Address) return Storage_Count;
   function "-"(A, B : Virtual_Address) return Storage_Count is (Storage_Count (A) - Storage_Count (B));
end x86;
