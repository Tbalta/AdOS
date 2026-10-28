with System;

package body x86.Vmm.Structures is


   function Get_PML2 (CR3 : CR3_Register) return Page_Map_Level_2_Access is
   begin
      return To_PML2_Access (To_Address (CR3.Address));
   end Get_PML2;
   function Get_PML2 (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_2_Access is (To_PML2_Access (To_Address (CR3.Address)));

   -- PML1 --
   function Get_PML1 (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_1_Access is
      PML2 : Page_Map_Level_2_Access := Get_PML2 (CR3, Address);
   begin
      if PML2 = null                   or else
         not PML2 (Address.PML2_Index).Present or else
         PML2 (Address.PML2_Index).Page_Size
      then
         return null;
      end if;
      return To_PML1_Access(To_Address (PML2 (Address.PML2_Index).Address));
   end Get_PML1;


   function Get_PML_Entry (PML2_Entry : Page_Map_Level_2_Entry; PML_Index : Page_Index) return Page_Map_Level_1_Entry
   is
      PML1 : Page_Map_Level_1_Access := To_PML_Access (PML2_Entry);
   begin
      return PML1 (PML_Index);
   end Get_PML_Entry;

   function Get_PML_Entry (CR3 : CR3_Register                        ; PML_Index : Page_Index) return Page_Map_Level_2_Entry
   is
      PML2 : Page_Map_Level_2_Access := To_PML_Access (CR3);
   begin
      return PML2 (PML_Index);
   end Get_PML_Entry;


   function Get_PML_Entry_From_Addr_Break (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_Entry_Access is
      PML : Page_Map_Level_Access := Get_PML (CR3, Address);
   begin
      if PML = null then
         return null;
      end if;
      return PML (Get_Entry_Index (Address))'Access;
   end Get_PML_Entry_From_Addr_Break;
end x86.Vmm.Structures;