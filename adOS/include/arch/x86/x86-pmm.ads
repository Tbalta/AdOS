with MultiBoot;               use MultiBoot;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Address_To_Access_Conversions;
with Interfaces;              use Interfaces;
package x86.pmm is
   pragma Preelaborate;

   MULTIBOOT_MEMORY_AVAILABLE        : constant multiboot_uint32_t := 1;
   MULTIBOOT_MEMORY_RESERVED         : constant multiboot_uint32_t := 2;
   MULTIBOOT_MEMORY_ACPI_RECLAIMABLE : constant multiboot_uint32_t := 3;
   MULTIBOOT_MEMORY_NVS              : constant multiboot_uint32_t := 4;
   MULTIBOOT_MEMORY_BADRAM           : constant multiboot_uint32_t := 5;
   PMM_PAGE_SIZE                     : constant Positive           := 4_096;

   type multiboot_mmap is
     array (Positive range <>) of multiboot_mmap_entry with
     Pack, Convention => C;
   type pmm_bitmap is array (Positive range <>) of Boolean with
     Pack, Convention => C;

   type pmm_map is record
      length : Positive;
      bitmap : access pmm_bitmap;
   end record;

   -- pmm_map_header_entry store the lenght and base address of a free memory region
   -- This is used for converting pmm_map offsets to physical addresses
   type pmm_map_header_entry is record
      length    : Unsigned_64;
      base_addr : System.Address;
   end record with
     Convention => C;
   type pmm_map_header is
     array (Positive range <>) of pmm_map_header_entry with
     Convention => C;

   procedure Init (MB : multiboot_mmap);

   subtype pmmMapAddress is Integer_Address with
       Dynamic_Predicate => (pmmMapAddress mod Integer_Address (PMM_PAGE_SIZE) = 0);

      --   package pmm_bitmap_from_address is new System.Address_To_Access_Conversions
      --      (multiboot_mmap_array);

private
end x86.pmm;
