------------------------------------------------------------------------------
--                             X86-PMM-VARIANT                              --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Limine;                  use Limine;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Address_To_Access_Conversions;
with Interfaces;              use Interfaces;
with config;                  use config;

package x86.pmm.Variant is
   pragma Preelaborate;
   use all type System.Address;

   PMM_PAGE_SIZE : constant := 4_096;


   procedure Print_PMM_Info;

   function Memory_Available (MB : Mem_Map_Entry) return Boolean;
   function Base_Address (MB : Mem_Map_Entry) return Physical_Address;
   function Entry_Length (MB : Mem_Map_Entry) return Unsigned_64;
   function Find_PMM_Start (Storage_Size_Needed : Storage_Count; Mem_Map : Memory_Map) return Virtual_Address;
   procedure Mask_Kernel_Pages;

private

end x86.pmm.Variant;
