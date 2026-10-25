with Ada.Strings.Text_Buffers.Unbounded;
with Interfaces.C;
with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Ada.Assertions;
with Loggers;
with Util;

with x86.vmm.Structures; use x86.vmm.Structures;
with x86.vmm.vab;        use x86.vmm.vab;
with Limine; use Limine;
with vmm; use vmm;
package body x86.vmm is
   use Standard.ASCII;


   function To_Hex is new Util.To_Hex (Physical_Address);
   function To_Hex is new Util.To_Hex(Virtual_Address);
   pragma Assertion_Policy (Assert => Check);
   package Logger renames Loggers;


   -----------------------------
   -- HHDM Address conversion --
   -----------------------------

   function Is_Physical_Address (Address : Physical_Address) return Boolean is
      (Storage_Offset (Address) < hhdm_response.offset);

   function Is_Virtual_Address (Address : Virtual_Address) return Boolean is
      (Storage_Offset (To_Address (Address)) >= hhdm_response.offset);

   function To_Virtual_Address (Address : Physical_Address) return Virtual_Address is
   begin
      if not Is_Physical_Address (Address) then
         Logger.Log_Error (To_Hex (Address) & " is not a valid Physical Address");
      end if;
      
      return Virtual_Address (Address + hhdm_response.offset);
   end To_Virtual_Address;

   function To_Physical_Address (Address : Virtual_Address) return Physical_Address is
   begin
      if not Is_Virtual_Address (Address) then
         Logger.Log_Error (To_Hex (Address) & " is not a valid virtual address");
      end if;
      return Physical_Address (Address - Limine.Get_HHDM_Offset);
   end To_Physical_Address;



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
      null;
   end Enable_Paging;

   procedure Disable_Paging is
   begin
      null;
   end Disable_Paging;

   --------------------
   -- CR3 Operations --
   --------------------

   function Create_CR3 return CR3_register is
      CR3     : CR3_Register := Get_Kernel_CR3;
      New_CR3 : CR3_register := CR3;
      New_PML4       : Page_Map_Level_4_Access := null;
   begin
      New_CR3.Address := To_Page_Address (Allocate_Page);
      New_PML4   := To_PML4_Access (To_Address (New_CR3.Address));
      
      Logger.Log_Info ("New CR3 PLM4 is located at: " & To_Hex (To_Address (New_CR3.Address)));
      for  Index in New_PML4'Range loop
         New_PML4 (Index).Present := False;
         New_PML4 (Index).Address := Page_Address (0);
      end loop;

      Duplicate_hhdm (Get_Kernel_CR3, New_CR3);

      return New_CR3;
   end Create_CR3;

   procedure Load_CR3 (CR3 : CR3_register) is
   begin
      --!format off
      Asm
        ("movq %0, %%rax" & LF &
         "movq %%rax, %%cr3" & LF,
         Inputs   => CR3_register'Asm_Input ("a", CR3),
         Volatile => True);
      --!format on
   end Load_CR3;

   function Get_Current_CR3 return CR3_register is
      CR3 : CR3_register;
   begin
      --!format off
      Asm
        ("movq %%cr3, %%rax" & LF &
         "movq %%rax, %0" & LF,
         Outputs  => CR3_register'Asm_Output ("=a", CR3),
         Volatile => True);
      --!format on

      return CR3;
   end Get_Current_CR3;

   function Get_PML4_Entry is new Get_PML_Entry_From_Addr_Break (
      Page_Map_Level_Entry => Page_Map_Level_4_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_4_Entry_Access,
      Page_Map_Level => Page_Map_Level_4,
      Page_Map_Level_Access => Page_Map_Level_4_Access,
      Get_Entry_Index =>  Get_PML4_Index,
      Get_PML => Get_PML4);
   function Get_PML3_Entry is new Get_PML_Entry_From_Addr_Break (
      Page_Map_Level_Entry => Page_Map_Level_3_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_3_Entry_Access,
      Page_Map_Level => Page_Map_Level_3,
      Page_Map_Level_Access => Page_Map_Level_3_Access,
      Get_Entry_Index =>  Get_PML3_Index,
      Get_PML => Get_PML3);
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


   function Get_Free_Size (CR3 : CR3_Register; Address : Virtual_Address_Break) return Storage_Count is
      PML4_Entry : Page_Map_Level_4_Entry;
      PML3_Entry : Page_Map_Level_3_Entry;
      PML2_Entry : Page_Map_Level_2_Entry;
      PML1_Entry : Page_Map_Level_1_Entry;

      Current_PML1_Index : Page_Index := Address.PML1_Index;
      Current_PML2_Index : Page_Index := Address.PML2_Index;
      Current_PML3_Index : Page_Index := Address.PML3_Index;
      Current_PML4_Index : Page_Index := Address.PML4_Index;

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
         PML2_Entry := Get_PML_Entry (PML3_Entry, PML2_Index);

         if not PML2_Entry.Present then
            return PAGE_SIZE_2MB;
         end if;

         if PML2_Entry.Page_Size then
            Address_Mapped := True;
            return 0;
         end if;

         for PML_Index in Current_PML1_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML1_Size (PML_Index);
            exit when Address_Mapped;
         end loop;

         Current_PML1_Index := 0;
         return Total_Size;
      end Get_PML2_Size;

   
      function Get_PML3_Size (PML3_Index : Page_Index) return Storage_Count is
         Total_Size : Storage_Count := 0;
      begin
         PML3_Entry := Get_PML_Entry (PML4_Entry, PML3_Index);

         if not PML3_Entry.Present then
            return PAGE_SIZE_1GB;
         end if;

         if PML3_Entry.Page_Size then
            Address_Mapped := True;
            return 0;
         end if;

         for PML_Index in Current_PML2_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML2_Size (PML_Index);
            Current_PML1_Index := 0;
            exit when Address_Mapped;
         end loop;
   
         return Total_Size;
      end Get_PML3_Size;
   
      function Get_PML4_Size (PML4_Index : Page_Index) return Storage_Count is
         Total_Size : Storage_Count := 0;
      begin
         PML4_Entry := Get_PML_Entry (CR3, PML4_Index);

         if not PML4_Entry.Present then
            return PAGE_SIZE_512GB;
         end if;

         for PML_Index in Current_PML3_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML3_Size (PML_Index);
            Current_PML2_Index := 0;
            exit when Address_Mapped;
         end loop;

         return Total_Size;
      end Get_PML4_Size;

      Total_Size : Storage_Count := 0;
   begin
      for PML_Index in Current_PML4_Index .. Page_Index'Last loop
         Total_Size := Total_Size + Get_PML4_Size (PML_Index);
         Current_PML3_Index := 0;
         exit when Address_Mapped;
      end loop;

      return Total_Size;
   end Get_Free_Size;
   function Get_Free_Size (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Count is (Get_Free_Size (CR3, To_Virtual_Address_Break (Address)));

   function Get_Allocated_Size (CR3 : CR3_Register; Address : Virtual_Address_Break) return Storage_Count is
      PML4_Entry : Page_Map_Level_4_Entry;
      PML3_Entry : Page_Map_Level_3_Entry;
      PML2_Entry : Page_Map_Level_2_Entry;
      PML1_Entry : Page_Map_Level_1_Entry;

      Current_PML1_Index : Page_Index := Address.PML1_Index;
      Current_PML2_Index : Page_Index := Address.PML2_Index;
      Current_PML3_Index : Page_Index := Address.PML3_Index;
      Current_PML4_Index : Page_Index := Address.PML4_Index;

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
         PML2_Entry := Get_PML_Entry (PML3_Entry, PML2_Index);

         if not PML2_Entry.Present then
            Address_Mapped := False;
            return 0;
         end if;

         if PML2_Entry.Page_Size then
            return PAGE_SIZE_2MB;
         end if;

         for PML_Index in Current_PML1_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML1_Size (PML_Index);
            exit when not Address_Mapped;
         end loop;

         Current_PML1_Index := 0;
         return Total_Size;
      end Get_PML2_Size;

   
      function Get_PML3_Size (PML3_Index : Page_Index) return Storage_Count is
         Total_Size : Storage_Count := 0;
      begin
         PML3_Entry := Get_PML_Entry (PML4_Entry, PML3_Index);

         if not PML3_Entry.Present then
            Address_Mapped := False;
            return 0;
         end if;

         if PML3_Entry.Page_Size then
            return PAGE_SIZE_1GB;
         end if;

         for PML_Index in Current_PML2_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML2_Size (PML_Index);
            Current_PML1_Index := 0;
            exit when not Address_Mapped;
         end loop;
   
         return Total_Size;
      end Get_PML3_Size;
   
      function Get_PML4_Size (PML4_Index : Page_Index) return Storage_Count is
         Total_Size : Storage_Count := 0;
      begin
         PML4_Entry := Get_PML_Entry (CR3, PML4_Index);

         if not PML4_Entry.Present then
            Address_Mapped := False;
            return 0;
         end if;

         for PML_Index in Current_PML3_Index .. Page_Index'Last loop
            Total_Size := Total_Size + Get_PML3_Size (PML_Index);
            Current_PML2_Index := 0;
            exit when not Address_Mapped;
         end loop;

         return Total_Size;
      end Get_PML4_Size;

      Total_Size : Storage_Count := 0;
   begin
      for PML_Index in Current_PML4_Index .. Page_Index'Last loop
         Total_Size := Total_Size + Get_PML4_Size (PML_Index);
         Current_PML3_Index := 0;
         exit when not Address_Mapped;
      end loop;

      return Total_Size;
   end Get_Allocated_Size;
   function Get_Allocated_Size (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Count is (Get_Allocated_Size (CR3, To_Virtual_Address_Break (Address)));
   -------------------------
   -- Get_Number_Of_Pages --
   -------------------------
   function Get_Number_Of_Pages (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
   is begin
    return (Positive ((Size + Storage_Count (PAGE_SIZE - 1 + Offset)) / PAGE_SIZE));
   end Get_Number_Of_Pages;



   ---------------------
   -- To_Page_Address --
   ---------------------
   function To_Page_Address (Addr : Physical_Address) return Page_Address is
    (Page_Address (Storage_Count (Integer_Address (Addr)) / PAGE_SIZE));

   ----------
   -- Next --
   ----------
   function Get_Entry_Level (CR3 : CR3_register; Address : Virtual_Address_Break) return Entry_Level is
   begin
      if not Get_PML4_Entry (CR3, Address).Present then
         return Entry_Level_4;
      end if;

      if not Get_PML3_Entry (CR3, Address).Present or else 
             Get_PML3_Entry (CR3, Address).Page_Size then
         return Entry_Level_3;
      end if;

      if not Get_PML2_Entry (CR3, Address).Present or else 
             Get_PML2_Entry (CR3, Address).Page_Size then
         return Entry_Level_2;
      end if;

      return Entry_Level_1;
   end Get_Entry_Level;

   procedure Next (CR3 : CR3_register; Address : in out Virtual_Address) is
      Level : Entry_Level := Get_Entry_Level (CR3, To_Virtual_Address_Break (Address));
      Offset : Storage_Offset := Get_Offset (CR3, Address);

      Address_2MB_Mask : constant Virtual_Address := From_Virtual_Address_Break_2MB ((PML4_Index => 511, PML3_Index => 511, PML2_Index => 511, Offset => 0));
      Address_1GB_Mask : constant Virtual_Address := From_Virtual_Address_Break_1GB ((PML4_Index => 511, PML3_Index => 511, PML2_Index => 511, Offset => 0));
   begin
      case Level is
         when Entry_Level_4 =>
            Address := Address + PAGE_SIZE;
         when Entry_Level_3 =>
            Address := Address + PAGE_SIZE_1GB;
            Address := Address and Address_1GB_Mask;
         when Entry_Level_2 =>
            Address := Address + PAGE_SIZE_2MB;
            Address := Address and Address_2MB_Mask;
         when Entry_Level_1 =>
            Address := Address + PAGE_SIZE;
      end case;

      Address := Address - Offset;
   end Next;
   procedure Next (CR3 : CR3_register; Address_Breakdown : in out Virtual_Address_Break) is
      Address : Virtual_Address := From_Virtual_Address_Break (Address_Breakdown);
   begin
      Next (CR3, Address);
      Address_Breakdown := To_Virtual_Address_Break (Address);
   end Next;


   function Is_Usermode (CR3 : CR3_Register; Address : Virtual_Address_Break) return Boolean is
      result : Boolean := True;
   begin
      result := result and then Get_PML4_Entry (CR3, Address).Is_Usermode;
      if Get_PML4_Entry (CR3, Address).Page_Size then
         return result;
      end if;

      result := result and then Get_PML3_Entry (CR3, Address).Is_Usermode;
      if Get_PML3_Entry (CR3, Address).Page_Size then
         return result;
      end if;

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
      result := result and then Get_PML4_Entry (CR3, Address).Is_Writable;
      if Get_PML4_Entry (CR3, Address).Page_Size then
         return result;
      end if;

      result := result and then Get_PML3_Entry (CR3, Address).Is_Writable;
      if Get_PML3_Entry (CR3, Address).Page_Size then
         return result;
      end if;

      result := result and then Get_PML2_Entry (CR3, Address).Is_Writable;
      if Get_PML2_Entry (CR3, Address).Page_Size then
         return result;
      end if;

      result := result and then Get_PML1_Entry (CR3, Address).Is_Writable;
      return result;
   end Is_Writable;

   function Compute_Next_Page (CR3 : CR3_Register; Current_Address : Virtual_Address_Break) return Page_Count is
   begin
      if (not Get_PML4_Entry (CR3, Current_Address).Present) or else
         (Get_PML4_Entry (CR3, Current_Address).Page_Size)
      then
         return Page_Per_PML3;
      end if;

      if (not Get_PML3_Entry (CR3, Current_Address).Present) or else
         (Get_PML3_Entry (CR3, Current_Address).Page_Size)
      then
         return Page_Per_PML2;
      end if;

      if (not Get_PML2_Entry (CR3, Current_Address).Present) or else
         (Get_PML2_Entry (CR3, Current_Address).Page_Size)
      then
         return Page_Per_PML1;
      end if;

      return 1;
   end Compute_Next_Page;

   function Get_Page_Number (Address : Virtual_Address_Break) return Page_Count is
   begin
      return 
         (Page_Count (Address.PML4_Index) * Page_Per_PML3) + 
         (Page_Count (Address.PML3_Index) * Page_Per_PML2) + 
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

      function To_Hex is new Util.To_Hex (Storage_Count);
      function To_Hex is new Util.To_Hex (Virtual_Address);
      procedure Print (Region_End_Address : Virtual_Address) is
         Region_Start_Address : constant Virtual_Address := From_Virtual_Address_Break (Current_Region_Start);
      begin
         Logger.Log_Info (To_Hex (Storage_Count (Region_Start_Address), 16)      & " " &
                          To_Hex (Storage_Count (Region_End_Address), 16)        & " " &
                          To_Hex (Region_End_Address - Region_Start_Address, 16) & " " &
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

         if Get_Page_Number (Test_Address) = Page_Per_PML4 - 1                         or else
            Is_Usermode (CR3, Test_Address) /= Is_Usermode (CR3, Current_Region_Start) or else
            Is_Writable (CR3, Test_Address) /= Is_Writable (CR3, Current_Region_Start)
         then
            Print (From_Virtual_Address_Break (Test_Address));
            Current_Region_Start := Test_Address;
         end if;
      end Test;

   begin
      Logger.Log_Info ("Printing mapped memory for CR3: " & To_Hex (Storage_Count (CR3.Address)));
      while Current_Page < Page_Per_PML4 loop
         Address_Breakdown := To_Virtual_Address_Break (Virtual_Address (Storage_Count (Current_Page) * PAGE_SIZE));
         Test (Address_Breakdown);
         Current_Page := Current_Page + Compute_Next_Page (CR3, Address_Breakdown);
      end loop;
      Logger.Log_Info ("--");
   end Print_Mapped_Memory;

   procedure Print_PLM4 (CR3 : CR3_Register) is
      PML4 : Page_Map_Level_4_Access := Get_PML4 (CR3, Null_Address_Break);
      function To_Hex is new Util.To_Hex (Storage_Count);
   begin
      Logger.Log_Info ("Printing PML4 for CR3: " & To_Hex (Storage_Count (CR3.Address)));
      for Index in PML4'Range loop
         if PML4 (Index).Present then
            Logger.Log_Info ("PML4[" & Index'Image & "] = " & PML4 (Index)'Image);
         end if;
      end loop;
   end Print_PLM4;

   -------------------------
   -- Create_Page_Entries --
   -------------------------
  
   procedure Create_PLM4_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML4 : Page_Map_Level_4_Access := Get_PML4 (CR3);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      pragma Assert (PML4 /= null);
      pragma Assert (not PML4 (Destination.PML4_Index).Present);
      -- Reset_PML (To_PML3_Access (Page_To_Allocate));
      declare
         PML3 : Page_Map_Level_3_Access := To_PML3_Access (Page_To_Allocate);
      begin
         for I in PML3'Range loop
            PML3 (I) := (Present => False, others => <>);
         end loop;
      end;

      PML4 (Destination.PML4_Index).Present := True;
      PML4 (Destination.PML4_Index).Is_Writable := True;
      PML4 (Destination.PML4_Index).Is_Usermode := False;
      PML4 (Destination.PML4_Index).Write_Through := True;
      PML4 (Destination.PML4_Index).Cache_Disable := True;
      PML4 (Destination.PML4_Index).Accessed := False;
      PML4 (Destination.PML4_Index).Address := To_Page_Address (Page_To_Allocate);
   end Create_PLM4_Entry;

   procedure Create_PML3_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML3 : Page_Map_Level_3_Access := Get_PML3 (CR3, Destination);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      pragma Assert (PML3 /= null);
      pragma Assert (not PML3 (Destination.PML3_Index).Present);
      --  Init the Page Map Level 2
      declare
         PML2 : Page_Map_Level_2_Access := To_PML2_Access (Page_To_Allocate);
      begin
         for I in PML2'Range loop
            PML2 (I) := (Present => False, others => <>);
         end loop;
      end;

      PML3 (Destination.PML3_Index).Present := True;
      PML3 (Destination.PML3_Index).Is_Writable := True;
      PML3 (Destination.PML3_Index).Is_Usermode := True;
      PML3 (Destination.PML3_Index).Write_Through := True;
      PML3 (Destination.PML3_Index).Cache_Disable := True;
      PML3 (Destination.PML3_Index).Accessed := False;
      PML3 (Destination.PML3_Index).Address := To_Page_Address (Page_To_Allocate);
   end Create_PML3_Entry;

   procedure Create_PML2_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML2 : Page_Map_Level_2_Access := Get_PML2 (CR3, Destination);
      Page_To_Allocate : Physical_Address := Allocate_Page;
   begin
      pragma Assert (PML2 /= null);
      pragma Assert (not PML2 (Destination.PML2_Index).Present);

      --  Init the Page Map Level 1
      declare
         PML1 : Page_Map_Level_1_Access := To_PML1_Access (Page_To_Allocate);
      begin
         for I in PML1'Range loop
            PML1 (I) := (Present => False, others => <>);
         end loop;
      end;

      PML2 (Destination.PML2_Index).Present := True;
      PML2 (Destination.PML2_Index).Is_Writable := True;
      PML2 (Destination.PML2_Index).Is_Usermode := True;
      PML2 (Destination.PML2_Index).Write_Through := True;
      PML2 (Destination.PML2_Index).Cache_Disable := True;
      PML2 (Destination.PML2_Index).Accessed := False;
      PML2 (Destination.PML2_Index).Address := To_Page_Address (Page_To_Allocate);
   end Create_PML2_Entry;

   procedure Create_PML1_Entry (CR3 : CR3_register; Destination : Virtual_Address_Break)
   is
      PML1 : Page_Map_Level_1_Access := Get_PML1 (CR3, Destination);
   begin
      pragma Assert (PML1 /= null);
      pragma Assert (not PML1 (Destination.PML1_Index).Present);
      PML1 (Destination.PML1_Index).Present := False;
      PML1 (Destination.PML1_Index).Is_Writable := True;
      PML1 (Destination.PML1_Index).Is_Usermode := True;
      PML1 (Destination.PML1_Index).Write_Through := True;
      PML1 (Destination.PML1_Index).Cache_Disable := True;
      PML1 (Destination.PML1_Index).Accessed := False;
      PML1 (Destination.PML1_Index).Page_Size := False;
      PML1 (Destination.PML1_Index).Address := To_Page_Address (Physical_Address (0));
   end Create_PML1_Entry;


   procedure Duplicate_hhdm (Source_CR3, Dest_CR3 : CR3_Register)
   is
      Kernel_Start : Virtual_Address_Break := To_Virtual_Address_Break (Limine.Get_HHDM_Offset);

      Source_PML4 : Page_Map_Level_4_Access := Get_PML4 (Source_CR3);
      Dest_PML4 : Page_Map_Level_4_Access := Get_PML4 (Dest_CR3);
   begin
      pragma Assert (Kernel_Start.PML1_Index = 0);
      pragma Assert (Kernel_Start.PML2_Index = 0);
      pragma Assert (Kernel_Start.PML3_Index = 0);

      Logger.Log_Info ("Duplicating PML4 range: " & Kernel_Start.PML4_Index'Image & ".." & Page_Index'Last'Image);
      for Index in Kernel_Start.PML4_Index .. Page_Index'Last loop
         pragma Assert (not Dest_PML4 (Index).Present);
         Dest_PML4 (Index) := Source_PML4 (Index);
      end loop;
   end Duplicate_hhdm;

   procedure Invalidate_TLB_Address (Address : Virtual_Address)
   is
      Canonical_Address : constant System.Address := To_Address (Address);
   begin
         Asm ("invlpg %0" & LF, Inputs => System.Address'Asm_Input ("m", Canonical_Address), Volatile => True);
   end Invalidate_TLB_Address;
   
   procedure Create_Page_Entries
     (CR3 : CR3_Register;
      Destination : Virtual_Address_Break) is
   begin
      if not Get_PML4_Entry (CR3, Destination).Present then
         Create_PLM4_Entry (CR3, Destination);
      end if;
      pragma Assert (not Get_PML4_Entry (CR3, Destination).Page_Size);

      if not Get_PML3_Entry (CR3, Destination).Present then
         Create_PML3_Entry (CR3, Destination);
      end if;
      pragma Assert (not Get_PML3_Entry (CR3, Destination).Page_Size);

      if not Get_PML2_Entry (CR3, Destination).Present then
         Create_PML2_Entry (CR3, Destination);
      end if;
      pragma Assert (not Get_PML2_Entry (CR3, Destination).Page_Size);

      if not Get_PML1_Entry (CR3, Destination).Present then
         Create_PML1_Entry (CR3, Destination);
      else
         Logger.Log_Error ("Entry already exist in CR3: " & CR3'Image);
      end if;
      Invalidate_TLB_Address (From_Virtual_Address_Break (Destination));
   end Create_Page_Entries;

   function Get_Page_Size (CR3 : CR3_register; Address : Virtual_Address_Break) return Page_Type is
   begin
      if not Get_PML4_Entry (CR3, Address).Present then
         return Not_Mapped;
      end if;

      if not Get_PML3_Entry (CR3, Address).Present then 
         return Not_Mapped;
      end if;
      if Get_PML3_Entry (CR3, Address).Page_Size then
         return Page_1GB;
      end if;

      if not Get_PML2_Entry (CR3, Address).Present then
         return Not_Mapped;
      end if;
      if Get_PML2_Entry (CR3, Address).Page_Size then
         return Page_2MB;
      end if;

      if not Get_PML1_Entry (CR3, Address).Present then
         return Not_Mapped;
      end if;

      return Page_4KB;
   end Get_Page_Size;

   function Is_Mapped
      (CR3: CR3_Register; Address : Virtual_Address) return Boolean is (Get_Page_Size (CR3, To_Virtual_Address_Break (Address)) /= Not_Mapped);

   procedure Set_Entry_Address
     (CR3            : CR3_Register;
      Destination    : Virtual_Address_Break;
      Address_To_Map : Physical_Address)
   is
      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Destination);
      pragma Assert (not PML1_Entry.Present);
   begin
      if Is_Kernel_Address (Address_To_Map) then
         Logger.Log_Warning ("Trying to map a kernel address: " & To_Hex (Address_To_Map));
      end if;
      PML1_Entry.Present := True;
      PML1_Entry.Address := To_Page_Address (Address_To_Map);
      Invalidate_TLB_Address (From_Virtual_Address_Break (Destination));
   end Set_Entry_Address;

   procedure Set_Entry_Flags
     (CR3         : CR3_Register;
      Destination : Virtual_Address_Break;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False)
   is
      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Destination);
      PML2_Entry : Page_Map_Level_2_Entry_Access := Get_PML2_Entry (CR3, Destination);
      PML3_Entry : Page_Map_Level_3_Entry_Access := Get_PML3_Entry (CR3, Destination);
      PML4_Entry : Page_Map_Level_4_Entry_Access := Get_PML4_Entry (CR3, Destination);

      Page_Level : constant Entry_Level := Get_Entry_Level (CR3, Destination);
   begin
      if Page_Level <= Entry_Level_4 then
         PML4_Entry.Is_Writable := Is_Writable or PML4_Entry.Is_Writable;
         PML4_Entry.Is_Usermode := Is_Usermode or PML4_Entry.Is_Usermode;
      end if;

      if Page_Level <= Entry_Level_3 then
         PML3_Entry.Is_Writable := Is_Writable or PML3_Entry.Is_Writable;
         PML3_Entry.Is_Usermode := Is_Usermode or PML3_Entry.Is_Usermode;
      end if;

      if Page_Level <= Entry_Level_2 then
         PML2_Entry.Is_Writable := Is_Writable or PML2_Entry.Is_Writable;
         PML2_Entry.Is_Usermode := Is_Usermode or PML2_Entry.Is_Usermode;
      end if;

      PML1_Entry.Is_Writable := Is_Writable;
      PML1_Entry.Is_Usermode := Is_Usermode;

      pragma Assert (x86.vmm.Is_Usermode (CR3, Destination) = Is_Usermode);
      pragma Assert (x86.vmm.Is_Writable (CR3, Destination) = Is_Writable);
      Invalidate_TLB_Address (From_Virtual_Address_Break (Destination));
   end Set_Entry_Flags;

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
   begin
      Create_Page_Entries (Process, Address_Breakdown);
      Set_Entry_Address   (Process, Address_Breakdown, Address_To_Map);
      Set_Entry_Flags     (Process, Address_Breakdown, Is_Writable, Is_Usermode);
   end Map_Physical_Page;

   ----------------
   -- Unmap_Page --
   ----------------
   procedure Unmap_Page
     (CR3         : CR3_Register;
      Address     : Virtual_Address;
      Free_Page   : Boolean)
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      PML1_Entry : Page_Map_Level_1_Entry_Access := Get_PML1_Entry (CR3, Address_Breakdown);
   begin
      if Get_PML4_Entry (CR3, Address_Breakdown).Page_Size then
         raise Program_Error with "Cannot unmap PML4 entry";
      end if;

      if Get_PML3_Entry (CR3, Address_Breakdown).Page_Size then
         raise Program_Error with "Cannot unmap PML3 entry";
      end if;

      if Get_PML2_Entry (CR3, Address_Breakdown).Page_Size then
         raise Program_Error with "Cannot unmap PML2 entry";
      end if;

      if not PML1_Entry.Present then
         raise Program_Error with "PML1 entry not present";
      end if;

      if Free_Page then
         PMM.Free_Page (To_Address (PML1_Entry.Address));
      end if;
      PML1_Entry.Present := False;
      Invalidate_TLB_Address (Address);      
   end Unmap_Page;

   ---------------------------------
   -- Virtual_To_Physical_Address --
   ---------------------------------
   function Virtual_To_Physical_Address
     (CR3 : CR3_register; Address : Virtual_Address) return Physical_Address
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
   begin
      if not Is_Mapped (CR3, Address) then
         return Physical_Address'First;
      end if;

      if Get_PML4_Entry (CR3, Address_Breakdown).Page_Size then
         return Physical_Address'First;
      end if;

      if Get_PML3_Entry (CR3, Address_Breakdown).Page_Size then
         return To_Address (Get_PML3_Entry (CR3, Address_Breakdown).Address) +
                To_Virtual_Address_Break_1GB (Address).Offset;
      end if;

      if Get_PML2_Entry (CR3, Address_Breakdown).Page_Size then
         return To_Address (Get_PML2_Entry (CR3, Address_Breakdown).Address_2MB) + 
                To_Virtual_Address_Break_2MB (Address).Offset;
      end if;

      pragma Assert (Get_PML1_Entry (CR3, Address_Breakdown).Present);
      return To_Address (Get_PML1_Entry (CR3, Address_Breakdown).Address) + Address_Breakdown.Offset;
   end Virtual_To_Physical_Address;

   ----------------
   -- Get_Offset --
   ----------------
   function Get_Offset (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Offset
   is
      Page_Size : Page_Type := Get_Page_Size (CR3, To_Virtual_Address_Break (Address));
   begin
      case Page_Size is
         when Page_1GB =>
            return To_Virtual_Address_Break_1GB (Address).Offset;
         when Page_2MB =>
            return To_Virtual_Address_Break_2MB (Address).Offset;
         when Page_4KB | Not_Mapped =>
            return To_Virtual_Address_Break (Address).Offset;
      end case;
   end Get_Offset;

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
      pragma Assert (Start_Address < End_Address);
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
   begin
      null;
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
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      To_Fit : Storage_Count := Data_Size;
   begin
      if not Can_Fit (CR3, Address, Data_Size) then
         Logger.Log_Error ("Cannot fit " & Data_Size'Image & " at " & Address'Image);
         return False;
      end if;

      while To_Fit > 0 loop
         Create_Page_Entries (CR3, Address_Breakdown);

         Set_Entry_Address (CR3, Address_Breakdown, Allocate_Page);
         Set_Entry_Flags (CR3, Address_Breakdown, Is_Writable, Is_Usermode);


         To_Fit := To_Fit - Storage_Count'Min (To_Fit, PMM_PAGE_SIZE);
         Address_Breakdown.Offset := 0;
         Next (CR3, Address_Breakdown);
      end loop;

      return True;
   end Alloc;


   ---------------------
   -- Is_Last_Address --
   ---------------------
   function Is_Last_Address (CR3 : CR3_Register; Address : Virtual_Address) return Boolean is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      PML2_Entry : Page_Map_Level_2_Entry_Access := Get_PML2_Entry (CR3, Address_Breakdown);
      PML3_Entry : Page_Map_Level_3_Entry_Access := Get_PML3_Entry (CR3, Address_Breakdown);
      PML4_Entry : Page_Map_Level_4_Entry_Access := Get_PML4_Entry (CR3, Address_Breakdown);
   begin
      if Address_Breakdown.PML4_Index /= Page_Index'Last then
         return False;
      end if;

      if Address_Breakdown.PML3_Index /= Page_Index'Last then
         return False;
      end if;
      if PML3_Entry.Page_Size then
         return True;
      end if;

      if Address_Breakdown.PML2_Index /= Page_Index'Last then
         return False;
      end if;
      if PML2_Entry.Page_Size then
         return True;
      end if;

      return Address_Breakdown.PML1_Index = Page_Index'Last;
   end Is_Last_Address;

end x86.vmm;
