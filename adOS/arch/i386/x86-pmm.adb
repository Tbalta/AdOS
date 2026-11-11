------------------------------------------------------------------------------
--                                 X86-PMM                                  --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

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
   function Round_64 is new Standard.Util.Round (Unsigned_64);
   function To_Hex is new Util.To_Hex (Unsigned_64);
   function To_Hex is new Util.To_Hex (Virtual_Address);
   function To_Hex is new Util.To_Hex (Physical_Address);


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
   function Address_To_Offset (addr : Physical_Address) return Natural
   is (Address_To_Offset_Unchecked (addr));


   function Address_To_Offset_Unchecked (addr : Physical_Address) return Natural is
      use all type System.Address;
      Offset : Natural := 1;
      function Round_64 is new Standard.Util.Round (Unsigned_64);
   begin
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
      is (addr < Physical_Address (((Storage_Count (Get_Pmm_End_Address) + PMM_PAGE_SIZE - Storage_Count (1)) / PMM_PAGE_SIZE) * PMM_PAGE_SIZE));

   function Get_Next_Free_Page return Natural is
      use all type System.Address;
      pragma Assert (PMM_Info_Ptr /= null, "PMM Bitmap not initialized.");
   begin
      pragma Assert (not x86.vmm.Is_Paging_Enabled);
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

      if PMM_Info_Ptr.Bitmap (Offset) = PMM_Bitmap_Entry_Used then
         Logger.Log_Error ("Allocating already used page at " & Result'Image & " with offset " & Offset'Image);
         raise Program_Error;
      end if;
      PMM_Info_Ptr.Bitmap (Offset) := PMM_Bitmap_Entry_Used;
      Number_Of_Remaining_Pages := Number_Of_Remaining_Pages - 1;
      return Result;
   end Allocate_Page;

   procedure Free_Page (addr : Physical_Address) is
      Offset : Natural := Address_To_Offset (addr);
   begin
      if Is_System_Address (addr) then
         Logger.Log_Error ("Freeing System_Address " & addr'Image & " at offset " & Offset'Image);
         raise Program_Error;
      end if;
      
      if PMM_Info_Ptr.Bitmap (Offset) = PMM_Bitmap_Entry_Free then
         Logger.Log_Error ("Freeing already free page at " & addr'Image & " with offset " & Offset'Image);
         raise Program_Error;
      end if;

      PMM_Info_Ptr.Bitmap (Offset) := PMM_Bitmap_Entry_Free;
      Number_Of_Remaining_Pages := Number_Of_Remaining_Pages + 1;
   end Free_Page;

   function Memory_Available (MB : multiboot_mmap_entry) return Boolean is
   begin
      return MB.entry_type = MULTIBOOT_MEMORY_AVAILABLE;
   end Memory_Available;

   function Base_Address (MB : multiboot_mmap_entry) return Physical_Address is
   begin
      return Physical_Address (MB.base_addr);
   end Base_Address;

   function Entry_Length (MB : multiboot_mmap_entry) return Unsigned_64 is
   begin
      return Unsigned_64 (MB.length);
   end Entry_Length;

   procedure Init (MB : multiboot_mmap) is
      package ASA is new Aligned_System_Address (PMM_PAGE_SIZE);
      use ASA;

      pmmEntryCount     : Natural := 0;
      pmmHeaderCount    : Integer := 0;
   begin

      --  First step:
         --    Number of pmm entries.
         --    Number of pmm headers.
      PMM_Header_Address := To_Address (Kernel_End);
      Logger.Log_Info ("PMM_Header_Address: " & PMM_Header_Address'Image);
      for Index in MB'Range loop
         if Memory_Available (MB (Index)) then
            Logger.Log_Info (MB (Index)'Image);
            Logger.Log_Info
              ("Found available memory at "
               & To_Hex (Unsigned_64 (Base_Address (MB (Index))))
               & " of size "
               & To_Hex (Entry_Length (MB (Index))));
            pmmEntryCount := pmmEntryCount + Positive (Round_64 (Entry_Length (MB (Index)), Unsigned_64 (PMM_PAGE_SIZE)) / Unsigned_64 (PMM_PAGE_SIZE));
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

         Mem_Map_Address : Physical_Address := Physical_Address (PMM_Header_Address);
         PMM_Settings_Ptr : access PMM_Info_Settings := null;
      begin
         Logger.Log_Info ("PMM structures will be stored at " & To_Hex (Mem_Map_Address));
         PMM_Info_Settings_Conv.To_Pointer (To_Address (Mem_Map_Address)).all :=
            PMM_Info_Settings'
               (Header_Count => pmmHeaderCount,
               Bitmap_Length => pmmEntryCount);

         PMM_Info_Ptr := PMM_Header_Conv.To_Pointer (To_Address (Mem_Map_Address)).all'Unchecked_Access;
      end;

      if PMM_Info_Ptr = null then
         Logger.Log_Error ("No suitable memory region found for PMM structures.");
         raise Program_Error;
      end if;

      Logger.Log_Info ("PMM Header_Count: " & PMM_Info_Ptr.Header_Count'Image);
      Logger.Log_Info ("PMM Bitmap_Length: " & PMM_Info_Ptr.Bitmap_Length'Image);
      
      
      -- Third step:
      --   Filling headers + bitmap allocation.
      declare
         PMM_Header_IDX : Positive := 1;
      begin
         for Index in MB'Range loop
            if Memory_Available (MB (Index)) then
               Logger.Log_Info ("setting header: " & PMM_Header_IDX'Image);
               PMM_Info_Ptr.Headers (PMM_Header_IDX).length := Entry_Length (MB (Index));
               PMM_Info_Ptr.Headers (PMM_Header_IDX).base_addr := Base_Address (MB (Index));
               PMM_Header_IDX := PMM_Header_IDX + 1;
            end if;
         end loop;
         Number_Of_Remaining_Pages := pmmEntryCount;

         for Index in PMM_Info_Ptr.all.Bitmap'Range loop
            PMM_Info_Ptr.Bitmap (Index) := PMM_Bitmap_Entry_Free;
         end loop;
      end;
      ------------------------------------------------------------------------
      Logger.Log_Info ("Setting pmm map.");
      declare
         PMM_Start : Virtual_Address  := To_Virtual_Address (PMM_Info_Ptr.all'Address);
         PMM_End   : Virtual_Address :=  PMM_Start + Virtual_Address ((PMM_Info_Ptr.all'Size + 7) / 8);

         PMM_Start_Offset : Natural := Address_To_Offset (x86.vmm.To_Physical_Address (PMM_Start));
         PMM_End_Offset :   Natural := Address_To_Offset (x86.vmm.To_Physical_Address (PMM_End));

         Kernel_Start_Offset : Natural := PMM_Info_Ptr.Bitmap'First;
         Kernel_End_Offset : Natural := Address_To_Offset (Kernel_End);
      begin
         Logger.Log_Info ("Masking " & PMM_Start_Offset'Image & " .. " & PMM_End_Offset'Image);
         PMM_Info_Ptr.Bitmap (PMM_Start_Offset .. PMM_End_Offset) := (others => PMM_Bitmap_Entry_Used);
         Number_Of_Remaining_Pages := Number_Of_Remaining_Pages - (PMM_End_Offset - PMM_Start_Offset) + 1;

         Logger.Log_Info ("Masking kernel memory " & Kernel_Start_Offset'Image & " .. " & Kernel_End_Offset'Image);
         PMM_Info_Ptr.Bitmap (Kernel_Start_Offset .. Kernel_End_Offset) := (others => PMM_Bitmap_Entry_Used);
         Number_Of_Remaining_Pages := Number_Of_Remaining_Pages - (Kernel_End_Offset - Kernel_Start_Offset);
      end;

      Logger.Log_Info ("PMM initialized. Remaining pages: " & Number_Of_Remaining_Pages'Image);
   
      --  declare
      --  begin
      --     PMM_Bitmap_End_Address := Align (PMM_Bitmap_Address + Storage_Count ((PMM_Bitmap'Size + 7) / 8));

      --     --  Masking the kernel memory.
      --     for Index in Util.Bitmap'Range loop
      --        Util.Bitmap (Index) := PMM_Bitmap_Entry_Free;
      --     end loop;
      --     Logger.Log_Info
      --       ("Masking kernel memory. (0 - " & Address_To_Offset (Kernel_End)'Image & ")");
      --     for Index in 0 .. Positive (Address_To_Offset (Kernel_End)) loop
      --        Util.Bitmap (Index) := PMM_Bitmap_Entry_Used;
      --        Number_Of_Remaining_Pages := Number_Of_Remaining_Pages - 1;
      --     end loop;

      --     -- Masking the headers and the bitmap.
      --     Logger.Log_Info ("Masking PMM entry. (" & Address_To_Offset (Physical_Address (PMM_Header_Address))'Image
      --                       & " .. " & Address_To_Offset (Physical_Address (PMM_Bitmap_End_Address))'Image & ")");
      --     for Index
      --       in Positive (Address_To_Offset (Physical_Address (PMM_Header_Address)))
      --       .. Positive (Address_To_Offset (Physical_Address (PMM_Bitmap_End_Address)))
      --     loop
      --        Util.Bitmap (Index) := PMM_Bitmap_Entry_Used;
      --        Number_Of_Remaining_Pages := Number_Of_Remaining_Pages - 1;
      --     end loop;
      --  end;
   end Init;

   function Get_Pmm_Start_Address return Physical_Address is
   begin
      return Physical_Address (PMM_Header_Address);
   end Get_Pmm_Start_Address;

   function Get_Pmm_End_Address return Physical_Address is
   begin
      return Physical_Address (PMM_Info_Ptr.all'Address + Storage_Count ((PMM_Info_Ptr.all'Size + 7) / 8));
   end Get_Pmm_End_Address;


end x86.pmm;
