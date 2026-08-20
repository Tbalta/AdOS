------------------------------------------------------------------------------
--                                 X86.PMM                                  --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with Limine;
with SERIAL;
with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;
with Aligned_System_Address;
with config;                  use config;
with Loggers;
with Util;
with x86.vmm;
package body x86.pmm is
   package Logger renames Loggers;

   function check (cond : Boolean; msg : String) return Boolean is
   begin
      if (not cond) then
         Logger.Log_Error ("PMM: " & msg);
      end if;
      return cond;
   end check;

   ------------------------------
   -- Physical_Address Utility --
   ------------------------------
   function To_Integer (Value : Physical_Address) return Integer_Address is
   begin
      return Integer_Address (Value);
   end To_Integer;

   function To_Address (Value : Physical_Address) return System.Address is
   begin
      return System.Address (Value);
   end To_Address;

   -----------------------
   -- Address_To_Offset --
   -----------------------
   function Address_To_Offset (addr : Virtual_Address) return Natural
   is (Address_To_Offset_Unchecked (x86.vmm.To_Physical_Address (addr)));

   function Address_To_Offset (addr : Physical_Address) return Natural
   is (Address_To_Offset_Unchecked (addr));

   function Address_To_Offset_Unchecked (addr : Physical_Address) return Natural is
      use all type System.Address;
      Offset : Natural := 1;
      function Round_64 is new Standard.Util.Round (Unsigned_64);
   begin
      -- Logger.Log_Info ("Address_To_Offset_Unchecked - looking for " & addr'Image);
      --  Logger.Log_Info ("Max offset: " & Storage_Offset'Last'Image & " " & Standard'Address_Size'Image);
      for Index in PMM_Info_Ptr.Headers'Range loop
         declare
            Start_Address : constant Physical_Address := PMM_Info_Ptr.Headers (Index).base_addr;
            End_Address : constant Physical_Address := PMM_Info_Ptr.Headers (Index).base_addr + Storage_Offset (PMM_Info_Ptr.Headers (Index).length) - 1;
         begin
            if addr in Start_Address .. End_Address then
               return Offset + Natural (Storage_Count (addr - PMM_Info_Ptr.Headers (Index).base_addr) / PMM_PAGE_SIZE);
            end if;
            Offset := Offset + Natural (Round_64 (PMM_Info_Ptr.Headers (Index).length, Unsigned_64 (PMM_PAGE_SIZE)) / Unsigned_64 (PMM_PAGE_SIZE));
         end;
      end loop;
      Logger.Log_Error ("Address_To_Offset_Unchecked - unable to find Index for " & addr'Image);
      raise Constraint_Error;
   end Address_To_Offset_Unchecked;

   -----------------------
   -- Offset_To_Address --
   -----------------------
   function Offset_To_Address_Unchecked (paroffset : Natural) return Physical_Address is
      Offset : Natural := paroffset;
      function Round_64 is new Standard.Util.Round (Unsigned_64);
   begin
      for Index in PMM_Info_Ptr.Headers'Range loop
         if Offset <= Positive (Round_64 (PMM_Info_Ptr.Headers (Index).length, Unsigned_64 (PMM_PAGE_SIZE)) / Unsigned_64 (PMM_PAGE_SIZE)) then
            return
              Physical_Address
                (PMM_Info_Ptr.Headers (Index).base_addr + 
                (Storage_Count (Offset - 1) * PMM_PAGE_SIZE));
         else
            Offset := Offset - Positive (Round_64 (PMM_Info_Ptr.Headers (Index).length, Unsigned_64 (PMM_PAGE_SIZE))  / Unsigned_64 (PMM_PAGE_SIZE));
         end if;
      end loop;

      Logger.Log_Error ("Offset not found: " & paroffset'Image);
      raise Storage_Error;
      return Physical_Address (0);
   end Offset_To_Address_Unchecked;

   function Offset_To_Address (paroffset : Natural) return Physical_Address
   is (Offset_To_Address_Unchecked (paroffset));

   function Is_System_Address (addr : Physical_Address) return Boolean
      is (addr < Physical_Address ((Storage_Count (Get_Pmm_End_Address + PMM_PAGE_SIZE - Storage_Count (1)) / PMM_PAGE_SIZE) * PMM_PAGE_SIZE));

   function Get_Next_Free_Page return Natural is
      use all type System.Address;
      pragma Assert (PMM_Header_Address /= System.Null_Address, "PMM Bitmap not initialized.");
   begin
      --  pragma Assert (not x86.vmm.Is_Paging_Enabled);
      for Index in PMM_Info_Ptr.Bitmap'Range loop
         if PMM_Info_Ptr.Bitmap (Index) = PMM_Bitmap_Entry_Free then
            return Index;
         end if;
      end loop;
      Logger.Log_Error ("PMM: Out of memory !");
      raise Storage_Error;
   end Get_Next_Free_Page;

   function Allocate_Page return Physical_Address is
      Offset : Natural := Get_Next_Free_Page;
      Result : Physical_Address;
   begin
      Result := Offset_To_Address (Offset);
      if Is_System_Address (Result) then
         Logger.Log_Error ("Allocating System_Address " & Result'Image & " at offset " & Offset'Image);
         Logger.Log_Error ("Remaining PMM entry: " & Number_Of_Remaining_Pages'Image);
         raise Program_Error;
      end if;
      PMM_Info_Ptr.Bitmap (Offset) := PMM_Bitmap_Entry_Used;
      Number_Of_Remaining_Pages := Number_Of_Remaining_Pages - 1;
      --  Logger.Log_Info (PMM_Header_Address'Image);
      --  Logger.Log_Info
      --    ("PMM: Allocated page at " & To_Address (Result)'Image & " with offset " & Offset'Image & " | " & Util.Bitmap (Offset)'Address'Image);
      return Result;
   end Allocate_Page;

   procedure Free_Page (addr : Physical_Address) is
      Offset : Natural := Address_To_Offset (addr);
   begin
      if Is_System_Address (addr) then
         Logger.Log_Error ("Freeing System_Address " & addr'Image & " at offset " & Offset'Image);
         raise Program_Error;
      end if;
      
      if Offset = -1 then
         return;
      end if;
      PMM_Info_Ptr.Bitmap (Offset) := PMM_Bitmap_Entry_Free;
      Number_Of_Remaining_Pages := Number_Of_Remaining_Pages + 1;
   end Free_Page;

   procedure Init (Mem_Map : Mem_Map_Response) is
      package ASA is new Aligned_System_Address (PMM_PAGE_SIZE);
      use ASA;

      pmmEntryCount     : Natural := 0;
      pmmHeaderCount    : Integer := 0;
      firstValidAddress : Unsigned_32 := 0;
      
      function Round_64 is new Standard.Util.Round (Unsigned_64);
      function To_Hex is new Util.To_Hex (Unsigned_64);
   begin   
      --  First step:
      --    Number of pmm entries.
      --    Number of pmm headers.
      for Index in 1 .. Mem_Map.Entry_Map_Count loop
         --  Logger.Log_Info ("MB Entry: " & Mem_Map.entry_map.all (Index).all'Image);
         if Mem_Map.entry_map.all (Index).flags = Limine.LIMINE_MEMMAP_USABLE then
            Logger.Log_Info
              ("Found available memory at "
               & Mem_Map.entry_map.all (Index).base'Image
               & " of size "
               & To_Hex (Mem_Map.entry_map.all (Index).length));
            pmmEntryCount := pmmEntryCount + Positive (Round_64 (Mem_Map.entry_map.all (Index).length, Unsigned_64 (PMM_PAGE_SIZE)) / Unsigned_64 (PMM_PAGE_SIZE));
            pmmHeaderCount := pmmHeaderCount + 1;
         end if;
      end loop;

      Logger.Log_Info ("Found " & pmmEntryCount'Image & " PMM entries.");
      Logger.Log_Info ("Found " & pmmHeaderCount'Image & " PMM headers.");

      -- Second step:
      --   Searching pmm start
      Logger.Log_Info ("Setting pmm header.");
      declare
         subtype Current_PMM_Header is PMM_Info (Header_Count => pmmHeaderCount, Bitmap_Length => pmmEntryCount);
         Storage_Size_Needed : constant Storage_Count := Storage_Count ((Current_PMM_Header'Size + 7) / 8);

         package PMM_Header_Conv is new System.Address_To_Access_Conversions (PMM_Info);
         package PMM_Info_Settings_Conv is new System.Address_To_Access_Conversions (PMM_Info_Settings);

         Mem_Map_Address : System.Address := System.Null_Address;
         PMM_Settings_Ptr : access PMM_Info_Settings := null;
      begin
         for Index in 1 .. Mem_Map.Entry_Map_Count loop
            if Mem_Map.entry_map.all (Index).flags = Limine.LIMINE_MEMMAP_USABLE and 
               Mem_Map.entry_map.all (Index).length > Unsigned_64 (Storage_Size_Needed)
            then
               Mem_Map_Address := x86.vmm.To_Virtual_Address (Mem_Map.entry_map.all (Index).base);
               Logger.Log_Info
                 ("PMM structures will be stored at "
                  & Mem_Map_Address'Image
                  & " from physical address "
                  & Mem_Map.entry_map.all (Index).base'Image);
               PMM_Info_Settings_Conv.To_Pointer (Mem_Map_Address).all :=
                 PMM_Info_Settings'
                   (Header_Count => pmmHeaderCount,
                    Bitmap_Length => pmmEntryCount);

               PMM_Info_Ptr := PMM_Header_Conv.To_Pointer (Mem_Map_Address).all'Unchecked_Access;
               exit when PMM_Info_Ptr /= null;
            end if;
         end loop;
      end;

      if PMM_Info_Ptr = null then
         Logger.Log_Error ("No suitable memory region found for PMM structures.");
         raise Program_Error;
      end if;
      Logger.Log_Info ("PMM Stored at: " & PMM_Info_Ptr'Image);
      Logger.Log_Info ("PMM Header_Count: " & PMM_Info_Ptr.Header_Count'Image);
      Logger.Log_Info ("PMM Bitmap_Length: " & PMM_Info_Ptr.Bitmap_Length'Image);
      -- Third step:
      --   Filling headers + bitmap allocation.
      declare
         PMM_Header_IDX : Positive := 1;
      begin
         for Index in 1 .. Mem_Map.Entry_Map_Count loop
            if Mem_Map.entry_map.all (Index).flags = Limine.LIMINE_MEMMAP_USABLE then
               Logger.Log_Info ("setting header: " & PMM_Header_IDX'Image);
               PMM_Info_Ptr.Headers (PMM_Header_IDX).length := Unsigned_64 (Mem_Map.entry_map.all (Index).length);
               PMM_Info_Ptr.Headers (PMM_Header_IDX).base_addr := Mem_Map.entry_map.all (Index).base;
               PMM_Header_IDX := PMM_Header_IDX + 1;
            end if;
         end loop;
         Number_Of_Remaining_Pages := pmmEntryCount;

         for Index in PMM_Info_Ptr.all.Bitmap'Range loop
            PMM_Info_Ptr.Bitmap (Index) := PMM_Bitmap_Entry_Free;
         end loop;
      end;

      -- Fourth step:
      --   Masking already used memory.
      declare
         PMM_Start : Virtual_Address  := PMM_Info_Ptr.all'Address;
         PMM_End   : Virtual_Address :=  PMM_Start + Virtual_Address ((PMM_Info_Ptr.all'Size + 7) / 8);
      begin
         Logger.Log_Info ("Masking " & x86.vmm.To_Physical_Address (PMM_Start)'Image & " .. " & x86.vmm.To_Physical_Address (PMM_End)'Image);
         Logger.Log_Info ("Masking " & Address_To_Offset (x86.vmm.To_Physical_Address (PMM_Start))'Image & " .. " & Address_To_Offset (x86.vmm.To_Physical_Address (PMM_End))'Image);
         PMM_Info_Ptr.Bitmap (Address_To_Offset (x86.vmm.To_Physical_Address (PMM_Start)) .. Address_To_Offset (x86.vmm.To_Physical_Address (PMM_End))) := (others => PMM_Bitmap_Entry_Used);
      end;
   end Init;

   procedure Print_PMM_Info is

      function To_Hex is new Util.To_Hex(Physical_Address);
      function To_Hex is new Util.To_Hex(Storage_Count);

      procedure Print_Region (First_Index, Last_Index : Natural) is
         Start_Address : Physical_Address := Offset_To_Address (First_Index);
         End_Address : Physical_Address := Offset_To_Address (Last_Index);
         To_Hex_Size  : Natural := Physical_Address'Size / 4;

      begin
         Logger.Log_Info ("   " & To_Hex (Start_Address, To_Hex_Size) & " " & To_Hex (End_Address, To_Hex_Size) & " " & PMM_Info_Ptr.Bitmap (First_Index)'Image & " " & First_Index'Image & ".." & Last_Index'Image);
      end Print_Region;

      Total_Free : Natural := 0;
      Total_Used : Natural := 0;
   begin
      Logger.Log_Info ("PMM Info:");
      for Region in PMM_Info_Ptr.Headers'Range loop
         declare
            First_Index : Natural := Address_To_Offset (PMM_Info_Ptr.Headers (Region).base_addr);
            Last_Index : Natural := Address_To_Offset (PMM_Info_Ptr.Headers (Region).base_addr + Storage_Count (PMM_Info_Ptr.Headers (Region).length) - 1);
            Current_Index : Natural := First_Index;
         begin
            for Index in (Current_Index + 1) .. Last_Index loop
               if PMM_Info_Ptr.Bitmap (Index) /= PMM_Info_Ptr.Bitmap (Current_Index) then
                  Print_Region (Current_Index, Index - 1);
                  Current_Index := Index;
               end if;

               if PMM_Info_Ptr.Bitmap (Index) = PMM_Bitmap_Entry_Free then
                  Total_Free := Total_Free + 1;
               else
                  Total_Used := Total_Used + 1;
               end if;
            end loop;
            Print_Region (Current_Index, Last_Index);
         end;
      end loop;

      Logger.Log_Info ("Total free pages: " & Total_Free'Image);
      Logger.Log_Info ("Total used pages: " & Total_Used'Image);
      Logger.Log_Info ("Total memory: " & To_Hex (Storage_Count (Total_Free + Total_Used) * PMM_PAGE_SIZE));

   end Print_PMM_Info;

   function Get_Pmm_Start_Address return Virtual_Address is
   begin
      return PMM_Header_Address;
   end Get_Pmm_Start_Address;

   function Get_Pmm_End_Address return Virtual_Address is
   begin
      return Virtual_Address (PMM_Bitmap_End_Address);
   end Get_Pmm_End_Address;


end x86.pmm;
