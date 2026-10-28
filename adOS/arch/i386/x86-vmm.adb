with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Ada.Assertions;
with Loggers;
with x86.vmm;
with Util;
with vmm; use vmm;
with x86.vmm.Structures; use x86.vmm.Structures;
with x86.vmm.vab; use x86.vmm.vab;
package body x86.vmm is
   use Standard.ASCII;
   pragma Assertion_Policy (Assert => Check);

   function To_Hex is new Util.To_Hex (Virtual_Address);
   function To_Hex is new Util.To_Hex (Storage_Offset);

   package Logger renames Loggers;

   -------------------------
   -- Page Access Utility --
   -------------------------
   function Get_PML2_Entry is new Get_PML_Entry_From_Addr_Break (
      Page_Map_Level_Entry => Page_Map_Level_2_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_2_Entry_Access,
      Page_Map_Level => Page_Map_Level_2,
      Page_Map_Level_Access => Page_Map_Level_2_Access,
      Get_Entry_Index =>  Get_PML2_Index,
      Get_PML => Get_PML2);
   function Get_PML1_Entry is new Get_PML_Entry_From_Addr_Break (
      Page_Map_Level_Entry => Page_Map_Level_1_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_1_Entry_Access,
      Page_Map_Level => Page_Map_Level_1,
      Page_Map_Level_Access => Page_Map_Level_1_Access,
      Get_Entry_Index =>  Get_PML1_Index,
      Get_PML => Get_PML1);


   ------------------------
   -- Address Utility --
   ------------------------
   function To_Virtual_Address (address : Physical_Address) return Virtual_Address is
   begin
      -- Only valid because of identity mapping
      return Virtual_Address (address);
   end To_Virtual_Address;

   function To_Address (Addr : Page_Address) return Physical_Address is (Physical_Address (Integer_Address (Addr) * 4_096));

   function To_Page_Table_Address (Addr : System.Address) return Page_Table_Address is
      (Page_Table_Address (Integer_Address (Addr) / 4_096));

   function To_Page_Address (Addr : Physical_Address) return Page_Address is
      (Page_Address (Storage_Count (Integer_Address (Addr)) / PAGE_SIZE));

   function Virtual_To_Physical_Address
      (CR3 : CR3_register; Address : Virtual_Address) return Physical_Address
   is
      PD                : Page_Map_Level_2_Access := To_PML2_Access (To_Address (CR3.Address));
      PT                : Page_Map_Level_1_Access;
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
   begin
      if not PD (Address_Breakdown.PML2_Index).Present then
         return Physical_Address'First;
      end if;
      PT := Get_PML1 (CR3, Address_Breakdown);

      if not PT (Address_Breakdown.PML1_Index).Present then
         return Physical_Address'First;
      end if;

      return To_Address (PT (Address_Breakdown.PML1_Index).Address) + Address_Breakdown.Offset;
   end Virtual_To_Physical_Address;

   function Is_Last_Address (CR3 : CR3_Register; Address : Virtual_Address) return Boolean is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      PML2_Entry : Page_Map_Level_2_Entry_Access := Get_PML2_Entry (CR3, Address_Breakdown);
   begin
      if Address_Breakdown.PML2_Index /= Page_Index'Last then
         return False;
      end if;

      return Address_Breakdown.PML1_Index = Page_Index'Last;
   end Is_Last_Address;

   function Get_Offset (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Offset
   is
   begin
      return To_Virtual_Address_Break (Address).Offset;
   end Get_Offset;

   procedure Invalidate_TLB_Address (Address : Virtual_Address)
   is
      Canonical_Address : constant System.Address := To_Address (Address);
   begin
         Asm ("invlpg %0" & LF, Inputs => System.Address'Asm_Input ("m", Canonical_Address), Volatile => True);
   end Invalidate_TLB_Address;


   -----------------------
   -- Paging Operations --
   -----------------------
   function Is_Paging_Enabled return Boolean
   is
   begin
      return Paging_Enabled;
   end Is_Paging_Enabled;

   procedure Enable_Paging is
   begin
      if Paging_Enabled then
         Logger.Log_Warning ("Paging is already enabled!");
         return;
      end if;
      --!format off
      Asm
        ("movl %%cr0, %%eax"     & LF & HT &
         "or $0x80000001, %%eax" & LF & HT &
         "movl %%eax, %%cr0",
         Volatile => True);
      --!format off
      Paging_Enabled := True;
   end Enable_Paging;

   procedure Disable_Paging is
   begin
      if not Paging_Enabled then
         Logger.Log_Warning ("Paging is already disabled!");
         return;
      end if;
      --!format off
      Asm
        ("mov %%cr0, %%eax"       & LF & HT &
         "and $0x7FFFFFFF, %%eax" & LF & HT &
          "mov %%eax, %%cr0",
         Volatile => True);
      --!format on
      Paging_Enabled := False;
   end Disable_Paging;


   --------------------
   -- CR3 Operations --
   --------------------
   function Create_CR3 return CR3_register is
      CR3 : CR3_register;
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      --  Used to allocate Page Directory table
      CR3.Address := To_Page_Address (Allocate_Page);
      CR3.PCD := True; -- Todo: why?
      CR3.PWT := True; -- Todo: why?

      --  Init the Page Directory
      declare
         PD : Page_Map_Level_2_Access := Get_PML2 (CR3);
      begin
         PD.all := Page_Map_Level_2'(others => (Present => False, others => <>));
      end;

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;

      return CR3;
   end Create_CR3;

   procedure Load_CR3 (CR3 : CR3_register) is
   begin
      --!format off
      Asm
        ("movl %0, %%eax" & LF & "movl %%eax, %%cr3" & LF,
         Inputs   => CR3_register'Asm_Input ("a", CR3),
         Volatile => True);
      --!format on
   end Load_CR3;

   function Get_Current_CR3 return CR3_register is
      CR3 : CR3_register;
   begin
      --!format off
      Asm
        ("movl %%cr3, %%eax" & LF & "movl %%eax, %0" & LF,
         Outputs  => CR3_register'Asm_Output ("=a", CR3),
         Volatile => True);
      --!format on
      return CR3;
   end Get_Current_CR3;

   
   ------------------------
   -- Access Right Check --
   ------------------------
   function Is_Usermode (CR3 : CR3_Register; Address : Virtual_Address_Break) return Boolean is
      result : Boolean := True;
   begin
      result := result and then Get_PML2_Entry (CR3, Address).Is_Usermode;
      if Get_PML2_Entry (CR3, Address).Page_Size then
         return result;
      end if;

      result := result and then Get_PML1_Entry (CR3, Address).Is_Usermode;
      return result;
   end Is_Usermode;

   function Is_Writable (CR3 : CR3_Register; Address : Virtual_Address_Break) return Boolean is
      result : Boolean := True;
   begin
      result := result and then Get_PML2_Entry (CR3, Address).Is_Writable;
      if Get_PML2_Entry (CR3, Address).Page_Size then
         return result;
      end if;

      result := result and then Get_PML1_Entry (CR3, Address).Is_Writable;
      return result;
   end Is_Writable;


   -------------------
   -- Page counting --
   -------------------
   function Get_Number_Of_Pages (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
      is (Positive (Size + Storage_Count (4_095 + Offset)) / 4_096);
   function Get_Page_Number (Address : Virtual_Address_Break) return Page_Count is
   begin
      return 
         (Page_Count (Address.PML2_Index) * Page_Per_PML1) + 
          Page_Count (Address.PML1_Index);
   end Get_Page_Number;

   function Get_Free_Size (CR3 : CR3_Register; Address : Virtual_Address_Break) return Storage_Count is
      PML1_Entry : Page_Map_Level_1_Entry;
      PML2_Entry : Page_Map_Level_2_Entry;

      Current_PML1_Index : Page_Index := Address.PML1_Index;
      Current_PML2_Index : Page_Index := Address.PML2_Index;

      Address_Mapped : Boolean := False;

      function Get_PML1_Size (PML1_Index : Page_Index) return Storage_Count is
      begin
         PML1_Entry := Get_PML_Entry (PML2_Entry, PML1_Index);

         if PML1_Entry.Present then
            Address_Mapped := True;
            return 0;
         end if;
         return PAGE_SIZE;
      end Get_PML1_Size;

      function Get_PML2_Size (PML2_Index : Page_Index) return Storage_Count is
         Total_Size : Storage_Count := 0;
      begin
         PML2_Entry := Get_PML_Entry (CR3, PML2_Index);

         if not PML2_Entry.Present then
            return PAGE_SIZE_2MB;
         end if;

         for PML_Index in Current_PML1_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML1_Size (PML_Index);
            exit when Address_Mapped;
         end loop;

         Current_PML1_Index := 0;
         return Total_Size;
      end Get_PML2_Size;

      Total_Size : Storage_Count := 0;
   begin
      for PML_Index in Current_PML2_Index .. Page_Index'Last loop
         Total_Size := Total_Size + Get_PML2_Size (PML_Index);
         Current_PML1_Index := 0;
         exit when Address_Mapped;
      end loop;

      return Total_Size;
   end Get_Free_Size;
   function Get_Free_Size (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Count is (Get_Free_Size (CR3, To_Virtual_Address_Break (Address)));

   function Get_Allocated_Size (CR3 : CR3_Register; Address : Virtual_Address_Break) return Storage_Count is
      PML1_Entry : Page_Map_Level_1_Entry;
      PML2_Entry : Page_Map_Level_2_Entry;

      Current_PML1_Index : Page_Index := Address.PML1_Index;
      Current_PML2_Index : Page_Index := Address.PML2_Index;

      Address_Mapped : Boolean := True;

      function Get_PML1_Size (PML1_Index : Page_Index) return Storage_Count is
      begin
         PML1_Entry := Get_PML_Entry (PML2_Entry, PML1_Index);

         if not PML1_Entry.Present then
            Address_Mapped := False;
            return 0;
         end if;
         return PAGE_SIZE;
      end Get_PML1_Size;

      function Get_PML2_Size (PML2_Index : Page_Index) return Storage_Count is
         Total_Size : Storage_Count := 0;
      begin
         PML2_Entry := Get_PML_Entry (CR3, PML2_Index);

         if not PML2_Entry.Present then
            Address_Mapped := False;
            return 0;
         end if;

         for PML_Index in Current_PML1_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML1_Size (PML_Index);
            exit when not Address_Mapped;
         end loop;

         Current_PML1_Index := 0;
         return Total_Size;
      end Get_PML2_Size;

      Total_Size : Storage_Count := 0;
   begin
      for PML_Index in Current_PML2_Index .. Page_Index'Last loop
         Total_Size := Total_Size + Get_PML2_Size (PML_Index);
         Current_PML1_Index := 0;
         exit when not Address_Mapped;
      end loop;

      return Total_Size;
   end Get_Allocated_Size;
   function Get_Allocated_Size (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Count is (Get_Allocated_Size (CR3, To_Virtual_Address_Break (Address)));


   ---------------------
   -- Logging Utility --
   ---------------------
   procedure Print_Mapped_Memory (CR3 : CR3_Register) is 
      pragma Assert (CR3.Address /= 0);
      Current_Page : Page_Count := 0;
      Address_Breakdown : Virtual_Address_Break := Null_Address_Break;


      Current_Region_Start : Virtual_Address_Break := Null_Address_Break;

      function Get_Flag_String  return String is
         Result : String (1 .. 3);
         Writable : Boolean := Is_Writable (CR3, Current_Region_Start);
         Usermode : Boolean := Is_Usermode (CR3, Current_Region_Start);
      begin
         if Usermode then
            Result (1) := 'U';
         else
            Result (1) := '-';
         end if;
            
         Result (2) := 'R';
         if Writable then
            Result (3) := 'W';
         else
            Result (3) := '-';
         end if;

         return Result;
      end Get_Flag_String;

      function Is_Mapped (CR3 : CR3_Register; Address : Virtual_Address) return Boolean is
         Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      begin
         return Get_PML2_Entry (CR3, Address_Breakdown).Present and then
                (Get_PML2_Entry (CR3, Address_Breakdown).Page_Size or else Get_PML1_Entry (CR3, Address_Breakdown).Present);
      end Is_Mapped;

      procedure Print (Region_End_Address : Virtual_Address) is
         Region_Start_Address : constant Virtual_Address := From_Virtual_Address_Break (Current_Region_Start);
      begin
         Logger.Log_Info (To_Hex (Storage_Count (Region_Start_Address), 8)      & " " &
                          To_Hex (Storage_Count (Region_End_Address), 8)        & " " &
                          To_Hex (Virtual_Address (Region_End_Address - Region_Start_Address), 8) & " " &
                          Get_Flag_String );
      end Print;

      procedure Test (Test_Address : Virtual_Address_Break) is
      begin
         if not Is_Mapped (CR3, From_Virtual_Address_Break (Current_Region_Start)) then
            Current_Region_Start := Test_Address;
            return;
         end if;

         if not Is_Mapped (CR3, From_Virtual_Address_Break (Test_Address)) then
            Print (From_Virtual_Address_Break (Test_Address));
            Current_Region_Start := Test_Address;
            return;
         end if;

         if Get_Page_Number (Test_Address) = Page_Per_PML2 - 1                         or else
            Is_Usermode (CR3, Test_Address) /= Is_Usermode (CR3, Current_Region_Start) or else
            Is_Writable (CR3, Test_Address) /= Is_Writable (CR3, Current_Region_Start)
         then
            Print (From_Virtual_Address_Break (Test_Address));
            Current_Region_Start := Test_Address;
         end if;
      end Test;

   begin
      Logger.Log_Info ("Printing mapped memory for CR3: " & To_Hex (Storage_Count (CR3.Address)));
      while Current_Page < Page_Per_PML2 loop
         Address_Breakdown := To_Virtual_Address_Break (Virtual_Address (Storage_Count (Current_Page) * PAGE_SIZE));
         Test (Address_Breakdown);
         Current_Page := Current_Page + 1;
      end loop;
      Logger.Log_Info ("--");
   end Print_Mapped_Memory;

   function Get_Entry_Level (CR3 : CR3_register; Address : Virtual_Address_Break) return Entry_Level is
   begin
      if not Get_PML2_Entry (CR3, Address).Present or else 
             Get_PML2_Entry (CR3, Address).Page_Size then
         return Entry_Level_2;
      end if;

      return Entry_Level_1;
   end Get_Entry_Level;


   -----------------------
   -- Create_PML2_Entry --
   -----------------------
   procedure Create_PML2_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML2 : Page_Map_Level_2_Access := Get_PML2 (CR3, Destination);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      pragma Assert (PML2 /= null);
      pragma Assert (not PML2 (Destination.PML2_Index).Present);
      pragma Assert (not Is_Paging_Enabled);

      --  Init the Page Map Level 1
      declare
         PML1 : Page_Map_Level_1_Access := To_PML1_Access (Page_To_Allocate);
      begin
         for I in PML1'Range loop
            PML1 (I) := (Present => False, others => <>);
         end loop;
      end;

      PML2 (Destination.PML2_Index).Present := True;
      PML2 (Destination.PML2_Index).Is_Writable := False;
      PML2 (Destination.PML2_Index).Is_Usermode := False;
      PML2 (Destination.PML2_Index).Write_Through := False;
      PML2 (Destination.PML2_Index).Cache_Disable := False;
      PML2 (Destination.PML2_Index).Accessed := False;
      PML2 (Destination.PML2_Index).Page_Size := False;
      PML2 (Destination.PML2_Index).Global := False;
      PML2 (Destination.PML2_Index).Address := To_Page_Address (Page_To_Allocate);
   end Create_PML2_Entry;

   procedure Create_PML1_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML1 : Page_Map_Level_1_Access := Get_PML1 (CR3, Destination);
   begin
      pragma Assert (PML1 /= null);
      pragma Assert (not PML1 (Destination.PML1_Index).Present);
      PML1 (Destination.PML1_Index).Present := False;
      PML1 (Destination.PML1_Index).Is_Writable := False;
      PML1 (Destination.PML1_Index).Is_Usermode := False;
      PML1 (Destination.PML1_Index).Write_Through := False;
      PML1 (Destination.PML1_Index).Cache_Disable := False;
      PML1 (Destination.PML1_Index).Accessed := False;
      PML1 (Destination.PML1_Index).Page_Size := False;
      PML1 (Destination.PML1_Index).Global := False;
      PML1 (Destination.PML1_Index).Address := To_Page_Address (Physical_Address (0));
   end Create_PML1_Entry;

   procedure Create_Page_Entries
     (CR3 : CR3_Register;
      Destination : Virtual_Address)
   is
      Address_Break : Virtual_Address_Break := To_Virtual_Address_Break (Destination);
   begin
      if not Get_PML2_Entry (CR3, Address_Break).Present then
         Create_PML2_Entry (CR3, Address_Break);
      end if;
      pragma Assert (not Get_PML2_Entry (CR3, Address_Break).Page_Size);

      if not Get_PML1_Entry (CR3, Address_Break).Present then
         Create_PML1_Entry (CR3, Address_Break);
      else
         Logger.Log_Error ("Entry already exist in CR3: " & CR3'Image);
      end if;
      Invalidate_TLB_Address (Destination);
   end Create_Page_Entries;

   procedure Set_Entry_Flags
     (CR3         : CR3_Register;
      Destination : Virtual_Address;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False)
   is
      Address_Break : Virtual_Address_Break := To_Virtual_Address_Break (Destination);

      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Address_Break);
      PML2_Entry : Page_Map_Level_2_Entry_Access := Get_PML2_Entry (CR3, Address_Break);

      Page_Level : constant Entry_Level := Get_Entry_Level (CR3, Address_Break);
   begin

      if Page_Level <= Entry_Level_2 then
         --  Directory permissions must allow any access granted by a leaf.
         PML2_Entry.Is_Writable := Is_Writable or PML2_Entry.Is_Writable;
         PML2_Entry.Is_Usermode := Is_Usermode or PML2_Entry.Is_Usermode;
      end if;

      PML1_Entry.Is_Writable := Is_Writable;
      PML1_Entry.Is_Usermode := Is_Usermode;

      pragma Assert (x86.vmm.Is_Usermode (CR3, Address_Break) = Is_Usermode);
      pragma Assert (x86.vmm.Is_Writable (CR3, Address_Break) = Is_Writable);
      Invalidate_TLB_Address (Destination);
   end Set_Entry_Flags;


   procedure Set_Entry_Address
     (CR3            : CR3_Register;
      Destination    : Virtual_Address;
      Address_To_Map : Physical_Address)
   is
      Address_Break : Virtual_Address_Break := To_Virtual_Address_Break (Destination);

      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Address_Break);
      pragma Assert (not PML1_Entry.Present);
   begin
      PML1_Entry.Present := True;
      PML1_Entry.Address := To_Page_Address (Address_To_Map);
      Invalidate_TLB_Address (Destination);
   end Set_Entry_Address;


   procedure Unmap_Page
     (CR3                 : CR3_Register;
      Address             : Virtual_Address;
      Free_Page           : Boolean)
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);

      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Address_Breakdown);
   begin
      if not PML1_Entry.Present then
         return;
      end if;

      if Free_Page then
         PMM.Free_Page (To_Address (PML1_Entry.Address));
      end if;
      PML1_Entry.Present := False;
   end Unmap_Page;


   -- Todo: move this outside x86-vmm.adb
   procedure Identity_Map (CR3 : CR3_register) is
      PD                  : Page_Map_Level_2_Access := Get_PML2 (CR3);
      Address_Breakdown   : Virtual_Address := (Virtual_Address (Null_Address));
      PMM_Start_Breakdown : Virtual_Address := (To_Virtual_Address (PMM.Get_Pmm_Start_Address));
      Kernel_Start_Break  : Virtual_Address := (To_Virtual_Address (Kernel_Start));
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      -- Identity map the kernel
      Logger.Log_Info ("Identity map kernel " & Kernel_Start'Image & "-" & Kernel_End'Image);
      Standard.vmm.Map_Range
        (CR3,
         Address_Breakdown,
         Physical_Address (Null_Address),
         Kernel_Start,
         Is_Writable => False,
         Is_Usermode => False);
      Standard.vmm.Map_Range
        (CR3,
         Kernel_Start_Break,
         Kernel_Start,
         Kernel_End,
         Is_Writable => True,
         Is_Usermode => False);
      Standard.vmm.Map_Range
        (CR3,
         PMM_Start_Breakdown,
         PMM.Get_Pmm_Start_Address,
         PMM.Get_Pmm_End_Address,
         Is_Writable => False,
         Is_Usermode => False);

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Identity_Map;

end x86.vmm;
