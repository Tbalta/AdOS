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

   function "-"(A,B : Physical_Address) return Storage_Count is
   begin
      return Storage_Count (To_Integer (A - B));
   end "-";

   function To_Address (Address : Virtual_Address) return System.Address is
   begin

      if Address >= 16#8000_0000_0000# then
            return System.Address (Address or 16#FFFF_0000_0000_0000#);
         end if;

      return System.Address (Address);
   end To_Address;
   
end x86;