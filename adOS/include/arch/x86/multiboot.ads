with Interfaces.C; use Interfaces.C;
with Interfaces;   use Interfaces;
with System;

package MultiBoot is
   pragma Pure;

   subtype multiboot_uint8_t is Unsigned_8;
   subtype multiboot_uint16_t is Unsigned_16;
   subtype multiboot_uint32_t is Unsigned_32;
   subtype multiboot_uint64_t is Unsigned_64;

   type multiboot_header is record
      --      Must be MULTIBOOT_MAGIC - see above.
      magic : multiboot_uint32_t;

      -- Feature flags
      flags : multiboot_uint32_t;

      -- The above fields plus this one must equal 0 mod 2^32
      checksum : multiboot_uint32_t;

      -- These are only valid if MULTIBOOT_AOUT_KLUDGE is set
      header_addr   : System.Address;
      load_addr     : System.Address;
      load_end_addr : System.Address;
      bss_end_addr  : System.Address;
      entry_addr    : System.Address;

      -- These are only valid if MULTIBOOT_VIDEO_MODE is set
      mode_type : multiboot_uint32_t;
      width     : multiboot_uint32_t;
      height    : multiboot_uint32_t;
      depth     : multiboot_uint32_t;
   end record;

   for multiboot_header use
      record
         magic         at 0  range 0 .. 31;
         flags         at 4  range 0 .. 31;
         checksum      at 8  range 0 .. 31;
         header_addr   at 12 range 0 .. 31;
         load_addr     at 16 range 0 .. 31;
         load_end_addr at 20 range 0 .. 31;
         bss_end_addr  at 24 range 0 .. 31;
         entry_addr    at 28 range 0 .. 31;
         mode_type     at 32 range 0 .. 31;
         width         at 36 range 0 .. 31;
         height        at 40 range 0 .. 31;
         depth         at 44 range 0 .. 31;
      end record; 

   type multiboot_info_flag is array (0 .. 31) of Boolean;
   for multiboot_info_flag'Size use 32;
   for multiboot_info_flag'Component_Size use 1;

   type multiboot_info is record
      flags     : multiboot_info_flag;
      -- Available memory from BIOS
      mem_lower : multiboot_uint32_t;
      mem_upper : multiboot_uint32_t;

      -- "root" partition
      boot_device : multiboot_uint32_t;

      -- Kernel command line
      cmdline : System.Address;

      -- Boot-Module list
      mods_count : multiboot_uint32_t;
      mods_addr  : multiboot_uint32_t;

      -- multiboot_elf_section_header_table_t
      tabsize  : multiboot_uint32_t;
      strsize  : multiboot_uint32_t;
      addr     : multiboot_uint32_t;
      reserved : multiboot_uint32_t;

      -- Memory Mapping buffer
      mmap_length : multiboot_uint32_t;
      mmap_addr   : System.Address;

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

   for multiboot_info use
      record
         flags             at 0   range 0 .. 31;
         mem_lower         at 4   range 0 .. 31;
         mem_upper         at 8   range 0 .. 31;
         boot_device       at 12  range 0 .. 31;
         cmdline           at 16  range 0 .. 31;
         mods_count        at 20  range 0 .. 31;
         mods_addr         at 24  range 0 .. 31;
         tabsize           at 28  range 0 .. 31;
         strsize           at 32  range 0 .. 31;
         addr              at 36  range 0 .. 31;
         reserved          at 40  range 0 .. 31;
         mmap_length       at 44  range 0 .. 31;
         mmap_addr         at 48  range 0 .. 31;
         drives_length     at 52  range 0 .. 31;
         drives_addr       at 56  range 0 .. 31;
         config_table      at 60  range 0 .. 31;
         boot_loader_name  at 64  range 0 .. 31;
         apm_table         at 68  range 0 .. 31;
      end record;

   type multiboot_mmap_entry is record
      size       : multiboot_uint32_t;
      base_addr  : multiboot_uint64_t;
      length     : multiboot_uint64_t;
      entry_type : multiboot_uint32_t;
   end record
   with Convention => C, Pack => True;


private
end MultiBoot;
