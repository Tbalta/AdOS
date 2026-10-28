package x86.vmm.vab is
   pragma Preelaborate;


   -- Vol-5.3 Figure 5-2. Linear-Address Translation to a 4-KByte Page using 32-Bit Paging
   type Virtual_Address_Break is record
      PML2_Index : Page_Index;
      PML1_Index : Page_Index;
      Offset     : Virtual_Address_Offset;
   end record
      with Size => 32;

   -- !format off
   for Virtual_Address_Break use
     record
       PML2_Index at 0 range 22 .. 31;
       PML1_Index at 0 range 12 .. 21;
       Offset     at 0 range  0 .. 11;
     end record;
   -- !format on

   function To_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address, Target => Virtual_Address_Break);
   function From_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address_Break, Target => Virtual_Address);

   Null_Address_Break : constant Virtual_Address_Break := (PML2_Index => 0, PML1_Index => 0, Offset => 0);

   Last_Virtual_Address_Break : constant Virtual_Address_Break :=
     (PML2_Index => Page_Index'Last, PML1_Index => Page_Index'Last, Offset => 0);

   function Get_PML2_Index (Address : Virtual_Address_Break) return Page_Index is (Address.PML2_Index);
   function Get_PML1_Index (Address : Virtual_Address_Break) return Page_Index is (Address.PML1_Index);

   procedure Next (Address : in out Virtual_Address_Break);
   procedure Next (Address : in out Virtual_Address);


end x86.vmm.vab;