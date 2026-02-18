with System.Storage_Elements; use System.Storage_Elements;
package body x86 is
   
   function To_Integer (Address : Physical_Address) return Integer_Address
   is
   begin
      return To_Integer (System.Address (Address));
   end To_Integer;

   function To_Integer (Address : Virtual_Address) return Integer_Address
   is
   begin
      return To_Integer (System.Address (Address));
   end To_Integer;

   function "+"(Address : Physical_Address; SC : Storage_Count) return Physical_Address is
   begin
      return Physical_Address (Storage_Count (Address) + SC);
   end "+";
   
   function "-"(A,B : Physical_Address) return Storage_Count is
   begin
      return Storage_Count (To_Integer (A - B));
   end "-";
   
end x86;