------------------------------------------------------------------------------
--                             X86-PMM-VARIANT                              --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with MultiBoot;               use MultiBoot;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Address_To_Access_Conversions;
with Interfaces;              use Interfaces;

package x86.pmm.Variant is
   pragma Preelaborate;
   use all type System.Address;

   PMM_PAGE_SIZE : constant Storage_Count := 4_096;

   -- function Is_System_Address (addr : Physical_Address) return Boolean;
   function Memory_Available (MB : Multiboot.multiboot_mmap_entry) return Boolean;
   function Base_Address (MB : Multiboot.multiboot_mmap_entry) return Physical_Address;
   function Entry_Length (MB : Multiboot.multiboot_mmap_entry) return Unsigned_64;
   function Find_PMM_Start (Storage_Size_Needed : Storage_Count; Mem_Map : Multiboot.multiboot_mmap) return Virtual_Address;
   procedure Mask_Kernel_Pages;
end x86.pmm.Variant;
