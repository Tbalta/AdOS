with System;          use System;
with System.Storage_Elements; use System.Storage_Elements;
generic
    Alignment : Positive;
package Aligned_System_Address is
    pragma Preelaborate;

    subtype Aligned_Address is System.Address with
          Dynamic_Predicate =>
           ((To_Integer (System.Address'(Aligned_Address)) mod Integer_Address (Alignment)) = 0);
    function Align (Address : System.Address) return Aligned_Address is
        (Aligned_Address ((Positive (To_Integer (Address)) + Alignment - 1) / Alignment * Alignment));

private
end Aligned_System_Address;
