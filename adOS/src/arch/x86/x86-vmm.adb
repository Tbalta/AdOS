with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Ada.Assertions;
with System.Secondary_Stack;
with Log;
package body x86.vmm is
   use Standard.ASCII;
   package Logger renames Log.Serial_Logger;

   function To_Address (Addr : Page_Address) return System.Address is
   begin
      return System.Address (Integer_Address (Addr) * 4_096);
   end To_Address;

   function To_Page_Table_Address (Addr : System.Address) return Page_Table_Address is
   begin
      return Page_Table_Address (Integer_Address (Addr) / 4_096);
   end To_Page_Table_Address;

   function To_Page_Directory_Address (Addr : System.Address) return Page_Directory_Address is
   begin
      return Page_Directory_Address (Integer_Address (Addr) / 4_096);
   end To_Page_Directory_Address;

   function To_Page_Address (Addr : System.Address) return Page_Address is
   begin
      return Page_Address (Integer_Address (Addr) / 4_096);
   end To_Page_Address;

   procedure Enable_Paging is
   begin
      --  Logger.Log_Info ("Enabling paging");
      --!format off
      Asm  ("movl %%cr0, %%eax"      & LF & HT & 
            "or $0x80000001, %%eax"  & LF & HT &
            "movl %%eax, %%cr0",
         Volatile => True);
      --!format off
      Is_Paging_Enabled := True;
   end Enable_Paging;

   procedure Disable_Paging is
   begin
      --  Logger.Log_Info ("Disabling paging");
      --!format off
      Asm ("mov %%cr0, %%eax"        & LF &
            "and $0x7FFFFFFF, %%eax" & LF &
            "mov %%eax, %%cr0"       & LF,
            Volatile => True);
      --!format on
      Is_Paging_Enabled := False;
   end Disable_Paging;

   function Create_CR3 return CR3_register is
      CR3 : CR3_register;
   begin
      --  Used to allocate Page Directory table
      CR3.Address := To_Page_Address (Allocate_Page);
      CR3.PCD := True;
      CR3.PWT := True;

      --  Init the Page Directory
      declare
         PD : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
      begin
         PD.all := Page_Directory'(others => (Present => False, others => <>));
      end;

      return CR3;
   end Create_CR3;

   procedure Load_CR3 (CR3 : CR3_register) is
   begin
      --!format off
      Asm ( "movl %0, %%eax"     & LF &
            "movl %%eax, %%cr3"  & LF,
         Inputs   => CR3_register'Asm_Input ("a", CR3),
         Volatile => True);
      --!format on
   end Load_CR3;

   function Get_Current_CR3 return CR3_register is
      CR3 : CR3_register;
   begin
      --!format off
      Asm ( "movl %%cr3, %%eax"  & LF &
            "movl %%eax, %0"     & LF,
         Outputs  => CR3_register'Asm_Output ("=a", CR3),
         Volatile => True);
      --!format on

      return CR3;
   end Get_Current_CR3;

   procedure Create_Page_Table
     (PD          : Page_Directory_Access;
      PD_Index    : Page_Directory_Index;
      PT          : out Page_Table_Access;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) is
   begin
      PD.all (PD_Index).Present := True;
      PD.all (PD_Index).Is_Writable := True;
      PD.all (PD_Index).Is_Usermode := True;
      PD.all (PD_Index).Write_Through := False;
      PD.all (PD_Index).Cache_Disable := False;
      PD.all (PD_Index).Accessed := False;
      PD.all (PD_Index).Page_Size := False;
      PD.all (PD_Index).Global := False;
      PD.all (PD_Index).Address := To_Page_Address (Allocate_Page);

      PT := To_Page_Table (To_Address (PD.all (PD_Index).Address));
      PT.all := Page_Table'(others => (others => <>));
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

      PT := To_Page_Table_Access (PD (Address_Breakdown.Directory).Address);

      if not PT (Address_Breakdown.Table).Present then
         return Physical_Address'First;
      end if;

      return To_Address (PT (Address_Breakdown.Table).Address) + Address_Breakdown.Offset;
   end Virtual_To_Physical_Address;

   procedure Map_Range
     (Page_Directory             : Page_Directory_Access;
      Page_Directory_Start       : Page_Directory_Index;
      Page_Table_Start           : Page_Table_Index;
      Start_Address, End_Address : Physical_Address;
      Is_Writable                : Boolean := False;
      Is_Usermode                : Boolean := False)
   is
      PT_Count : Natural := (Natural (To_Integer (End_Address - Start_Address)) + 4_095) / 4_096;

      PD_Index       : Page_Directory_Index := Page_Directory_Start;
      PT_Index       : Page_Table_Index := Page_Table_Start;
      Address_To_Map : Physical_Address := Start_Address;
   begin
      Logger.Log_Info ("Mapping range " & Start_Address'Image & " - " & End_Address'Image);
      Logger.Log_Info ("Number of pages to map: " & Natural'Image (PT_Count));
      for i in 1 .. PT_Count loop
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

   procedure Identity_Map (CR3 : CR3_register) is
      PD                  : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
      Address_Breakdown   : Virtual_Address_Break := To_Virtual_Address_Break (Null_Address);
      PMM_Start_Breakdown : Virtual_Address_Break :=
        To_Virtual_Address_Break (PMM.Get_Pmm_Start_Address);
   begin

      -- Identity map the kernel
      Logger.Log_Info ("Identity map kernel " & Kernel_Start'Image & "-" & Kernel_End'Image);
      Map_Range
        (PD,
         Address_Breakdown.Directory,
         Address_Breakdown.Table,
         Null_Address,
         Kernel_End,
         Is_Writable => True,
         Is_Usermode => False);
      Map_Range
        (PD,
         PMM_Start_Breakdown.Directory,
         PMM_Start_Breakdown.Table,
         PMM.Get_Pmm_Start_Address,
         PMM.Get_Pmm_End_Address,
         Is_Writable => True,
         Is_Usermode => False);
   end Identity_Map;

   function Can_Fit
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      PD                : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
      PT                : Page_Table_Access;
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      To_Fit            : Storage_Count := Size;
   begin
      --  Logger.Log_Info ("Can_Fit: Checking if " & To_Fit'Image & " bytes can fit at " & Address'Image);
      --  Logger.Log_Info
      --    ("Can_Fit: Address breakdown: " &
      --     Address_Breakdown.Directory'Image & " " &
      --     Address_Breakdown.Table'Image & " " &
      --     Address_Breakdown.Offset'Image);
      for PD_Index in Address_Breakdown.Directory .. Page_Directory'Last loop
         exit when To_Fit = 0;
         if not PD (PD_Index).Present then
            To_Fit := To_Fit - Storage_Count'Min (To_Fit, Page_Table'Length * PMM_PAGE_SIZE);
         else
            PT := To_Page_Table (To_Address (PD (PD_Index).Address));
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

   function Alloc
     (CR3         : CR3_register;
      Address     : Virtual_Address;
      Data_Size   : Storage_count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Boolean
   is
      --  Returns True if the mapping was successful and False otherwise

      PD                : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
      PT                : Page_Table_Access;
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);

      To_Fit : Storage_Count := Data_Size;

      PD_Entry : Page_Directory_Entry renames PD (Address_Breakdown.Directory);
   begin
      if not Can_Fit (CR3, Address, Data_Size) then
         return False;
      end if;

      while To_Fit > 0 loop
         if not PD.all (Address_Breakdown.Directory).Present then
            Create_Page_Table
              (PD,
               Address_Breakdown.Directory,
               Is_Writable => Is_Writable,
               Is_Usermode => Is_Usermode);
         end if;

         PT := To_Page_Table (To_Address (PD_Entry.Address));

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

   function Map_Data
     (CR3         : in out CR3_register;
      Address     : Virtual_Address;
      Data        : in Data_Type;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Boolean
   is
      --  Returns True if the mapping was successful and False otherwise
      Data_Size : Storage_Count := Data'Size / Storage_Unit;

      procedure memcpy (dest : System.Address; src : System.Address; size : Natural);
      pragma Import (C, memcpy, "memcpy");

      Data_Buffer : System.Address := Data'Address;

   begin
      Logger.Log_Info ("Map_Data: Mapping " & Data_Size'Image & " bytes at " & Address'Image);

      Disable_Paging;
      if not Alloc (CR3, Address, Data_Size, Is_Writable => Is_Writable, Is_Usermode => Is_Usermode)
      then
         Logger.Log_Error ("Map_Data: Could not allocate memory for data");
         return False;
      end if;

      Enable_Paging;
      memcpy (dest => Address, src => Data'Address, size => Natural (Data_Size));

      return True;
   end Map_Data;

   function Find_Next_Space
     (CR3 : CR3_register; Size : Storage_Count; Start : System.Address) return Virtual_Address_Break
   is
      Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Start);
      PD        : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
      Paging_Enabled : Boolean := Is_Paging_Enabled;
   begin
      Disable_Paging;

      for PD_Index in Breakdown.Directory .. Page_Directory'Last loop
         for PT_Index in Breakdown.Table .. Page_Table'Last loop
            if Can_Fit (CR3, From_Virtual_Address_Break (Breakdown), Size) then
               if Paging_Enabled then
                  Enable_Paging;
               end if;
               return Breakdown;
            end if;

            Next (Breakdown.Directory, Breakdown.Table);
         end loop;
      end loop;

      if Paging_Enabled then
         Enable_Paging;
      end if;
      return To_Virtual_Address_Break (Null_Address);
   end;

   function kmalloc
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address
   is
      Address_Breakdown : Virtual_Address_Break := Find_Next_Space (CR3, Size, Null_Address);
      Paging_Enabled : Boolean := Is_Paging_Enabled;
   begin
      if Address_Breakdown = Last_Virtual_Address_Break then
         Logger.Log_Error ("No more free space in the Page Directory");
         return Null_Address;
      end if;

      Logger.Log_Info
        ("kmalloc: Allocating "
         & Size'Image
         & " bytes at "
         & From_Virtual_Address_Break (Address_Breakdown)'Image);

      Disable_Paging;
      if not Alloc
               (CR3,
                From_Virtual_Address_Break (Address_Breakdown),
                Size,
                Is_Writable => Is_Writable,
                Is_Usermode => Is_Usermode)
      then
         Logger.Log_Error ("kmalloc: Could not allocate memory");
         if Paging_Enabled then
            Enable_Paging;
         end if;
         return Null_Address;
      end if;

      if Paging_Enabled then
         Enable_Paging;
      end if;
      return From_Virtual_Address_Break (Address_Breakdown);
   end kmalloc;

   function Process_To_Process_Map
     (Source_CR3     : CR3_register;
      Source_Address : System.Address;
      Dest_CR3       : CR3_register;
      Size           : Storage_Count) return System.Address
   is
      Paging_Enabled : Boolean := Is_Paging_Enabled;
      Offset_In_Page : Virtual_Address_Offset := To_Virtual_Address_Break (Source_Address).Offset;

      User_Physical_Address : Physical_Address;
      PT_Count              : Natural := Natural ((Size + 4_095 + Offset_In_Page) / 4_096);
      Return_Address        : System.Address;
      Dest_Address          : Virtual_Address_Break :=
        Find_Next_Space (Dest_CR3, Size + Offset_In_Page, Null_Address);
   begin
      Disable_Paging;
      --  !! TODO: Ensure [for page in Source_Address to Source_Address + Size that page is mapped in Source_CR3]
      Return_Address := From_Virtual_Address_Break (Dest_Address) + Offset_In_Page;
      Ada.Assertions.Assert
        (Return_Address /= Null_Address,
         "Map_Process_Memory: Could not find space in destination process");

      for i in 0 .. PT_Count - 1 loop
         User_Physical_Address :=
           Virtual_To_Physical_Address
             (Source_CR3, Source_Address + System.Address (i * PMM_PAGE_SIZE));
         --  Logger.Log_Info (Integer (Source_Address + System.Address (i * PMM_PAGE_SIZE))'Image & " - " & User_Physical_Address'Image);
         Map_Physical_Page
           (To_Page_Directory (To_Address (Dest_CR3.Address)),
            Dest_Address.Directory,
            Dest_Address.Table,
            User_Physical_Address,
            Is_Writable => True,
            Is_Usermode => True);
         Next (Dest_Address.Directory, Dest_Address.Table);
      end loop;

      if Paging_Enabled then
         Enable_Paging;
      end if;
      return Return_Address;
   end Process_To_Process_Map;

   procedure Unmap (CR3 : CR3_register; Address : System.Address; Size : Storage_Count; Free_Page : Boolean) is
      PD                : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      PT_Count          : Natural := Natural ((size + 4_095) / 4_096);
   begin
      Disable_Paging;
      --  Logger.Log_Info
      --    ("Unmapping "
      --     & Size'Image
      --     & " bytes at "
      --     & Address'Image
      --     & " spanning "
      --     & PT_Count'Image
      --     & " pages.");
      for i in 0 .. PT_Count - 1 loop
         Unmap_Page (PD, Address_Breakdown.Directory, Address_Breakdown.Table, Free_Page);
         Next (Address_Breakdown.Directory, Address_Breakdown.Table);
      end loop;
      Enable_Paging;
   end Unmap;

   procedure Load_Kernel_Mapping is
      procedure test is new System.Secondary_Stack.SS_Info (Logger.Log_Info);
   begin
      Disable_Paging;
      Load_CR3 (Kernel_CR3);
      Enable_Paging;
   end Load_Kernel_Mapping;

   function Get_Kernel_CR3 return CR3_register is
   begin
      return Kernel_CR3;
   end Get_Kernel_CR3;

   procedure Set_Kernel_CR3 (CR3 : CR3_register) is
   begin
      Kernel_CR3 := CR3;
   end Set_Kernel_CR3;

end x86.vmm;
