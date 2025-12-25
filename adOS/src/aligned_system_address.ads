with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;

generic
   Alignment : Storage_Offset;
package Aligned_System_Address is
   pragma Preelaborate;
   use all type Storage_Offset;

   subtype Aligned_Address is System.Address
   with
     Dynamic_Predicate =>
       ((Storage_Offset (To_Integer (System.Address'(Aligned_Address))) mod Alignment) = 0);

   function Align (addr : System.Address) return Aligned_Address
   is (Aligned_Address ((To_Integer (addr) + Integer_Address (Alignment) - 1) / Integer_Address (Alignment) * Integer_Address (Alignment)));


private
end Aligned_System_Address;
