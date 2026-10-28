with System;

package body x86.Vmm.Structures is


   function Get_PML4 (CR3 : CR3_Register) return Page_Map_Level_4_Access is
   begin
      return To_PML4_Access (To_Address (CR3.Address));
   end Get_PML4;
   function Get_PML4 (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_4_Access is (To_PML4_Access (To_Address (CR3.Address)));

   -- PML3 --
   function Get_PML3 (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_3_Access is
      PML4 : Page_Map_Level_4_Access := Get_PML4 (CR3, Address);
   begin
      if PML4 = null or else
         not PML4 (Address.PML4_Index).Present or else
         PML4 (Address.PML4_Index).Page_Size
      then
         return null;
      end if;
      return To_PML3_Access (To_Address (PML4 (Address.PML4_Index).Address));
   end Get_PML3;

   -- PML2 --
   function Get_PML2 (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_2_Access is
      PML3 : Page_Map_Level_3_Access := Get_PML3 (CR3, Address);
   begin
      if PML3 = null or else
         not PML3 (Address.PML3_Index).Present or else
         PML3 (Address.PML3_Index).Page_Size
      then
         return null;
      end if;
   
      return To_PML2_Access (To_Address (PML3 (Address.PML3_Index).Address));
   end Get_PML2;


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

   function Get_PML_Entry (PML3_Entry : Page_Map_Level_3_Entry; PML_Index : Page_Index) return Page_Map_Level_2_Entry
   is
      PML2 : Page_Map_Level_2_Access := To_PML_Access (PML3_Entry);
   begin
      return PML2 (PML_Index);
   end Get_PML_Entry;
   function Get_PML_Entry (PML4_Entry : Page_Map_Level_4_Entry       ; PML_Index : Page_Index) return Page_Map_Level_3_Entry
   is
      PML3 : Page_Map_Level_3_Access := To_PML_Access (PML4_Entry);
   begin
      return PML3 (PML_Index);
   end Get_PML_Entry;
   function Get_PML_Entry (CR3 : CR3_Register                        ; PML_Index : Page_Index) return Page_Map_Level_4_Entry
   is
      PML4 : Page_Map_Level_4_Access := To_PML_Access (CR3);
   begin
      return PML4 (PML_Index);
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