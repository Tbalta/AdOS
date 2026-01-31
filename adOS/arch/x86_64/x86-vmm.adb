with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Ada.Assertions;
--  with System.Secondary_Stack;
with Loggers;
with x86.vmm;
with Util;

package body x86.vmm is
   use Standard.ASCII;
   pragma Assertion_Policy (Assert => Check);
   package Logger renames Loggers;

   ----------------
   -- To_Address --
   ----------------
   function To_Address (Addr : Page_Address) return System.Address is (System.Address (Integer_Address (Addr) * 4_096));

   -------------------------
   -- Get_Number_Of_Pages --
   -------------------------
   function Get_Number_Of_Pages (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
   is (Positive (Size + Storage_Count (4_095 + Offset)) / 4_096);

   -------------------------------
   -- Get_Number_Of_Page_Tables --
   -------------------------------
   function Get_Number_Of_Page_Tables (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
   is  ((Get_Number_Of_Pages (Size, Offset) + Positive (Page_Table'Length) - 1) / Page_Table'Length);

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
   function To_Page_Address (Addr : System.Address) return Page_Address is
    (Page_Address (Integer_Address (Addr) / 4_096));

   ------------------------
   -- Get_Page_Directory --
   ------------------------
   function Get_Page_Directory (CR3 : CR3_Register) return Page_Directory_Access is (To_Page_Directory (To_Address (CR3.Address)));
   
   function Is_Paging_Enabled return Boolean
   is
   begin
      return Paging_Enabled;
   end Is_Paging_Enabled;

   --------------------
   -- Get_Page_Table --
   --------------------
   function Get_Page_Table
     (CR3 : CR3_Register; Index : Page_Directory_Index) return Page_Table_Access is (To_Page_Table_Access (Get_Page_Directory (CR3) (Index).Address));

   -------------------
   -- Enable_Paging --
   -------------------
   procedure Enable_Paging is
   begin
      if Paging_Enabled then
         Logger.Log_Warning ("Paging is already enabled!");
         return;
      end if;
      Logger.Log_Error ("Not implemented: Enabling paging");
      --!format off

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
      Logger.Log_Error ("Not implemented: Disabling paging");
      --!format off
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
         PD : Page_Directory_Access := Get_Page_Directory (CR3);
      begin
         PD.all := Page_Directory'(others => (Present => False, others => <>));
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
        ("movq %0, %%rax" & LF & "movq %%rax, %%cr3" & LF,
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
        ("movq %%cr3, %%rax" & LF & "movq %%rax, %0" & LF,
         Outputs  => CR3_register'Asm_Output ("=a", CR3),
         Volatile => True);
      --!format on

      return CR3;
   end Get_Current_CR3;

   ---------------------------
   -- Enable_Kernel_Mapping --
   ---------------------------
   procedure Enable_Kernel_Mapping is
   begin
      Disable_Paging;
      Load_CR3 (Kernel_CR3);
      Enable_Paging;
   end Enable_Kernel_Mapping;

   --------------------
   -- Get_Kernel_CR3 --
   --------------------
   function Get_Kernel_CR3 return CR3_register is
   begin
      return Kernel_CR3;
   end Get_Kernel_CR3;
   
   function Get_Process_CR3 return CR3_register is
   begin
      return Process_CR3;
   end Get_Process_CR3;

   --------------------
   -- Set_Kernel_CR3 --
   --------------------
   procedure Set_Kernel_CR3 (CR3 : CR3_register) is
   begin
      Kernel_CR3 := CR3;
   end Set_Kernel_CR3;

   procedure Set_Process_CR3 (CR3 : CR3_register) is
   begin
      Process_CR3 := CR3;
   end Set_Process_CR3;

   procedure Print_Mapped_Memory (CR3 : CR3_Register) is
      Current_Region_Start : Virtual_Address_Break := Null_Address_Break;
      Current_Region : Virtual_Address_Break := Null_Address_Break;

      PD : Page_Directory_Access := Get_Page_Directory (CR3);
      PT : Page_Table_Access := null;
      Region_Valid : Boolean := false;

      function Get_Region_Size return Storage_Count is
      begin
         return From_Virtual_Address_Break (Current_Region) - From_Virtual_Address_Break (Current_Region_Start);
      end Get_Region_Size;

      function Get_Flag_String return String is
         Result : String (1 .. 3);
         Is_Writable : Boolean := PT (Current_Region_Start.Table).Is_Writable;
         Is_Usermode : Boolean := PT (Current_Region_Start.Table).Is_Usermode;
      begin
         if Is_Usermode then
            Result (1) := 'U';
         else
            Result (1) := '-';
         end if;
            
         Result (2) := 'R';
         if Is_Writable then
            Result (3) := '-';
         else
            Result (3) := 'W';
         end if;

         return Result;
      end Get_Flag_String;

      function To_Hex is new Util.To_Hex (Storage_Count);
      procedure Print (Dir : Page_Directory_Index; Table : Page_Table_Index) is
         Region_Start_Address : constant Virtual_Address := From_Virtual_Address_Break (Current_Region_Start);
         Region_End_Address :   constant Virtual_Address := From_Virtual_Address_Break ((Directory => Dir, Table => Table, Offset => 0));
      begin
         Logger.Log_Info (To_Hex (Storage_Count (Region_Start_Address), 8)      & " " &
                          To_Hex (Storage_Count (Region_End_Address), 8)        & " " &
                          To_Hex (Region_End_Address - Region_Start_Address, 8) & " " &
                          Get_Flag_String);
      end Print;

      procedure Test (Dir : Page_Directory_Index; Table : Page_Table_Index) is
         Current_PT : Page_Table_Access := null;
      begin
         if not PD (Current_Region_Start.Directory).Present then
            Current_Region_Start.Directory := Dir;
            Current_Region_Start.Table := Table;
            return;
         end if;

         PT := Get_Page_Table (CR3, Current_Region_Start.Directory);
         if not PT (Current_Region_Start.Table).Present then
            Current_Region_Start.Directory := Dir;
            Current_Region_Start.Table := Table;
            return;
         end if;

         if not PD (Dir).Present then
            Print (Dir, Table);
            Current_Region_Start.Directory := Dir;
            Current_Region_Start.Table := Table;
            return;
         end if;

         Current_PT := Get_Page_Table (CR3, Dir);
         if not Current_PT (Table).Present then
            Print (Dir, Table);
            Current_Region_Start.Directory := Dir;
            Current_Region_Start.Table := Table;
            return;
         end if;

         if (Dir = Page_Directory'Last and Table = Page_Table'Last)                       or else
            Current_PT (Table).Is_Usermode /= PT (Current_Region_Start.Table).Is_Usermode or else
            Current_PT (Table).Is_Writable /= PT (Current_Region_Start.Table).Is_Writable
         then
            Print (Dir, Table);
            Current_Region_Start.Directory := Dir;
            Current_Region_Start.Table := Table;
         end if;
      end Test;

      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;
      
      for Dir in Page_Directory'Range loop
         for Page in Page_Table'Range loop
            Test (Dir, Page);
         end loop;
      end loop;

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Print_Mapped_Memory;

   -----------------------
   -- Create_Page_Table --
   -----------------------
   procedure Create_Page_Table
     (PD          : Page_Directory_Access;
      PD_Index    : Page_Directory_Index;
      PT          : out Page_Table_Access;
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
      PT := To_Page_Table (To_Address (PD (PD_Index).Address));

      for Index in PT.all'Range loop
         PT (Index) := (Present => False, others => <>);
      end loop;
      -- PT.all := (others => (Present => False, others => <>));
   end Create_Page_Table;

   procedure Create_Page_Table
     (PD          : Page_Directory_Access;
      PD_Index    : Page_Directory_Index;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False)
   is
      PT : Page_Table_Access;
   begin
      Create_Page_Table (PD, PD_Index, PT, Is_Writable => Is_Writable, Is_Usermode => Is_Usermode);
   end Create_Page_Table;

   --------------------------
   -- Map_Page_Table_Entry --
   --------------------------
   procedure Map_Page_Table_Entry
     (Page_Table       : Page_Table_Access;
      Page_Table_Start : Page_Table_Index;
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
     (Page_Directory_Start : in out Page_Directory_Index;
      Page_Table_Start     : in out Page_Table_Index) is
   begin
      if Page_Table_Start = Page_Table'Last then
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
     (Page_Directory       : Page_Directory_Access;
      Page_Directory_Start : Page_Directory_Index;
      Page_Table_Start     : Page_Table_Index;
      Address_To_Map       : Physical_Address;
      Is_Writable          : Boolean := False;
      Is_Usermode          : Boolean := False)
   is
      PD_Index : Page_Directory_Index := Page_Directory_Start;
      PT_Index : Page_Table_Index := Page_Table_Start;
   begin
      if not Page_Directory.all (PD_Index).Present then
         Create_Page_Table
           (Page_Directory, PD_Index, Is_Writable => Is_Writable, Is_Usermode => Is_Usermode);
      end if;
      --  Logger.Log_Info
      --    ("Mapping physical page "
      --     & Address_To_Map'Image
      --     & " at PD index "
      --     & PD_Index'Image
      --     & " PT index "
      --     & PT_Index'Image);
      Map_Page_Table_Entry
        (To_Page_Table (Page_Directory.all (PD_Index)),
         PT_Index,
         To_Page_Address (Address_To_Map),
         Is_Writable => Is_Writable,
         Is_Usermode => Is_Usermode);

   end Map_Physical_Page;

   ----------------
   -- Unmap_Page --
   ----------------
   procedure Unmap_Page
     (Page_Directory       : Page_Directory_Access;
      Page_Directory_Start : Page_Directory_Index;
      Page_Table_Start     : Page_Table_Index;
      Free_Page            : Boolean)
   is
      PD_Index : Page_Directory_Index := Page_Directory_Start;
      PT_Index : Page_Table_Index := Page_Table_Start;
   begin
      if not Page_Directory (PD_Index).Present then
         return;
      end if;

      if Free_Page then
         PMM.Free_Page (To_Address (To_Page_Table (Page_Directory (PD_Index)) (PT_Index).Address));
      end if;
      To_Page_Table (Page_Directory (PD_Index)) (PT_Index).Present := False;
   end Unmap_Page;

   ---------------------------------
   -- Virtual_To_Physical_Address --
   ---------------------------------
   function Virtual_To_Physical_Address
     (CR3 : CR3_register; Address : Virtual_Address) return Physical_Address
   is
      PD                : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
      PT                : Page_Table_Access;
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
   begin
      if not PD (Address_Breakdown.Directory).Present then
         return Physical_Address'First;
      end if;
      PT := Get_Page_Table (CR3, Address_Breakdown.Directory);

      if not PT (Address_Breakdown.Table).Present then
         return Physical_Address'First;
      end if;

      return To_Address (PT (Address_Breakdown.Table).Address) + Address_Breakdown.Offset;
   end Virtual_To_Physical_Address;

   ---------------
   -- Map_Range --
   ---------------
   procedure Map_Range
     (Page_Directory             : Page_Directory_Access;
      Page_Directory_Start       : Page_Directory_Index;
      Page_Table_Start           : Page_Table_Index;
      Start_Address, End_Address : Physical_Address;
      Is_Writable                : Boolean := False;
      Is_Usermode                : Boolean := False)
   is
      Page_Count : Positive := Get_Number_Of_Pages (End_Address - Start_Address);

      PD_Index       : Page_Directory_Index := Page_Directory_Start;
      PT_Index       : Page_Table_Index := Page_Table_Start;
      Address_To_Map : Physical_Address := Start_Address;
   begin
      Logger.Log_Info ("Mapping range " & Start_Address'Image & " - " & End_Address'Image);
      Logger.Log_Info ("Number of pages to map: " & Natural'Image (Page_Count));
      for i in 1 .. Page_Count loop
         if not Page_Directory.all (PD_Index).Present then
            Create_Page_Table
              (Page_Directory, PD_Index, Is_Writable => Is_Writable, Is_Usermode => Is_Usermode);
         end if;

         Map_Page_Table_Entry
           (To_Page_Table (Page_Directory.all (PD_Index)),
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
      PD                  : Page_Directory_Access := Get_Page_Directory (CR3);
      Address_Breakdown   : Virtual_Address_Break := To_Virtual_Address_Break (Null_Address);
      PMM_Start_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (PMM.Get_Pmm_Start_Address);
      Kernel_Start_Break  : Virtual_Address_Break := To_Virtual_Address_Break (Kernel_Start);
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      -- Identity map the kernel
      Logger.Log_Info ("Identity map kernel " & Kernel_Start'Image & "-" & Kernel_End'Image);
      Map_Range
        (PD,
         Address_Breakdown.Directory,
         Address_Breakdown.Table,
         Null_Address,
         Kernel_Start,
         Is_Writable => False,
         Is_Usermode => False);
      Map_Range
        (PD,
         Kernel_Start_Break.Directory,
         Kernel_Start_Break.Table,
         Kernel_Start,
         Kernel_End,
         Is_Writable => True,
         Is_Usermode => False);
      Map_Range
        (PD,
         PMM_Start_Breakdown.Directory,
         PMM_Start_Breakdown.Table,
         PMM.Get_Pmm_Start_Address,
         PMM.Get_Pmm_End_Address,
         Is_Writable => False,
         Is_Usermode => False);

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Identity_Map;

   -------------
   -- Can_Fit --
   -------------
   function Can_Fit
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      PD                : Page_Directory_Access := Get_Page_Directory (CR3);
      PT                : Page_Table_Access;
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      To_Fit            : Storage_Count := Size;
   begin
      --  Logger.Log_Info ("Can_Fit: Checking if " & To_Fit'Image & " bytes can fit at " & Address'Image);
      --  Logger.Log_Info ("Can_Fit: Address breakdown: " & Address_Breakdown'Image);
      for PD_Index in Address_Breakdown.Directory .. Page_Directory'Last loop
         exit when To_Fit = 0;
         if not PD (PD_Index).Present then
            To_Fit := To_Fit - Storage_Count'Min (To_Fit, Page_Table'Length * PMM_PAGE_SIZE);
         else
            PT := Get_Page_Table (CR3, PD_Index);
            for PT_Index in Address_Breakdown.Table .. Page_Table'Last loop
               if not PT (PT_Index).Present then
                  To_Fit := To_Fit - Storage_Count'Min (To_Fit, PMM_PAGE_SIZE);
               else
                  return To_Fit = 0;
               end if;
            end loop;
            Address_Breakdown.Table := 0;
         end if;
      end loop;
      return To_Fit = 0;
   end Can_Fit;

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
      PD                : Page_Directory_Access := Get_Page_Directory (CR3);
      PT                : Page_Table_Access;
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      To_Fit : Storage_Count := Data_Size;
   begin
      if not Can_Fit (CR3, Address, Data_Size) then
         Logger.Log_Error ("Cannot fit " & Data_Size'Image & " at " & Address'Image);
         return False;
      end if;

      while To_Fit > 0 loop
         --  Logger.Log_Info ("At: " & Address_Breakdown'Image);
         if not PD.all (Address_Breakdown.Directory).Present then
            Logger.Log_Info ("PTE entry not present");
            Create_Page_Table
              (PD,
               Address_Breakdown.Directory,
               Is_Writable => Is_Writable,
               Is_Usermode => Is_Usermode);
         end if;

         PT := Get_Page_Table (CR3, Address_Breakdown.Directory);
         -- Logger.Log_Info ("PT: " & PT.all'Image);
         Map_Page_Table_Entry
           (PT,
            Address_Breakdown.Table,
            To_Page_Address (Allocate_Page),
            Is_Writable => Is_Writable,
            Is_Usermode => Is_Usermode);

         To_Fit := To_Fit - Storage_Count'Min (To_Fit, PMM_PAGE_SIZE);
         --  Map the data
         Address_Breakdown.Offset := 0;
         Next (Address_Breakdown.Directory, Address_Breakdown.Table);
      end loop;

      return True;
   end Alloc;


   ---------------------
   -- Is_Range_Mapped --
   ---------------------
   function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      PD  : Page_Directory_Access := Get_Page_Directory (CR3);
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);

      First_Page_Table : constant Page_Directory_Index := Address_Breakdown.Directory;
      Last_Page_Table :  constant Page_Directory_Index := Page_Directory_Index (Get_Number_Of_Page_Tables (Size, Address_Breakdown.Offset) - 1);

      Number_Of_Pages : Natural := Get_Number_Of_Pages (Size, Address_Breakdown.Offset);
      First_Page : Page_Table_Index := Address_Breakdown.Table;
      Last_Page  : Page_Table_Index := Page_Table_Index (Positive'Min (Number_Of_Pages - 1, Positive (Page_Table_Index'Last)));
   begin
      if (for some Page_Directory_Entry of PD (First_Page_Table .. Last_Page_Table) => not Page_Directory_Entry.Present) then
         Logger.Log_Error ("One Page_Directory not present" & First_Page_Table'Image & ".." & Last_Page_Table'Image);
         return False;
      end if;

      for Index in First_Page_Table .. Last_Page_Table loop
         if (for some Page of Get_Page_Table (CR3, Index).all (First_Page .. Last_Page) => not Page.Present) then
            Logger.Log_Error ("Not mapped " & Index'Image);
            return False;
         end if;

         Last_Page  := Page_Table_Index (Natural'Min (Number_Of_Pages - 1, Natural (Page_Table_Index'Last)));
         Number_Of_Pages := Number_Of_Pages - Natural'Min (Number_Of_Pages, Page_Table'Length);
         First_Page := 0;
      end loop;

      return True;
   end Is_Range_Mapped;

   ---------------------
   -- Find_Next_Space --
   ---------------------
   function Find_Next_Space
     (CR3 : CR3_register; Size : Storage_Count; Start : System.Address) return Virtual_Address_Break
   is
      Breakdown      : Virtual_Address_Break := To_Virtual_Address_Break (Start);
      PD             : Page_Directory_Access := Get_Page_Directory (CR3);
   begin
      if Breakdown = To_Virtual_Address_Break (Null_Address) then
         Next (Breakdown.Directory, Breakdown.Table);
      end if;

      for PD_Index in Breakdown.Directory .. Page_Directory'Last loop
         for PT_Index in Breakdown.Table .. Page_Table'Last loop
            if Can_Fit (CR3, From_Virtual_Address_Break (Breakdown), Size) then
               return Breakdown;
            end if;

            Next (Breakdown.Directory, Breakdown.Table);
         end loop;
      end loop;

      return To_Virtual_Address_Break (Null_Address);
   end;

   ------------------
   -- Kernel_Alloc --
   ------------------
   function Kernel_Alloc
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Null_Address);
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
      Success : Boolean := True;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;
      Address_Breakdown := Find_Next_Space (CR3, Size, Null_Address);
      if Address_Breakdown = To_Virtual_Address_Break (Null_Address) then
         Logger.Log_Error ("No more free space in the Page Directory");
         Success := False;
      end if;

      Logger.Log_Info
        ("Kernel_Alloc: Allocating "
         & Size'Image
         & " bytes at "
         & From_Virtual_Address_Break (Address_Breakdown)'Image);

      if Success and then not Alloc
               (CR3,
                From_Virtual_Address_Break (Address_Breakdown),
                Size,
                Is_Writable => Is_Writable,
                Is_Usermode => Is_Usermode)
      then
         Success := False;
      end if;

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;

      if Success then
         return From_Virtual_Address_Break (Address_Breakdown);
      end if; 

      return Null_Address;
   end Kernel_Alloc;

   ----------------------------
   -- Process_To_Process_Map --
   ----------------------------
   function Process_To_Process_Map
     (Source_CR3     : CR3_register;
      Source_Address : Virtual_Address;
      Dest_CR3       : CR3_register;
      Size           : Storage_Count;
      Hint           : Virtual_Address := System.Null_Address) return Virtual_Address
   is
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
      Offset_In_Page        : constant Virtual_Address_Offset := To_Virtual_Address_Break (Source_Address).Offset;
      Page_Count              : constant Positive := Get_Number_Of_Pages (Size + Storage_Count (Offset_In_Page));

      Return_Address        : System.Address;
      Dest_Address          : Virtual_Address_Break;

      --------------------------
      -- Compute_Dest_Address --
      --------------------------
      function Compute_Dest_Address return Virtual_Address_Break is
         begin
         if Hint /= System.Null_Address then
            return  To_Virtual_Address_Break (Hint);
         else
           return Find_Next_Space (Dest_CR3, Size + Storage_Count (Offset_In_Page), Null_Address);
         end if;
      end Compute_Dest_Address;

      ------------------------------
      -- Disable_Paging_If_Needed --
      ------------------------------
      procedure Disable_Paging_If_Needed is
      begin
         if Paging_Currently_Enabled then
            Disable_Paging;
         end if;
      end Disable_Paging_If_Needed;

      ------------------------------
      -- Re_Enable_Paging_If_Needed --
      ------------------------------
      procedure Re_Enable_Paging_If_Needed is
      begin
         if Paging_Currently_Enabled then
            Enable_Paging;
         end if;
      end Re_Enable_Paging_If_Needed;


   begin
      Disable_Paging_If_Needed;

      if not Is_Range_Mapped (Source_CR3, Source_Address, Size) then
         Logger.Log_Error ("Address is not mapped");
         Re_Enable_Paging_If_Needed;
         return Null_Address;
      end if;

      Dest_Address := Compute_Dest_Address;
      if Dest_Address = Null_Address_Break or else not Can_Fit (Dest_CR3, From_Virtual_Address_Break (Dest_Address), Size) then
         Logger.Log_Error ("Map_Process_Memory: Could not find space in destination process");
         Re_Enable_Paging_If_Needed;
         return Null_Address;
      end if;
      
      Return_Address := From_Virtual_Address_Break (Dest_Address) + Offset_In_Page;

      for i in 0 .. Page_Count - 1 loop
         Map_Physical_Page (
            Page_Directory => Get_Page_Directory (Dest_CR3),
            Page_Directory_Start => Dest_Address.Directory,
            Page_Table_Start => Dest_Address.Table,
            Address_To_Map => Virtual_To_Physical_Address (Source_CR3, Source_Address + Storage_Count (i * Positive (PMM_PAGE_SIZE))),
            Is_Writable => True,
            Is_Usermode => True);
         Next (Dest_Address.Directory, Dest_Address.Table);
      end loop;

      Re_Enable_Paging_If_Needed;
      return Return_Address;
   end Process_To_Process_Map;

   ------------------
   -- Memory_Unmap --
   ------------------
   procedure Memory_Unmap
     (CR3 : CR3_register; Address : System.Address; Size : Storage_Count; Free_Page : Boolean)
   is
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
      PD                       : constant Page_Directory_Access := Get_Page_Directory (CR3);
   
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      Page_Count               : constant Natural := Get_Number_Of_Pages (size, Address_Breakdown.Offset);
   
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      for i in 1 .. Page_Count loop
         Unmap_Page (PD, Address_Breakdown.Directory, Address_Breakdown.Table, Free_Page);
         Next (Address_Breakdown.Directory, Address_Breakdown.Table);
      end loop;
   
      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Memory_Unmap;

end x86.vmm;
