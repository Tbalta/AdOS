package x86.vmm.vab is
   pragma Preelaborate;


   type Virtual_Address_Break is record
      Offset     : Virtual_Address_Offset;
      PML1_Index : Page_Index;
      PML2_Index : Page_Index;
      PML3_Index : Page_Index;
      PML4_Index : Page_Index;
   end record
      with Size => 64;
   for Virtual_Address_Break use
     record
       Offset     at 0 range 0 .. 11;
       PML1_Index at 0 range 12 .. 20;
       PML2_Index at 0 range 21 .. 29;
       PML3_Index at 0 range 30 .. 38;
       PML4_Index at 0 range 39 .. 47;
     end record;

     type Virtual_Address_Break_2MB is record
         Offset : Storage_Offset range 0 .. 2 ** 21 - 1;
         PML2_Index : Page_Index;
         PML3_Index : Page_Index;
         PML4_Index : Page_Index;
      end record
         with Size => 64;
     for Virtual_Address_Break_2MB use record
         Offset at 0 range 0 .. 20;
         PML2_Index at 0 range 21 .. 29;
         PML3_Index at 0 range 30 .. 38;
         PML4_Index at 0 range 39 .. 47;
      end record;

     type Virtual_Address_Break_1GB is record
         Offset : Storage_Offset range 0 .. 2 ** 30 - 1;
         PML2_Index : Page_Index;
         PML3_Index : Page_Index;
         PML4_Index : Page_Index;
      end record
         with Size => 64;
     for Virtual_Address_Break_1GB use record
         Offset     at 0 range 0 .. 29;
         PML3_Index at 0 range 30 .. 38;
         PML4_Index at 0 range 39 .. 47;
      end record;

   function To_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address, Target => Virtual_Address_Break);
   function From_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address_Break, Target => Virtual_Address);

   function To_Virtual_Address_Break_2MB is new
     Ada.Unchecked_Conversion (Source => Virtual_Address, Target => Virtual_Address_Break_2MB);
   function From_Virtual_Address_Break_2MB is new
     Ada.Unchecked_Conversion (Source => Virtual_Address_Break_2MB, Target => Virtual_Address);

   function To_Virtual_Address_Break_1GB is new
     Ada.Unchecked_Conversion (Source => Virtual_Address, Target => Virtual_Address_Break_1GB);
   function From_Virtual_Address_Break_1GB is new
     Ada.Unchecked_Conversion (Source => Virtual_Address_Break_1GB, Target => Virtual_Address);
   
   Null_Address_Break : constant Virtual_Address_Break := 
     (PML4_Index => 0,
      PML3_Index => 0,
      PML2_Index => 0,
      PML1_Index => 0,
      Offset     => 0);

   function Get_PML4_Index (Address : Virtual_Address_Break) return Page_Index is (Address.PML4_Index);
   function Get_PML3_Index (Address : Virtual_Address_Break) return Page_Index is (Address.PML3_Index);
   function Get_PML2_Index (Address : Virtual_Address_Break) return Page_Index is (Address.PML2_Index);
   function Get_PML1_Index (Address : Virtual_Address_Break) return Page_Index is (Address.PML1_Index);

   procedure Next (Address : in out Virtual_Address_Break);



end x86.vmm.vab;