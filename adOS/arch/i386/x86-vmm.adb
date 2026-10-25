with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Ada.Assertions;
--  with System.Secondary_Stack;
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


   function To_Virtual_Address (address : Physical_Address) return Virtual_Address is
   begin
      -- Only valid because of identity mapping
      return Virtual_Address (address);
   end To_Virtual_Address;

   ----------------
   -- To_Address --
   ----------------
   function To_Address (Addr : Page_Address) return Physical_Address is (Physical_Address (Integer_Address (Addr) * 4_096));

   -------------------------
   -- Get_Number_Of_Pages --
   -------------------------
   function Get_Number_Of_Pages (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
   is (Positive (Size + Storage_Count (4_095 + Offset)) / 4_096);

   -------------------------------
   -- Get_Number_Of_Page_Tables --
   -------------------------------
   function Get_Number_Of_Page_Tables (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
   is  ((Get_Number_Of_Pages (Size, Offset) + Positive (Page_Map_Level_1'Length) - 1) / Page_Map_Level_1'Length);

   ---------------------------
   -- To_Page_Table_Address --
   ---------------------------
   function To_Page_Table_Address (Addr : System.Address) return Page_Table_Address is
    (Page_Table_Address (Integer_Address (Addr) / 4_096));

   -------------------------------
   -- To_Page_Directory_Address --
   -------------------------------
   function To_Page_Directory_Address (Addr : System.Address) return Page_Directory_Address is
   (Page_Directory_Address (Integer_Address (Addr) / 4_096));

   ---------------------
   -- To_Page_Address --
   ---------------------
   function To_Page_Address (Addr : Physical_Address) return Page_Address is
    (Page_Address (Storage_Count (Integer_Address (Addr)) / PAGE_SIZE));

   
   function Is_Paging_Enabled return Boolean
   is
   begin
      return Paging_Enabled;
   end Is_Paging_Enabled;

   --------------------
   -- Get_PML1 --
   --  --------------------
   --  function Get_PML1
   --    (CR3 : CR3_Register; Index : Page_Index) return Page_Map_Level_1_Access is (To_Page_Table_Access (Get_PML2 (CR3) (Index).Address));

   -------------------
   -- Enable_Paging --
   -------------------
   procedure Enable_Paging is
   begin
      if Paging_Enabled then
         Logger.Log_Warning ("Paging is already enabled!");
         return;
      end if;
      --  Logger.Log_Info ("Enabling paging");
      --!format off
      Asm
        ("movl %%cr0, %%eax"     & LF & HT &
         "or $0x80000001, %%eax" & LF & HT &
         "movl %%eax, %%cr0",
         Volatile => True);
      --!format off
      Paging_Enabled := True;
   end Enable_Paging;

   --------------------
   -- Disable_Paging --
   --------------------
   procedure Disable_Paging is
   begin
      if not Paging_Enabled then
         Logger.Log_Warning ("Paging is already disabled!");
         return;
      end if;
      --  Logger.Log_Info ("Disabling paging");
      --!format off
      Asm
        ("mov %%cr0, %%eax"       & LF & HT &
         "and $0x7FFFFFFF, %%eax" & LF & HT &
          "mov %%eax, %%cr0",
         Volatile => True);
      --!format on
      Paging_Enabled := False;
   end Disable_Paging;

   ----------------
   -- Create_CR3 --
   ----------------
   function Create_CR3 return CR3_register is
      CR3 : CR3_register;
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      --  Used to allocate Page Directory table
      CR3.Address := To_Page_Address (Allocate_Page);
      CR3.PCD := True;
      CR3.PWT := True;

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

   --------------
   -- Load_CR3 --
   --------------
   procedure Load_CR3 (CR3 : CR3_register) is
   begin
      --!format off
      Asm
        ("movl %0, %%eax" & LF & "movl %%eax, %%cr3" & LF,
         Inputs   => CR3_register'Asm_Input ("a", CR3),
         Volatile => True);
      --!format on
   end Load_CR3;

   ---------------------
   -- Get_Current_CR3 --
   ---------------------
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

   ---------------------------
   -- Enable_Kernel_Mapping --
   ---------------------------
   --  procedure Enable_Kernel_Mapping is
   --  begin
   --     Disable_Paging;
   --     Load_CR3 (Kernel_CR3);
   --     Enable_Paging;
   --  end Enable_Kernel_Mapping;

   --  --------------------
   --  -- Get_Kernel_CR3 --
   --  --------------------
   --  function Get_Kernel_CR3 return CR3_register is
   --  begin
   --     return Kernel_CR3;
   --  end Get_Kernel_CR3;
   
   --  function Get_Process_CR3 return CR3_register is
   --  begin
   --     return Process_CR3;
   --  end Get_Process_CR3;

   --------------------
   -- Set_Kernel_CR3 --
   --------------------
   --  procedure Set_Kernel_CR3 (CR3 : CR3_register) is
   --  begin
   --     Kernel_CR3 := CR3;
   --  end Set_Kernel_CR3;

   --  procedure Set_Process_CR3 (CR3 : CR3_register) is
   --  begin
   --     Process_CR3 := CR3;
   --  end Set_Process_CR3;

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

      function Get_Page_Number (Address : Virtual_Address_Break) return Page_Count is
   begin
      return 
         (Page_Count (Address.PML2_Index) * Page_Per_PML1) + 
          Page_Count (Address.PML1_Index);
   end Get_Page_Number;

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

   -----------------------
   -- Create_Page_Table --
   -----------------------
   procedure Create_Page_Table
     (PD          : Page_Map_Level_2_Access;
      PD_Index    : Page_Index;
      PT          : out Page_Map_Level_1_Access;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) is

      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      pragma Assert (not Is_Paging_Enabled);
      Logger.Log_Info ("Create_Page_Table: Is_Writable" & Is_Writable'Image & " / Is_Usermode: " & Is_Usermode'Image);
      PD.all (PD_Index).Present := True;
      PD.all (PD_Index).Is_Writable := True;
      PD.all (PD_Index).Is_Usermode := True;
      PD.all (PD_Index).Write_Through := False;
      PD.all (PD_Index).Cache_Disable := False;
      PD.all (PD_Index).Accessed := False;
      PD.all (PD_Index).Page_Size := False;
      PD.all (PD_Index).Global := False;
      PD.all (PD_Index).Address := To_Page_Address (Page_To_Allocate);

      pragma Assert (Page_To_Allocate = To_Address (PD (PD_Index).Address));
      -- Logger.Log_Info ("PT:" & PD.all (PD_Index)'Image);
      PT := To_PML1_Access (To_Address (PD (PD_Index).Address));

      for Index in PT.all'Range loop
         PT (Index) := (Present => False, others => <>);
      end loop;
      -- PT.all := (others => (Present => False, others => <>));
   end Create_Page_Table;

   procedure Create_Page_Table
     (PD          : Page_Map_Level_2_Access;
      PD_Index    : Page_Index;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False)
   is
      PT : Page_Map_Level_1_Access;
   begin
      Create_Page_Table (PD, PD_Index, PT, Is_Writable => Is_Writable, Is_Usermode => Is_Usermode);
   end Create_Page_Table;

   --------------------------
   -- Map_Page_Table_Entry --
   --------------------------
   procedure Map_Page_Table_Entry
     (Page_Table       : Page_Map_Level_1_Access;
      Page_Table_Start : Page_Index;
      Address          : Page_Address;
      Is_Writable      : Boolean := False;
      Is_Usermode      : Boolean := False) is
   begin
      Page_Table.all (Page_Table_Start).Present := True;
      Page_Table.all (Page_Table_Start).Is_Writable := Is_Writable;
      Page_Table.all (Page_Table_Start).Is_Usermode := Is_Usermode;
      Page_Table.all (Page_Table_Start).Write_Through := False;
      Page_Table.all (Page_Table_Start).Cache_Disable := False;
      Page_Table.all (Page_Table_Start).Accessed := False;
      Page_Table.all (Page_Table_Start).Page_Size := False;
      Page_Table.all (Page_Table_Start).Global := False;
      Page_Table.all (Page_Table_Start).Address := Address;
   end Map_Page_Table_Entry;

   ----------
   -- Next --
   ----------
   procedure Next
     (Page_Directory_Start : in out Page_Index;
      Page_Table_Start     : in out Page_Index) is
   begin
      if Page_Table_Start = Page_Map_Level_1'Last then
         Page_Table_Start := 0;
         Page_Directory_Start := Page_Directory_Start + 1;
      else
         Page_Table_Start := Page_Table_Start + 1;
      end if;
   end Next;

   -----------------------
   -- Map_Physical_Page --
   -----------------------
   procedure Map_Physical_Page
     (
      Process              : CR3_Register;
      Destination          : Virtual_Address;
      Address_To_Map       : Physical_Address;
      Is_Writable          : Boolean := False;
      Is_Usermode          : Boolean := False)
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Destination);
      Page_Map_Level_2 : Page_Map_Level_2_Access := Get_PML2 (Process);

      Page_Directory_Start : Page_Index := Address_Breakdown.PML2_Index;
      Page_Table_Start : Page_Index := Address_Breakdown.PML1_Index;

      PD_Index : Page_Index := Page_Directory_Start;
      PT_Index : Page_Index := Page_Table_Start;
   begin
      if not Page_Map_Level_2.all (PD_Index).Present then
         Create_Page_Table
           (Page_Map_Level_2, PD_Index, Is_Writable => Is_Writable, Is_Usermode => Is_Usermode);
      end if;
      --  Logger.Log_Info
      --    ("Mapping physical page "
      --     & Address_To_Map'Image
      --     & " at PD index "
      --     & PD_Index'Image
      --     & " PT index "
      --     & PT_Index'Image);
      Map_Page_Table_Entry
        (To_PML_Access (Page_Map_Level_2.all (PD_Index)),
         PT_Index,
         To_Page_Address (Address_To_Map),
         Is_Writable => Is_Writable,
         Is_Usermode => Is_Usermode);

   end Map_Physical_Page;

   ----------------
   -- Unmap_Page --
   ----------------
   procedure Unmap_Page
     (CR3                 : CR3_Register;
      Address             : Virtual_Address;
      Free_Page           : Boolean)
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);

      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Address_Breakdown);


      PD_Index : Page_Index := Address_Breakdown.PML2_Index;
      PT_Index : Page_Index := Address_Breakdown.PML1_Index;
   begin
      if not PML1_Entry.Present then
         return;
      end if;

      if Free_Page then
         PMM.Free_Page (To_Address (PML1_Entry.Address));
      end if;
      PML1_Entry.Present := False;
   end Unmap_Page;

   ---------------------------------
   -- Virtual_To_Physical_Address --
   ---------------------------------
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

   ---------------
   -- Map_Range --
   ---------------
   procedure Map_Range
     (Page_Map_Level_2             : Page_Map_Level_2_Access;
      Page_Directory_Start       : Page_Index;
      Page_Table_Start           : Page_Index;
      Start_Address, End_Address : Physical_Address;
      Is_Writable                : Boolean := False;
      Is_Usermode                : Boolean := False)
   is
      Page_Count : Positive := Get_Number_Of_Pages (End_Address - Start_Address);

      PD_Index       : Page_Index := Page_Directory_Start;
      PT_Index       : Page_Index := Page_Table_Start;
      Address_To_Map : Physical_Address := Start_Address;
   begin
      Logger.Log_Info ("Mapping range " & Start_Address'Image & " - " & End_Address'Image);
      Logger.Log_Info ("Number of pages to map: " & Natural'Image (Page_Count));
      for i in 1 .. Page_Count loop
         if not Page_Map_Level_2.all (PD_Index).Present then
            Create_Page_Table
              (Page_Map_Level_2, PD_Index, Is_Writable => Is_Writable, Is_Usermode => Is_Usermode);
         end if;

         Map_Page_Table_Entry
           (To_PML_Access (Page_Map_Level_2.all (PD_Index)),
            PT_Index,
            To_Page_Address (Address_To_Map),
            Is_Writable => Is_Writable,
            Is_Usermode => Is_Usermode);
         Next (PD_Index, PT_Index);
         Address_To_Map := Address_To_Map + Storage_Offset (4_096);
      end loop;

   end Map_Range;

   ------------------
   -- Identity_Map --
   ------------------
   procedure Identity_Map (CR3 : CR3_register) is
      PD                  : Page_Map_Level_2_Access := Get_PML2 (CR3);
      Address_Breakdown   : Virtual_Address_Break := To_Virtual_Address_Break (Virtual_Address (Null_Address));
      PMM_Start_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (To_Virtual_Address (PMM.Get_Pmm_Start_Address));
      Kernel_Start_Break  : Virtual_Address_Break := To_Virtual_Address_Break (To_Virtual_Address (Kernel_Start));
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      -- Identity map the kernel
      Logger.Log_Info ("Identity map kernel " & Kernel_Start'Image & "-" & Kernel_End'Image);
      Map_Range
        (PD,
         Address_Breakdown.PML2_Index,
         Address_Breakdown.PML1_Index,
         Physical_Address (Null_Address),
         Kernel_Start,
         Is_Writable => False,
         Is_Usermode => False);
      Map_Range
        (PD,
         Kernel_Start_Break.PML2_Index,
         Kernel_Start_Break.PML1_Index,
         Kernel_Start,
         Kernel_End,
         Is_Writable => True,
         Is_Usermode => False);
      Map_Range
        (PD,
         PMM_Start_Breakdown.PML2_Index,
         PMM_Start_Breakdown.PML1_Index,
         PMM.Get_Pmm_Start_Address,
         PMM.Get_Pmm_End_Address,
         Is_Writable => False,
         Is_Usermode => False);

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Identity_Map;

   -----------
   -- Alloc --
   -----------
   function Alloc
     (CR3         : CR3_register;
      Address     : Virtual_Address;
      Data_Size   : Storage_count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Boolean
   is
      PD                : Page_Map_Level_2_Access := Get_PML2 (CR3);
      PT                : Page_Map_Level_1_Access;
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      To_Fit : Storage_Count := Data_Size;
   begin
      if not Can_Fit (CR3, Address, Data_Size) then
         Logger.Log_Error ("Cannot fit " & Data_Size'Image & " at " & Address'Image);
         return False;
      end if;

      while To_Fit > 0 loop
         --  Logger.Log_Info ("At: " & Address_Breakdown'Image);
         if not PD.all (Address_Breakdown.PML2_Index).Present then
            Logger.Log_Info ("PTE entry not present");
            Create_Page_Table
              (PD,
               Address_Breakdown.PML2_Index,
               Is_Writable => Is_Writable,
               Is_Usermode => Is_Usermode);
         end if;

         PT := Get_PML1 (CR3, Address_Breakdown);
         -- Logger.Log_Info ("PT: " & PT.all'Image);
         Map_Page_Table_Entry
           (PT,
            Address_Breakdown.PML1_Index,
            To_Page_Address (Allocate_Page),
            Is_Writable => Is_Writable,
            Is_Usermode => Is_Usermode);

         To_Fit := To_Fit - Storage_Count'Min (To_Fit, PMM_PAGE_SIZE);
         --  Map the data
         Address_Breakdown.Offset := 0;
         Next (Address_Breakdown.PML2_Index, Address_Breakdown.PML1_Index);
      end loop;

      return True;
   end Alloc;


   --  ---------------------
   --  -- Is_Range_Mapped --
   --  ---------------------
   --  function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   --  is
   --     PD  : Page_Map_Level_2_Access := Get_PML2 (CR3);
   --     Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);

   --     First_Page_Table : constant Page_Index := Address_Breakdown.PML2_Index;
   --     Last_Page_Table :  constant Page_Index := Page_Index (Get_Number_Of_Page_Tables (Size, Address_Breakdown.Offset) - 1);

   --     Number_Of_Pages : Natural := Get_Number_Of_Pages (Size, Address_Breakdown.Offset);
   --     First_Page : Page_Index := Address_Breakdown.PML1_Index;
   --     Last_Page  : Page_Index := Page_Index (Positive'Min (Number_Of_Pages - 1, Positive (Page_Index'Last)));
   --  begin
   --     if (for some Page_Map_Level_1_Entry of PD (First_Page_Table .. Last_Page_Table) => not Page_Map_Level_1_Entry.Present) then
   --        Logger.Log_Error ("One Page_Map_Level_2 not present" & First_Page_Table'Image & ".." & Last_Page_Table'Image);
   --        return False;
   --     end if;

   --     for Index in First_Page_Table .. Last_Page_Table loop
   --        if (for some Page of Get_PML1 (CR3, Index).all (First_Page .. Last_Page) => not Page.Present) then
   --           Logger.Log_Error ("Not mapped " & Index'Image);
   --           return False;
   --        end if;

   --        Last_Page  := Page_Index (Natural'Min (Number_Of_Pages - 1, Natural (Page_Index'Last)));
   --        Number_Of_Pages := Number_Of_Pages - Natural'Min (Number_Of_Pages, Page_Table'Length);
   --        First_Page := 0;
   --     end loop;

   --     return True;
   --  end Is_Range_Mapped;

   --  ------------------
   --  -- Kernel_Alloc --
   --  ------------------
   --  function Kernel_Alloc
   --    (CR3         : CR3_register;
   --     Size        : Storage_Count;
   --     Is_Writable : Boolean := False;
   --     Is_Usermode : Boolean := False) return Virtual_Address
   --  is
   --     Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Virtual_Address'First);
   --     Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   --     Success : Boolean := True;
   --  begin
   --     if Paging_Currently_Enabled then
   --        Disable_Paging;
   --     end if;
   --     Address_Breakdown := Find_Next_Space (CR3, Size, Virtual_Address'First);
   --     if Address_Breakdown = To_Virtual_Address_Break (Virtual_Address'First) then
   --        Logger.Log_Error ("No more free space in the Page Directory");
   --        Success := False;
   --     end if;

   --     Logger.Log_Info
   --       ("Kernel_Alloc: Allocating "
   --        & Size'Image
   --        & " bytes at "
   --        & From_Virtual_Address_Break (Address_Breakdown)'Image);

   --     if Success and then not Alloc
   --              (CR3,
   --               From_Virtual_Address_Break (Address_Breakdown),
   --               Size,
   --               Is_Writable => Is_Writable,
   --               Is_Usermode => Is_Usermode)
   --     then
   --        Success := False;
   --     end if;

   --     if Paging_Currently_Enabled then
   --        Enable_Paging;
   --     end if;

   --     if Success then
   --        return From_Virtual_Address_Break (Address_Breakdown);
   --     end if; 

   --     return Virtual_Address'First;
   --  end Kernel_Alloc;

   ----------------------------
   -- Process_To_Process_Map --
   ----------------------------
   --  function Process_To_Process_Map
   --    (Source_CR3     : CR3_register;
   --     Source_Address : Virtual_Address;
   --     Dest_CR3       : CR3_register;
   --     Size           : Storage_Count;
   --     Hint           : Virtual_Address := Virtual_Address'First) return Virtual_Address
   --  is
   --     Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   --     Offset_In_Page        : constant Virtual_Address_Offset := To_Virtual_Address_Break (Source_Address).Offset;
   --     Page_Count              : constant Positive := Get_Number_Of_Pages (Size + Storage_Count (Offset_In_Page));

   --     Return_Address        : Virtual_Address;
   --     Dest_Address          : Virtual_Address_Break;

   --     --------------------------
   --     -- Compute_Dest_Address --
   --     --------------------------
   --     function Compute_Dest_Address return Virtual_Address_Break is
   --        begin
   --        if Hint /= Virtual_Address'First then
   --           return  To_Virtual_Address_Break (Hint);
   --        else
   --          return Find_Next_Space (Dest_CR3, Size + Storage_Count (Offset_In_Page), Virtual_Address'First);
   --        end if;
   --     end Compute_Dest_Address;

   --     ------------------------------
   --     -- Disable_Paging_If_Needed --
   --     ------------------------------
   --     procedure Disable_Paging_If_Needed is
   --     begin
   --        if Paging_Currently_Enabled then
   --           Disable_Paging;
   --        end if;
   --     end Disable_Paging_If_Needed;

   --     ------------------------------
   --     -- Re_Enable_Paging_If_Needed --
   --     ------------------------------
   --     procedure Re_Enable_Paging_If_Needed is
   --     begin
   --        if Paging_Currently_Enabled then
   --           Enable_Paging;
   --        end if;
   --     end Re_Enable_Paging_If_Needed;


   --  begin
   --     Disable_Paging_If_Needed;

   --     if not Is_Range_Mapped (Source_CR3, Source_Address, Size) then
   --        Logger.Log_Error ("Address is not mapped");
   --        Re_Enable_Paging_If_Needed;
   --        return Virtual_Address'First;
   --     end if;

   --     Dest_Address := Compute_Dest_Address;
   --     if Dest_Address = Null_Address_Break or else not Can_Fit (Dest_CR3, From_Virtual_Address_Break (Dest_Address), Size) then
   --        Logger.Log_Error ("Map_Process_Memory: Could not find space in destination process");
   --        Re_Enable_Paging_If_Needed;
   --        return Virtual_Address'First;
   --     end if;
      
   --     Return_Address := From_Virtual_Address_Break (Dest_Address) + Offset_In_Page;

   --     for i in 0 .. Page_Count - 1 loop
   --        Map_Physical_Page (
   --           Page_Map_Level_2 => Get_PML2 (Dest_CR3),
   --           Page_Directory_Start => Dest_Address.Directory,
   --           Page_Table_Start => Dest_Address.Table,
   --           Address_To_Map => Virtual_To_Physical_Address (Source_CR3, Source_Address + Storage_Count (i * Positive (PMM_PAGE_SIZE))),
   --           Is_Writable => True,
   --           Is_Usermode => True);
   --        Next (Dest_Address.Directory, Dest_Address.Table);
   --     end loop;

   --     Re_Enable_Paging_If_Needed;
   --     return Return_Address;
   --  end Process_To_Process_Map;

   ------------------
   -- Memory_Unmap --
   ------------------
   --  procedure Memory_Unmap
   --    (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count; Free_Page : Boolean)
   --  is
   --     Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   --     PD                       : constant Page_Map_Level_2_Access := Get_PML2 (CR3);
   
   --     Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
   --     Page_Count               : constant Natural := Get_Number_Of_Pages (size, Address_Breakdown.Offset);
   
   --  begin
   --     if Paging_Currently_Enabled then
   --        Disable_Paging;
   --     end if;

   --     for i in 1 .. Page_Count loop
   --        Unmap_Page (PD, Address_Breakdown.PML2_Index, Address_Breakdown.PML1_Index, Free_Page);
   --        Next (Address_Breakdown.PML2_Index, Address_Breakdown.PML1_Index);
   --     end loop;
   
   --     if Paging_Currently_Enabled then
   --        Enable_Paging;
   --     end if;
   --  end Memory_Unmap;


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

end x86.vmm;
