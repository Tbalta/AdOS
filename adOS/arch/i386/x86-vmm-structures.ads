with System;

with x86.vmm.vab; use x86.vmm.vab;
package x86.Vmm.Structures is
   pragma Preelaborate;


  package PML2_Conversion is new System.Address_To_Access_Conversions (Page_Map_Level_2);
  package PML1_Conversion is new System.Address_To_Access_Conversions (Page_Map_Level_1);

  function To_PML2_Access (System_Address : Virtual_Address) return Page_Map_Level_2_Access is (Page_Map_Level_2_Access (PML2_Conversion.To_Pointer (System.Address (System_Address))));
  function To_PML1_Access (System_Address : Virtual_Address) return Page_Map_Level_1_Access is (Page_Map_Level_1_Access (PML1_Conversion.To_Pointer (System.Address (System_Address))));

  function To_PML2_Access (System_Address : Physical_Address) return Page_Map_Level_2_Access is (To_PML2_Access (To_Virtual_Address (System_Address)));
  function To_PML1_Access (System_Address : Physical_Address) return Page_Map_Level_1_Access is (To_PML1_Access (To_Virtual_Address (System_Address)));
  
  function To_PML_Access (CR3 : CR3_Register) return Page_Map_Level_2_Access is (To_PML2_Access (To_Address (CR3.Address)));
  function To_PML_Access (PML_Entry : Page_Map_Level_2_Entry) return Page_Map_Level_1_Access is (To_PML1_Access (To_Address (PML_Entry.Address)));


   function Get_PML2 (CR3 : CR3_Register) return Page_Map_Level_2_Access;
   function Get_PML2 (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_2_Access;
   function Get_PML1 (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_1_Access;


   function Get_PML_Entry (PML2_Entry : Page_Map_Level_2_Entry; PML_Index : Page_Index) return Page_Map_Level_1_Entry;
   function Get_PML_Entry (CR3 : CR3_Register;                  PML_Index : Page_Index) return Page_Map_Level_2_Entry;


    generic
      type Page_Map_Level_Entry is private;
      type Page_Map_Level_Entry_Access is access all Page_Map_Level_Entry;
      type Page_Map_Level is array (Page_Index) of aliased Page_Map_Level_Entry;
      type Page_Map_Level_Access is access all Page_Map_Level;
      with function Get_Entry_Index (Address : Virtual_Address_Break) return Page_Index;
      with function Get_PML (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_Access;
   function Get_PML_Entry_From_Addr_Break (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_Entry_Access; 
end x86.Vmm.Structures;