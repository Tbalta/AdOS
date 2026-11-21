------------------------------------------------------------------------------
--                             X86-PMM-VARIANT                              --
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
package body x86.pmm.Variant is
   package Logger renames Loggers;
   function Round_64 is new Standard.Util.Round (Unsigned_64);
   function To_Hex is new Util.To_Hex (Unsigned_64);
   function To_Hex is new Util.To_Hex (Virtual_Address);
   function To_Hex is new Util.To_Hex (Physical_Address);


   --  function Is_System_Address (addr : Physical_Address) return Boolean
   --     is (addr < Physical_Address (((Storage_Count (Get_Pmm_End_Address) + PMM_PAGE_SIZE - Storage_Count (1)) / PMM_PAGE_SIZE) * PMM_PAGE_SIZE));

   function Memory_Available (MB : Multiboot.multiboot_mmap_entry) return Boolean is
   begin
      return MB.entry_type = MULTIBOOT_MEMORY_AVAILABLE;
   end Memory_Available;

   function Base_Address (MB : Multiboot.multiboot_mmap_entry) return Physical_Address is
   begin
      return Physical_Address (MB.base_addr);
   end Base_Address;

   function Entry_Length (MB : Multiboot.multiboot_mmap_entry) return Unsigned_64 is
   begin
      return Unsigned_64 (MB.length);
   end Entry_Length;

   function Find_PMM_Start (Storage_Size_Needed : Storage_Count; Mem_Map : Multiboot.multiboot_mmap) return Virtual_Address
   is
      pragma Unreferenced (Storage_Size_Needed);
      pragma Unreferenced (Mem_Map);
   begin
      return Virtual_Address (System.Address (Kernel_End));
   end Find_PMM_Start;

   procedure Mask_Kernel_Pages is
      Kernel_Start_Offset : Natural := PMM_Info_Ptr.Bitmap'First;
      Kernel_End_Offset : Natural := Address_To_Offset (Kernel_End);
   begin
      Logger.Log_Info ("Masking kernel memory " & Kernel_Start_Offset'Image & " .. " & Kernel_End_Offset'Image);
      PMM_Info_Ptr.Bitmap (Kernel_Start_Offset .. Kernel_End_Offset) := (others => PMM_Bitmap_Entry_Used);
      Number_Of_Remaining_Pages := Number_Of_Remaining_Pages - (Kernel_End_Offset - Kernel_Start_Offset);
   end Mask_Kernel_Pages;
end x86.pmm.Variant;
