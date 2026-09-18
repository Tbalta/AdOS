with Ada.Strings.Text_Buffers.Unbounded;
with Interfaces.C;
with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Ada.Assertions;
--  with System.Secondary_Stack;
with Loggers;
with x86.vmm;
with Util;
with Loggers;
package body x86.vmm is
   use Standard.ASCII;


   function To_Hex is new Util.To_Hex (Physical_Address);
   pragma Assertion_Policy (Assert => Check);
   package Logger renames Loggers;

   function To_Canonical_Address (Address : Virtual_Address) return Virtual_Address is
   begin
      if Address >= 16#8000_0000_0000# then
         return Address or 16#FFFF_0000_0000_0000#;
      end if;

      return Address;
   end To_Canonical_Address;

   function From_Canonical_Address (Address : Virtual_Address) return Virtual_Address is
   begin
      return Address and 16#FFFF_FFFF_FFFF#;
   end From_Canonical_Address;

   function Is_Canonical_Address (Address : Virtual_Address) return Boolean is
   begin
      return Address = To_Canonical_Address (Address);
   end Is_Canonical_Address;


   function Is_Physical_Address (Address : Physical_Address) return Boolean is
      use Limine;
   begin
      return Storage_Offset (Address) < hhdm_response.offset;
   end Is_Physical_Address;

   function Is_Virtual_Address (Address : Virtual_Address) return Boolean is
      use Limine;
   begin
      return Storage_Offset (To_Address (Address)) >= hhdm_response.offset;
   end Is_Virtual_Address;

   function To_Virtual_Address (Address : Physical_Address) return Virtual_Address is
      use Limine;
      function To_Hex is new Util.To_Hex(Physical_Address);
   begin
      if not Is_Physical_Address (Address) then
         pragma Assert (Is_Physical_Address (Address) = False);
         Logger.Log_Error (To_Hex (Address) & " is not a valid Physical Address");
         pragma Assert (Is_Physical_Address (Address) = False, "Internal Error: Invalid Physical Address");
      end if;
      
      return Virtual_Address (Address + hhdm_response.offset);
   end To_Virtual_Address;

   function To_Physical_Address (Address : Virtual_Address) return Physical_Address is
      use Limine;
      function To_Hex is new Util.To_Hex(Virtual_Address);
   begin
      if not Is_Virtual_Address (Address) then
         Logger.Log_Error (To_Hex (Address) & " is not a valid virtual address");
      end if;
      pragma Assert (Is_Virtual_Address (Address));
      return Physical_Address (Address - Limine.Get_HHDM_Offset);
   end To_Physical_Address;

   ----------------
   -- To_Address --
   ----------------
   function To_Address (Addr : Page_Address) return Physical_Address is (Physical_Address (Storage_Count (Integer_Address (Addr)) * PAGE_SIZE));
   function To_Address (Addr : Page_Address_2MB)  return Physical_Address is (Physical_Address (Storage_Count (Integer_Address (Addr)) * PAGE_SIZE_2MB));


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
      return To_PML1_Access(To_Address (PML2 (Address.PML2_Index).PML1_Address));
   end Get_PML1;


   function Get_PML_Entry (CR3 : CR3_Register; Address : Virtual_Address_Break) return Page_Map_Level_Entry_Access is
      PML : Page_Map_Level_Access := Get_PML (CR3, Address);
   begin
      if PML = null then
         return null;
      end if;
      return PML (Get_Entry_Index (Address))'Access;
   end Get_PML_Entry;

   function Get_PML4_Entry is new Get_PML_Entry (
      Page_Map_Level_Entry => Page_Map_Level_4_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_4_Entry_Access,
      Page_Map_Level => Page_Map_Level_4,
      Page_Map_Level_Access => Page_Map_Level_4_Access,
      Get_Entry_Index =>  Get_PML4_Index,
      Get_PML => Get_PML4);
   function Get_PML3_Entry is new Get_PML_Entry (
      Page_Map_Level_Entry => Page_Map_Level_3_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_3_Entry_Access,
      Page_Map_Level => Page_Map_Level_3,
      Page_Map_Level_Access => Page_Map_Level_3_Access,
      Get_Entry_Index =>  Get_PML3_Index,
      Get_PML => Get_PML3);
   function Get_PML2_Entry is new Get_PML_Entry (
      Page_Map_Level_Entry => Page_Map_Level_2_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_2_Entry_Access,
      Page_Map_Level => Page_Map_Level_2,
      Page_Map_Level_Access => Page_Map_Level_2_Access,
      Get_Entry_Index =>  Get_PML2_Index,
      Get_PML => Get_PML2);
   function Get_PML1_Entry is new Get_PML_Entry (
      Page_Map_Level_Entry => Page_Map_Level_1_Entry,
      Page_Map_Level_Entry_Access => Page_Map_Level_1_Entry_Access,
      Page_Map_Level => Page_Map_Level_1,
      Page_Map_Level_Access => Page_Map_Level_1_Access,
      Get_Entry_Index =>  Get_PML1_Index,
      Get_PML => Get_PML1);

   -------------------------
   -- Get_Number_Of_Pages --
   -------------------------
   function Get_Number_Of_Pages (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive
   is begin
      if (Size + Storage_Count (PAGE_SIZE - 1 + Offset)) / PAGE_SIZE <= 0 then
         Logger.Log_Error(Size'Image & ", " & Offset'Image);
      end if;

    return (Positive ((Size + Storage_Count (PAGE_SIZE - 1 + Offset)) / PAGE_SIZE));
   end Get_Number_Of_Pages;



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
      Address.Offset := 0;
   end Next;

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
         if not Is_Mapped (CR3, Current_Region_Start) then
            Current_Region_Start := Test_Address;
            return;
         end if;

         if not Is_Mapped (CR3, Test_Address) then
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
   ----------------
   -- Create_CR3 --
   ----------------
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
      declare
         PML3 : Page_Map_Level_3_Access := To_PML3_Access (Page_To_Allocate);
      begin
         PML3.all := Page_Map_Level_3'(others => (Present => False, others => <>));
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
         PML2.all := Page_Map_Level_2'(others => (Present => False, others => <>));
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
         PML1.all := Page_Map_Level_1'(others => (Present => False, others => <>));
      end;

      PML2 (Destination.PML2_Index).Present := True;
      PML2 (Destination.PML2_Index).Is_Writable := True;
      PML2 (Destination.PML2_Index).Is_Usermode := True;
      PML2 (Destination.PML2_Index).Write_Through := True;
      PML2 (Destination.PML2_Index).Cache_Disable := True;
      PML2 (Destination.PML2_Index).Accessed := False;
      PML2 (Destination.PML2_Index).PML1_Address := To_Page_Address (Page_To_Allocate);
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
     (CR3: CR3_Register; Destination : Virtual_Address_Break) return Boolean is (Get_Page_Size (CR3, Destination) /= Not_Mapped);

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
      if Get_PML4_Entry (CR3, Destination).Page_Size then
         raise Program_Error with "Cannot unmap PML4 entry";
      end if;

      if Get_PML3_Entry (CR3, Destination).Page_Size then
         raise Program_Error with "Cannot unmap PML3 entry";
      end if;

      if Get_PML2_Entry (CR3, Destination).Page_Size then
         raise Program_Error with "Cannot unmap PML2 entry";
      end if;

      if not PML1_Entry.Present then
         raise Program_Error with "PML1 entry not present";
      end if;

      if Free_Page then
         PMM.Free_Page (To_Address (PML1_Entry.Address));
      end if;
      PML1_Entry.Present := False;
      Invalidate_TLB_Address (From_Virtual_Address_Break (Destination));      
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
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;
      
      -- TODO: This is for VGA, need to be cleaned
      -- Map_Range (CR3 => CR3, Destination => To_Virtual_Address_Break (System.Address (16#A0000#)), Start_Address => Physical_Address (16#A0000#), End_Address => Physical_Address (16#C0000#), Is_Writable => True, Is_Usermode => True);

      -- Identity map the kernel
      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Identity_Map;

   -------------
   -- Can_Fit --
   -------------


   function Get_Free_Space
     (CR3 : CR3_register; Address : Virtual_Address) return Storage_Count
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      level : Entry_Level := Get_Entry_Level (CR3, Address_Breakdown);
   begin
      case level is
         when Entry_Level_4 =>
            return PAGE_SIZE - Address_Breakdown.Offset;
         when Entry_Level_3 =>
            if Get_PML3_Entry (CR3, Address_Breakdown).Present then
               return 0;
            else
               return PAGE_SIZE_1GB - Storage_Count (To_Virtual_Address_Break_1GB (Address).Offset);
            end if;
         when Entry_Level_2 =>
            if Get_PML2_Entry (CR3, Address_Breakdown).Present then
               return 0;
            else
               return PAGE_SIZE_2MB - Storage_Count (To_Virtual_Address_Break_2MB (Address).Offset);
            end if;
         when Entry_Level_1 =>
            if Get_PML1_Entry (CR3, Address_Breakdown).Present then
               return 0;
            else
               return PAGE_SIZE - Address_Breakdown.Offset;
            end if;
      end case;
   end Get_Free_Space;


   function Can_Fit
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address  - Get_Offset (CR3, Address));
      Free_Space : Storage_Count := 0;
   begin
      pragma Assert (Address_Breakdown.Offset = 0);

      -- TODO: review end condition
      while From_Virtual_Address_Break (Address_Breakdown) /= Virtual_Address'Last loop
         exit when Is_Mapped (CR3, Address_Breakdown);
         exit when Free_Space >= Size;

         Free_Space := Free_Space + Get_Free_Space (CR3, From_Virtual_Address_Break (Address_Breakdown));
         Next (CR3, Address_Breakdown);
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
   -- Is_Range_Mapped --
   ---------------------
   function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      Number_Of_Pages : Natural := Get_Number_Of_Pages (Size, Get_Offset (CR3, Address));
      function To_Hex is new Util.To_Hex (Storage_Count);
   begin
      for Index in 1 .. Number_Of_Pages loop
         if not Is_Mapped (CR3, Address_Breakdown) then
            Logger.Log_Error ("Not mapped " & From_Virtual_Address_Break (Address_Breakdown)'Image);
            return False;
         end if;
         Next (Address_Breakdown);
      end loop;

      -- Logger.Log_Debug (To_Hex (Storage_Count (Address)) & " - " & To_Hex (Storage_Count (Address + Size)) & " is mapped");
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
     (CR3 : CR3_register; Size : Storage_Count; Start : Virtual_Address) return Virtual_Address
   is
      Breakdown      : Virtual_Address_Break := To_Virtual_Address_Break (Start);
   begin
      if Breakdown = To_Virtual_Address_Break (Virtual_Address'First) then
         Next (Breakdown);
      end if;

      for Page in Get_Page_Number (Breakdown) .. Page_Per_PML4 - 1 loop
         if Can_Fit (CR3, From_Virtual_Address_Break (Breakdown), Size) then
            return From_Virtual_Address_Break (Breakdown);
         end if;

         Next (Breakdown);
      end loop;

      return Virtual_Address'First;
   end;


   function Size_Of_Entry (CR3 : CR3_register; Address : Virtual_Address) return Storage_Count is
      Size : constant Page_Type := Get_Page_Size (CR3, To_Virtual_Address_Break (Address));
   begin
      case Size is
         when Page_1GB =>
            return PAGE_SIZE_1GB;
         when Page_2MB =>
            return PAGE_SIZE_2MB;
         when Page_4KB =>
            return PAGE_SIZE;
         when Not_Mapped =>
            return 0;
         when others =>
            Logger.Log_Error ("Size_Of_Entry: invalid page size for address " & Address'Image);
            return 0;
      end case;

   end Size_Of_Entry;

   function Get_Next_Entry (CR3 : CR3_register; Address : Virtual_Address) return Virtual_Address is
      Level : Entry_Level := Get_Entry_Level (CR3, To_Virtual_Address_Break (Address));
   begin
      case Level is
         when Entry_Level_4 =>
            Logger.Log_Error ("Get_Next_Entry: invalid map level for address " & Address'Image);
            return Virtual_Address'First;
         when Entry_Level_3 =>
            return Address + PAGE_SIZE_1GB;
         when Entry_Level_2 =>
            return Address + PAGE_SIZE_2MB;
         when Entry_Level_1 =>
            return Address + PAGE_SIZE;
      end case;
   end Get_Next_Entry;



   function Compute_Number_Of_Mapped_PLM_Entries (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Natural
   is
      Current_Size : Storage_Count := 0;
      Current_Address : Virtual_Address := Address;
      Current_Entry_Size : Storage_Count := 0;
      Number_Of_Entries : Natural := 0;
   begin
      while Current_Size < Size loop
         Current_Entry_Size := Size_Of_Entry (CR3, Current_Address);

         if Current_Entry_Size = 0 then
            Logger.Log_Error ("Compute_Number_Of_Mapped_PLM_Entries: Address " & Current_Address'Image & " is not mapped");
            return 0;
         end if;
         Current_Size := Current_Size + Current_Entry_Size;
         Current_Address := Current_Address + Current_Entry_Size;
         Number_Of_Entries := Number_Of_Entries + 1;
      end loop;

      return Number_Of_Entries;
   end Compute_Number_Of_Mapped_PLM_Entries;

   ----------------------------
   -- Process_To_Process_Map --
   ----------------------------
   function Process_To_Process_Map
     (Source_CR3     : CR3_register;
      Source_Address : Virtual_Address;
      Dest_CR3       : CR3_register;
      Size           : Storage_Count;
      Hint           : Virtual_Address := Virtual_Address'First) return Virtual_Address
   is
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
      Offset_In_Page          : constant Virtual_Address_Offset := To_Virtual_Address_Break (Source_Address).Offset;
      Page_Count              : constant Positive := Get_Number_Of_Pages (Size, Offset_In_Page);
      Aligned_Source_Address   : constant Virtual_Address := Source_Address - Offset_In_Page;

      Return_Address        : Virtual_Address;
      Dest_Address          : Virtual_Address_Break;

      --------------------------
      -- Compute_Dest_Address --
      --------------------------
      function Compute_Dest_Address return Virtual_Address_Break is
         begin
         if Hint /= Virtual_Address'First then
            return  To_Virtual_Address_Break (Hint);
         else
           return To_Virtual_Address_Break (Find_Next_Space (Dest_CR3, Size + Storage_Count (Offset_In_Page), Virtual_Address'First));
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

      if not Is_Range_Mapped (Source_CR3, Aligned_Source_Address, Size) then
         Logger.Log_Error ("Address is not mapped");
         Re_Enable_Paging_If_Needed;
         return Virtual_Address'First;
      end if;

      Dest_Address := Compute_Dest_Address;
      if Dest_Address = Null_Address_Break or else not Can_Fit (Dest_CR3, From_Virtual_Address_Break (Dest_Address), Size) then
         Logger.Log_Error ("Map_Process_Memory: Could not find space in destination process");
         Re_Enable_Paging_If_Needed;
         return Virtual_Address'First;
      end if;
      
      Return_Address := From_Virtual_Address_Break (Dest_Address) + Offset_In_Page;
      for i in 0 .. Page_Count - 1 loop
         Map_Physical_Page (
            Process => Dest_CR3,
            Destination => Dest_Address,
            Address_To_Map => Virtual_To_Physical_Address (Source_CR3, Aligned_Source_Address + Storage_Count (i * Positive (PMM_PAGE_SIZE))),
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
      Page_Count        : constant Positive := Get_Number_Of_Pages (size, Address_Breakdown.Offset);
   
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


   function Alloc_In_Range
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Range_Start, Range_End : Virtual_Address;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address
   is
      Paging_Currently_Enabled : constant Boolean := Paging_Enabled;
      Result : Virtual_Address := Virtual_Address'First;
      Success : Boolean := True;

      function To_Hex is new Util.To_Hex (Virtual_Address);
   begin
      Logger.Log_Debug ("Alloc_In_Range: Allocating" & Size'Image & " bytes");
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      Result := Find_Next_Space (CR3, Size, Range_Start);
      if Result = Virtual_Address'First or else
         Result + Size > Range_End
      then
         Logger.Log_Error ("No more free space in the Page Directory");
         Success := False;
      end if;

      Logger.Log_Debug ("  at " &  To_Hex (Result));

      if Success and then not Alloc
               (CR3,
                Result,
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
         Logger.Log_Ok ("  Allocation successfull");
         return Result;
      end if; 

      Logger.Log_Error ("  Allocation failed");

      return Virtual_Address'First;
   end Alloc_In_Range;

end x86.vmm;
