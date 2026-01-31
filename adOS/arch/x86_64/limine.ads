with Interfaces;              use Interfaces;
with System;
package Limine is
   pragma Pure;


   type Limine_Mem_Type is (
      LIMINE_MEMMAP_USABLE,
      LIMINE_MEMMAP_RESERVED,
      LIMINE_MEMMAP_ACPI_RECLAIMABLE,
      LIMINE_MEMMAP_ACPI_NVS,
      LIMINE_MEMMAP_BAD_MEMORY,
      LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE,
      LIMINE_MEMMAP_EXECUTABLE_AND_MODULES,
      LIMINE_MEMMAP_FRAMEBUFFER,
      LIMINE_MEMMAP_ACPI_TABLES
   );

   for Limine_Mem_Type use
      (
      LIMINE_MEMMAP_USABLE =>                 0,
      LIMINE_MEMMAP_RESERVED =>               1,
      LIMINE_MEMMAP_ACPI_RECLAIMABLE =>       2,
      LIMINE_MEMMAP_ACPI_NVS =>               3,
      LIMINE_MEMMAP_BAD_MEMORY =>             4,
      LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE => 5,
      LIMINE_MEMMAP_EXECUTABLE_AND_MODULES => 6,
      LIMINE_MEMMAP_FRAMEBUFFER =>            7,
      LIMINE_MEMMAP_ACPI_TABLES =>            8);

   type Mem_Map_Entry is record
      base   : System.Address;
      length : Unsigned_64;
      flags  : Limine_Mem_Type;
   end record;
   for Mem_Map_Entry use record
      base at 0 range 0 .. 63;
      length at 8 range 0 .. 63;
      flags at 16 range 0 .. 63;
   end record;

end Limine;