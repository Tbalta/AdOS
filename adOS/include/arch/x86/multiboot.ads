with Interfaces.C; use Interfaces.C;

package MultiBoot is
   pragma Pure;

   subtype multiboot_uint8_t is unsigned_char;
   subtype multiboot_uint16_t is unsigned_short;
   subtype multiboot_uint32_t is unsigned_int;
   subtype multiboot_uint64_t is unsigned_long_long;

   type multiboot_header is record
      --      Must be MULTIBOOT_MAGIC - see above.
      magic : multiboot_uint32_t;

      -- Feature flags
      flags : multiboot_uint32_t;

      -- The above fields plus this one must equal 0 mod 2^32
      checksum : multiboot_uint32_t;

      -- These are only valid if MULTIBOOT_AOUT_KLUDGE is set
      header_addr   : multiboot_uint32_t;
      load_addr     : multiboot_uint32_t;
      load_end_addr : multiboot_uint32_t;
      bss_end_addr  : multiboot_uint32_t;
      entry_addr    : multiboot_uint32_t;

      -- These are only valid if MULTIBOOT_VIDEO_MODE is set
      mode_type : multiboot_uint32_t;
      width     : multiboot_uint32_t;
      height    : multiboot_uint32_t;
      depth     : multiboot_uint32_t;
   end record;

   type multiboot_info is record
      -- Multiboot info version number
      flags : multiboot_uint32_t;

      -- Available memory from BIOS
      mem_lower : multiboot_uint32_t;
      mem_upper : multiboot_uint32_t;

      -- "root" partition
      boot_device : multiboot_uint32_t;

      -- Kernel command line
      cmdline : multiboot_uint32_t;

      -- Boot-Module list
      mods_count : multiboot_uint32_t;
      mods_addr  : multiboot_uint32_t;

      -- multiboot_elf_section_header_table_t
      num   : multiboot_uint32_t;
      size  : multiboot_uint32_t;
      addr  : multiboot_uint32_t;
      shndx : multiboot_uint32_t;

      -- Memory Mapping buffer
      mmap_length : multiboot_uint32_t;
      mmap_addr   : multiboot_uint32_t;

      -- Drive Info buffer
      drives_length : multiboot_uint32_t;
      drives_addr   : multiboot_uint32_t;

      -- ROM configuration table
      config_table : multiboot_uint32_t;

      -- Boot Loader Name
      boot_loader_name : multiboot_uint32_t;

      -- APM table
      apm_table : multiboot_uint32_t;
   end record
   with Convention => C, Pack => True;

   type multiboot_mmap_entry is record
      size       : multiboot_uint32_t;
      base_addr  : multiboot_uint64_t;
      length     : multiboot_uint64_t;
      entry_type : multiboot_uint32_t;
   end record
   with Convention => C, Pack => True;




private
end MultiBoot;
