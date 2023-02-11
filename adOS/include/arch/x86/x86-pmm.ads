with MultiBoot; use MultiBoot;

package x86.pmm is
    pragma Preelaborate;

    MULTIBOOT_MEMORY_AVAILABLE        : constant multiboot_uint32_t := 1;
    MULTIBOOT_MEMORY_RESERVED         : constant multiboot_uint32_t := 2;
    MULTIBOOT_MEMORY_ACPI_RECLAIMABLE : constant multiboot_uint32_t := 3;
    MULTIBOOT_MEMORY_NVS              : constant multiboot_uint32_t := 4;
    MULTIBOOT_MEMORY_BADRAM           : constant multiboot_uint32_t := 5;

    type multiboot_mmap is
       array (Positive range <>) of multiboot_mmap_entry with
       Pack, Convention => C;
    procedure Init (MB : multiboot_mmap);

private
end x86.pmm;
