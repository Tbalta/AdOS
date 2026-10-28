package body x86.vmm.vab is


   procedure Next (Address : in out Virtual_Address_Break)
   is
   begin
      Address := To_Virtual_Address_Break (From_Virtual_Address_Break (Address) + PAGE_SIZE);
      Address.Offset := 0;
   end Next;

   procedure Next (Address : in out Virtual_Address)
   is
      Address_Break : Virtual_Address_Break := To_Virtual_Address_Break (Address);
   begin
      Next (Address_Break);
      Address := From_Virtual_Address_Break (Address_Break);
   end Next;



end x86.vmm.vab;