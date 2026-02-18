with Interfaces.C;
with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Ada.Assertions;
--  with System.Secondary_Stack;
with Loggers;
with x86.vmm;
with Util;
with Limine;

package body x86.vmm is
   use Standard.ASCII;
   pragma Assertion_Policy (Assert => Check);
   package Logger renames Loggers;

   function Is_Physical_Address (Address : Physical_Address) return Boolean is
      use Limine;
   begin
      return Storage_Offset (Address) < hhdm_response.offset;
   end Is_Physical_Address;

   function Is_Virtual_Address (Address : Virtual_Address) return Boolean is
      use Limine;
   begin
      return Storage_Offset (Address) >= hhdm_response.offset;
   end Is_Virtual_Address;

   function To_Virtual_Address (Address : Physical_Address) return Virtual_Address is
      use Limine;
   begin
      pragma Assert (Is_Physical_Address (Address));
      return Virtual_Address (Address + hhdm_response.offset);
   end To_Virtual_Address;

   function To_Physical_Address (Address : Virtual_Address) return Physical_Address is
      use Limine;
   begin
      pragma Assert (Is_Virtual_Address (Address));
      return Physical_Address (Address - hhdm_response.offset);
   end To_Physical_Address;

   ----------------
   -- To_Address --
   ----------------
   function To_Address (Addr : Page_Address) return Physical_Address is (Physical_Address (Storage_Count (Integer_Address (Addr)) * PAGE_SIZE));

   -------------------------
   -- Get_Number_Of_Pages --
   -------------------------
   function Get_Number_Of_Pages (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
   is (Positive ((Size + Storage_Count (PAGE_SIZE - 1 + Offset)) / PAGE_SIZE));



   ---------------------
   -- To_Page_Address --
   ---------------------
   function To_Page_Address (Addr : Physical_Address) return Page_Address is
    (Page_Address (Storage_Count (Integer_Address (Addr)) / PAGE_SIZE));

   ------------------------
   -- Get_Page_Directory --
   ------------------------   
   function Is_Paging_Enabled return Boolean
   is
   begin
      return Paging_Enabled;
   end Is_Paging_Enabled;

   -------------------
   -- Enable_Paging --
   -------------------
   procedure Enable_Paging is
   begin
      if Paging_Enabled then
         Logger.Log_Warning ("Paging is already enabled!");
         return;
      end if;
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
      Paging_Enabled := False;
   end Disable_Paging;


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

      ----------
   -- Next --
   ----------
   procedure Next (Address : in out Virtual_Address_Break) is
   begin
      
      Address := To_Virtual_Address_Break (From_Virtual_Address_Break (Address) + PAGE_SIZE);
   end Next;

   -- PLM4 --
   function Get_PML4 (CR3 : CR3_Register) return Page_Map_Level_4_Access is
   begin
      return To_PML4_Access (To_Address (CR3.Address));
   end Get_PML4;
   function Get_PML4_Entry (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_4_Entry_Access is
      PLM4 : Page_Map_Level_4_Access := Get_PML4 (CR3);
   begin
      return PLM4 (Address.PML4_Index)'Access;
   end Get_PML4_Entry;

   -- PML3 --
   function Get_PML3 (CR3 : CR3_Register; PML4_Index : Page_Index) return Page_Map_Level_3_Access is
      PLM4 : Page_Map_Level_4_Access := Get_PML4 (CR3);
   begin
      return To_PML3_Access (To_Address (PLM4 (PML4_Index).Address));
   end Get_PML3;
   function Get_PML3_Entry (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_3_Entry_Access is
      PML3 : Page_Map_Level_3_Access := Get_PML3 (CR3, Address.PML4_Index);
   begin
      return PML3 (Address.PML3_Index)'Access;
   end Get_PML3_Entry;

   -- PML2 --
   function Get_PML2 (CR3 : CR3_Register; PML4_Index, PML3_Index : Page_Index) return Page_Map_Level_2_Access is
      PML3 : Page_Map_Level_3_Access := Get_PML3 (CR3, PML4_Index);
   begin
      return To_PML2_Access (To_Address (PML3 (PML3_Index).Address));
   end Get_PML2;
   function Get_PML2_Entry (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_2_Entry_Access is
      PML2 : Page_Map_Level_2_Access := Get_PML2 (CR3, Address.PML4_Index, Address.PML3_Index);
   begin
      return PML2 (Address.PML2_Index)'Access;
   end Get_PML2_Entry;

   -- PML1 --
   function Get_PML1 (CR3 : CR3_Register; PML4_Index, PML3_Index, PML2_Index : Page_Index) return Page_Map_Level_1_Access is
      PML2 : Page_Map_Level_2_Access := Get_PML2 (CR3, PML4_Index, PML3_Index);
   begin
      return To_PML1_Access(To_Address (PML2 (PML2_Index).Address));
   end Get_PML1;
   function Get_PML1_Entry (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_1_Entry_Access
    is
      PML1 : Page_Map_Level_1_Access := Get_PML1 (CR3, Address.PML4_Index, Address.PML3_Index, Address.PML2_Index);
   begin
      return PML1 (Address.PML1_Index)'Access;
   end Get_PML1_Entry;

   procedure Print_Mapped_Memory (CR3 : CR3_Register) is
      Current_Region_Start : Virtual_Address_Break := Null_Address_Break;
      Current_Region : Virtual_Address_Break := Null_Address_Break;



      function Get_Region_Size return Storage_Count is
      begin
         return From_Virtual_Address_Break (Current_Region) - From_Virtual_Address_Break (Current_Region_Start);
      end Get_Region_Size;

      function Get_Flag_String return String is
         Result : String (1 .. 3);
         Is_Writable : Boolean := Get_PML1_Entry (CR3, Current_Region_Start).Is_Writable;
         Is_Usermode : Boolean := Get_PML1_Entry (CR3, Current_Region_Start).Is_Usermode;
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
      procedure Print (Region_End_Address : Virtual_Address) is
         Region_Start_Address : constant Virtual_Address := From_Virtual_Address_Break (Current_Region_Start);
      begin
         Logger.Log_Info (To_Hex (Storage_Count (Region_Start_Address), 8)      & " " &
                          To_Hex (Storage_Count (Region_End_Address), 8)        & " " &
                          To_Hex (Region_End_Address - Region_Start_Address, 8) & " " &
                          Get_Flag_String);
      end Print;

      procedure Test (Test_Address : Virtual_Address_Break) is
      begin
         if not Is_Mapped (CR3, Current_Region_Start) then
            Current_Region_Start := Test_Address;
            return;
         end if;

         if not Is_Mapped (CR3, Test_Address) then
            Print (From_Virtual_Address_Break (Test_Address));
            Current_Region_Start := Test_Address;
            return;
         end if;

         if Get_Page_Number (Test_Address) = Page_Per_PML4 - 1                                                       or else
            Get_PML1_Entry (CR3, Test_Address).Is_Usermode /= Get_PML1_Entry (CR3, Current_Region_Start).Is_Usermode or else
            Get_PML1_Entry (CR3, Test_Address).Is_Writable /= Get_PML1_Entry (CR3, Current_Region_Start).Is_Writable
         then
            Print (From_Virtual_Address_Break (Test_Address));
            Current_Region_Start := Test_Address;
         end if;
      end Test;

      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      for Page in 0 .. Page_Per_PML4 - 1 loop
         Test (To_Virtual_Address_Break (System.Address (Storage_Count (Page) * PAGE_SIZE)));
      end loop;
      

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Print_Mapped_Memory;

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
         PML4 : Page_Map_Level_4_Access := Get_PML4 (CR3);
      begin
         PML4.all := (others => (Present => False, others => <>));
      end;

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;

      return CR3;
   end Create_CR3;
   -------------------------
   -- Create_Page_Entries --
   -------------------------
   procedure Create_PLM4_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PLM4 : Page_Map_Level_4_Access := Get_PML4 (CR3);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      PLM4 (Destination.PML4_Index).Present := True;
      PLM4 (Destination.PML4_Index).Is_Writable := True;
      PLM4 (Destination.PML4_Index).Is_Usermode := True;
      PLM4 (Destination.PML4_Index).Write_Through := False;
      PLM4 (Destination.PML4_Index).Cache_Disable := False;
      PLM4 (Destination.PML4_Index).Accessed := False;
      PLM4 (Destination.PML4_Index).Address := To_Page_Address (Page_To_Allocate);

      --  Logger.Log_Info ("Create PLM4" & PLM4 (Destination.PML4_Index)'Image);

      --  Init the Page Map Level 3
      declare
         PML3 : Page_Map_Level_3_Access := To_PML3_Access (To_Address (PLM4 (Destination.PML4_Index).Address));
      begin
         PML3.all := Page_Map_Level_3'(others => (Present => False, others => <>));
      end;
   end Create_PLM4_Entry;

   procedure Create_PML3_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML3 : Page_Map_Level_3_Access := Get_PML3 (CR3, Destination.PML4_Index);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      PML3 (Destination.PML3_Index).Present := True;
      PML3 (Destination.PML3_Index).Is_Writable := True;
      PML3 (Destination.PML3_Index).Is_Usermode := True;
      PML3 (Destination.PML3_Index).Write_Through := False;
      PML3 (Destination.PML3_Index).Cache_Disable := False;
      PML3 (Destination.PML3_Index).Accessed := False;
      PML3 (Destination.PML3_Index).Address := To_Page_Address (Page_To_Allocate);
      --  Logger.Log_Info ("Create PLM3" & PML3 (Destination.PML3_Index)'Image);

      --  Init the Page Map Level 2
      declare
         PML2 : Page_Map_Level_2_Access := To_PML2_Access (To_Address (PML3 (Destination.PML3_Index).Address));
      begin
         PML2.all := Page_Map_Level_2'(others => (Present => False, others => <>));
      end;
   end Create_PML3_Entry;

   procedure Create_PML2_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML2 : Page_Map_Level_2_Access := Get_PML2 (CR3, Destination.PML4_Index, Destination.PML3_Index);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      PML2 (Destination.PML2_Index).Present := True;
      PML2 (Destination.PML2_Index).Is_Writable := True;
      PML2 (Destination.PML2_Index).Is_Usermode := True;
      PML2 (Destination.PML2_Index).Write_Through := False;
      PML2 (Destination.PML2_Index).Cache_Disable := False;
      PML2 (Destination.PML2_Index).Accessed := False;
      PML2 (Destination.PML2_Index).Address := To_Page_Address (Page_To_Allocate);
      --  Logger.Log_Info ("Create PLM2" & PML2 (Destination.PML2_Index)'Image);

      --  Init the Page Map Level 1
      declare
         PML1 : Page_Map_Level_1_Access := To_PML1_Access (To_Address (PML2 (Destination.PML2_Index).Address));
      begin
         PML1.all := Page_Map_Level_1'(others => (Present => False, others => <>));
      end;
   end Create_PML2_Entry;

   procedure Create_PML1_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML1 : Page_Map_Level_1_Access := Get_PML1 (CR3, Destination.PML4_Index, Destination.PML3_Index, Destination.PML2_Index);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      PML1 (Destination.PML1_Index).Present := True;
      PML1 (Destination.PML1_Index).Is_Writable := True;
      PML1 (Destination.PML1_Index).Is_Usermode := True;
      PML1 (Destination.PML1_Index).Write_Through := False;
      PML1 (Destination.PML1_Index).Cache_Disable := False;
      PML1 (Destination.PML1_Index).Accessed := False;
      PML1 (Destination.PML1_Index).Page_Size := False;
      PML1 (Destination.PML1_Index).Address := To_Page_Address (Page_To_Allocate);
      --  Logger.Log_Info ("Create PML1" & PML1 (Destination.PML1_Index)'Image);
      --  Logger.Log_Info ("At " & Destination'Image);
   end Create_PML1_Entry;

   
   procedure Create_Page_Entries
     (CR3 : CR3_Register;
      Destination : Virtual_Address_Break) is
   begin
      if not Get_PML4_Entry (CR3, Destination).Present then
         Create_PLM4_Entry (CR3, Destination);
      end if;

      if not Get_PML3_Entry (CR3, Destination).Present then
         Create_PML3_Entry (CR3, Destination);
      end if;

      if not Get_PML2_Entry (CR3, Destination).Present then
         Create_PML2_Entry (CR3, Destination);
      end if;

      if not Get_PML1_Entry (CR3, Destination).Present then
         Create_PML1_Entry (CR3, Destination);
      end if;
   end Create_Page_Entries;

   function Is_Mapped
     (CR3: CR3_Register; Destination : Virtual_Address_Break) return Boolean is
   begin
      if not Get_PML4_Entry (CR3, Destination).Present then
         return False;
      end if;

      if not Get_PML3_Entry (CR3, Destination).Present then
         return False;
      end if;

      if not Get_PML2_Entry (CR3, Destination).Present then
         return False;
      end if;

      if not Get_PML1_Entry (CR3, Destination).Present then
         return False;
      end if;

      return True;
   end Is_Mapped;

   procedure Set_Entry_Address
     (CR3            : CR3_Register;
      Destination    : Virtual_Address_Break;
      Address_To_Map : Physical_Address) is
      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Destination);
   begin
      PML1_Entry.Address := To_Page_Address (Address_To_Map);
   end Set_Entry_Address;

   procedure Set_Entry_Flags
     (CR3         : CR3_Register;
      Destination : Virtual_Address_Break;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) is
      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Destination);
   begin
      PML1_Entry.Is_Writable := Is_Writable;
      PML1_Entry.Is_Usermode := Is_Usermode;
   end Set_Entry_Flags;

   -----------------------
   -- Map_Physical_Page --
   -----------------------
   procedure Map_Physical_Page
     (
      Process              : CR3_Register;
      Destination          : Virtual_Address_Break;
      Address_To_Map       : Physical_Address;
      Is_Writable          : Boolean := False;
      Is_Usermode          : Boolean := False)
   is
   begin
      Create_Page_Entries (Process, Destination);
      Set_Entry_Address   (Process, Destination, Address_To_Map);
      Set_Entry_Flags     (Process, Destination, Is_Writable, Is_Usermode);
   end Map_Physical_Page;

   ----------------
   -- Unmap_Page --
   ----------------
   procedure Unmap_Page
     (CR3         : CR3_Register;
      Destination : Virtual_Address_Break;
      Free_Page   : Boolean)
   is
      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Destination);
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
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
   begin
      if not Is_Mapped (CR3, Address_Breakdown) then
         return Physical_Address'First;
      end if;

      return To_Address (Get_PML1_Entry (CR3, Address_Breakdown).Address) + Address_Breakdown.Offset;
   end Virtual_To_Physical_Address;

   ---------------
   -- Map_Range --
   ---------------
   procedure Map_Range
     (CR3                        : CR3_Register;
      Destination                : Virtual_Address_Break;
      Start_Address, End_Address : Physical_Address;
      Is_Writable                : Boolean := False;
      Is_Usermode                : Boolean := False)
   is
      Page_Count : Positive := Get_Number_Of_Pages (End_Address - Start_Address);
      Address_To_Map : Physical_Address := Start_Address;
      Current_Destination : Virtual_Address_Break := Destination;
   begin
      Logger.Log_Info ("Mapping range " & Start_Address'Image & " - " & End_Address'Image);
      Logger.Log_Info ("Number of pages to map: " & Natural'Image (Page_Count));
      for i in 1 .. Page_Count loop
         Create_Page_Entries (CR3, Current_Destination);
         Set_Entry_Address (CR3, Current_Destination, Address_To_Map);
         Set_Entry_Flags  (CR3, Current_Destination, Is_Writable, Is_Usermode);
         Next (Current_Destination);
         Address_To_Map := Address_To_Map + Storage_Offset (4_096);
      end loop;
   end Map_Range;

   ------------------
   -- Identity_Map --
   ------------------
   procedure Identity_Map (CR3 : CR3_register) is
      Address_Breakdown   : Virtual_Address_Break := To_Virtual_Address_Break (Virtual_Address (Null_Address));
      PMM_Start_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (PMM.Get_Pmm_Start_Address);
      Kernel_Start_Break  : Virtual_Address_Break := To_Virtual_Address_Break (Kernel_Start);
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;
      
      Map_Range (CR3 => CR3, Destination => To_Virtual_Address_Break (System.Address (16#A0000#)), Start_Address => Physical_Address (16#A0000#), End_Address => Physical_Address (16#C0000#), Is_Writable => True, Is_Usermode => True);

      -- Identity map the kernel
      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Identity_Map;

   -------------
   -- Can_Fit --
   -------------


   function Get_Free_Space
     (CR3 : CR3_register; Address : Virtual_Address_Break) return Storage_Count
   is
      Free_Space : Storage_Count := 0;
      Current_Address : Virtual_Address_Break := Address;
   begin
      for Page in Get_Page_Number (Address) .. Page_Per_PML4 - 1 loop
         if Is_Mapped (CR3, Current_Address) then
            return Free_Space;
         end if;

         Free_Space := Free_Space + PAGE_SIZE;
         Next (Current_Address);
      end loop;

      return Free_Space;
   end Get_Free_Space;

   function Can_Fit
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      Free_Space : Storage_Count := 0;
   begin
      --  Logger.Log_Info ("Can_Fit: Checking if " & Size'Image & " bytes can fit at " & Address'Image);
      --  Logger.Log_Info ("Can_Fit: Address breakdown: " & Address_Breakdown'Image);

      for Page in Get_Page_Number (Address_Breakdown) .. Page_Per_PML4 - 1 loop
         exit when Is_Mapped (CR3, Address_Breakdown);
         exit when Free_Space >= Size;

         Free_Space := Free_Space + PAGE_SIZE;
         Next (Address_Breakdown);

      end loop;

      return Free_Space >= Size;
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
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      To_Fit : Storage_Count := Data_Size;
   begin
      if not Can_Fit (CR3, Address, Data_Size) then
         Logger.Log_Error ("Cannot fit " & Data_Size'Image & " at " & Address'Image);
         return False;
      end if;

      while To_Fit > 0 loop
         --  Logger.Log_Info ("At: " & Address_Breakdown'Image);
         Create_Page_Entries (CR3, Address_Breakdown);

         Set_Entry_Address (CR3, Address_Breakdown, Allocate_Page);
         Set_Entry_Flags (CR3, Address_Breakdown, Is_Writable, Is_Usermode);


         To_Fit := To_Fit - Storage_Count'Min (To_Fit, PMM_PAGE_SIZE);
         --  Map the data
         Address_Breakdown.Offset := 0;
         Next (Address_Breakdown);
      end loop;

      return True;
   end Alloc;


   ---------------------
   -- Is_Range_Mapped --
   ---------------------
   function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      Number_Of_Pages : Natural := Get_Number_Of_Pages (Size, Address_Breakdown.Offset);
   begin
      Logger.Log_Info (Address_Breakdown'Image);
      Logger.Log_Info ("Number_Of_Pages" & Number_Of_Pages'Image);
      for Index in 1 .. Number_Of_Pages loop
         if not Is_Mapped (CR3, Address_Breakdown) then
            Logger.Log_Error ("Not mapped " & Address_Breakdown'Image);
            return False;
         end if;
         Next (Address_Breakdown);
      end loop;

      return True;
   end Is_Range_Mapped;

   ---------------------
   -- Find_Next_Space --
   ---------------------
   function Get_Page_Number (Address : Virtual_Address_Break) return Page_Count is
   begin
      return 
         (Page_Count (Address.PML4_Index) * Page_Per_PML3) + 
         (Page_Count (Address.PML3_Index) * Page_Per_PML2) + 
         (Page_Count (Address.PML2_Index) * Page_Per_PML1) + 
          Page_Count (Address.PML1_Index);
   end Get_Page_Number;


   function Find_Next_Space
     (CR3 : CR3_register; Size : Storage_Count; Start : System.Address) return Virtual_Address_Break
   is
      Breakdown      : Virtual_Address_Break := To_Virtual_Address_Break (Start);
   begin
      if Breakdown = To_Virtual_Address_Break (Null_Address) then
         Next (Breakdown);
      end if;

      for Page in Get_Page_Number (Breakdown) .. Page_Per_PML4 - 1 loop
         if Can_Fit (CR3, From_Virtual_Address_Break (Breakdown), Size) then
            return Breakdown;
         end if;

         Next (Breakdown);
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
            Process => Dest_CR3,
            Destination => Dest_Address,
            Address_To_Map => Virtual_To_Physical_Address (Source_CR3, Source_Address + Storage_Count (i * Positive (PMM_PAGE_SIZE))),
            Is_Writable => True,
            Is_Usermode => True);
         Next (Dest_Address);
      end loop;

      Re_Enable_Paging_If_Needed;
      return Return_Address;
   end Process_To_Process_Map;

   ------------------
   -- Memory_Unmap --
   ------------------
   procedure Memory_Unmap
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count; Free_Page : Boolean)
   is
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      Page_Count        : constant Natural := Get_Number_Of_Pages (size, Address_Breakdown.Offset);
   
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      for i in 1 .. Page_Count loop
         Unmap_Page (CR3, Address_Breakdown, Free_Page);
         Next (Address_Breakdown);
      end loop;
   
      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Memory_Unmap;

end x86.vmm;
