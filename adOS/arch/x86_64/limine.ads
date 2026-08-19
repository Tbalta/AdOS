with Interfaces;              use Interfaces;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with x86;   use x86;
with Interfaces.C;
with Interfaces.C.Strings;
package Limine is
   pragma Preelaborate;

   type limine_id is array (0 .. 3) of Unsigned_64;

   -------------------------------
   -- Limine Memory Map Request --
   -------------------------------


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
      base   : Physical_Address;
      length : Unsigned_64;
      flags  : Limine_Mem_Type;
   end record;
   for Mem_Map_Entry use record
      base at 0 range 0 .. 63;
      length at 8 range 0 .. 63;
      flags at 16 range 0 .. 63;
   end record;
   type Mem_Map_Entry_Access is access all Mem_Map_Entry;
   pragma Convention (C, Mem_Map_Entry_Access);


   type Entry_Map_Array is array (Positive range <>) of Mem_Map_Entry_Access;
   type Entry_Map_Array_Access is access all Entry_Map_Array;
   pragma Convention (C, Entry_Map_Array_Access);

   type Mem_Map_Response (Entry_Map_Count : Positive) is record
      revision  : Unsigned_64;
      entry_map :  Entry_Map_Array_Access (1 .. Entry_Map_Count);
   end record;
   for Mem_Map_Response use record
      revision at 0 range 0 .. 63;
      Entry_Map_Count at 8 range 0 .. 63;
      entry_map at 16 range 0 .. 63;
   end record;
   type Mem_Map_Response_Access is access all Mem_Map_Response;
   pragma Convention (C, Mem_Map_Response_Access);


   -- Limine Memory Map Request --
   type limine_memmap_request is record
      id       : limine_id;
      revision : Unsigned_64 := 0;
      response : Mem_Map_Response_Access := null;
   end record;
   for limine_memmap_request use record
      id       at 0 range 0 .. 255;
      revision at 32 range 0 .. 63;
      response at 40 range 0 .. 63;
   end record;

   subtype HHDM_Offset is Storage_Offset range 0 .. Storage_Offset'Last;

   type limine_hhdm_response is record
      revision : Unsigned_64;
      offset   : HHDM_Offset;
   end record;
   for limine_hhdm_response use record
      revision at 0 range 0 .. 63;
      offset at 8 range 0 .. 63;
   end record;
   type hhdm_response_access is access all limine_hhdm_response;
   pragma Convention (C, hhdm_response_access);

   type limine_hhdm_request is record
      id      : limine_id;
      revision : Unsigned_64 := 0;
      response : hhdm_response_access := null;
   end record;
   for limine_hhdm_request use record
      id at 0 range 0 .. 255;
      revision at 32 range 0 .. 63;
      response at 40 range 0 .. 63;
   end record;
   
   
   -- Limine Framebuffer Request --
   type limine_video_mode is record
      pitch : Unsigned_64;
      width : Unsigned_64;
      height : Unsigned_64;
      bpp : Unsigned_16;
      memory_model : Unsigned_8;
      red_mask_size : Unsigned_8;
      red_mask_shift : Unsigned_8;
      green_mask_size : Unsigned_8;
      green_mask_shift : Unsigned_8;
      blue_mask_size : Unsigned_8;
      blue_mask_shift : Unsigned_8;
   end record
      with Convention => C_Pass_By_Copy;
   for limine_video_mode use record
      pitch at 0 range 0 .. 63;
      width at 8 range 0 .. 63;
      height at 16 range 0 .. 63;
      bpp at 24 range 0 .. 15;
      memory_model at 32 range 0 .. 7;
      red_mask_size at 40 range 0 .. 7;
      red_mask_shift at 48 range 0 .. 7;
      green_mask_size at 56 range 0 .. 7;
      green_mask_shift at 64 range 0 .. 7;
      blue_mask_size at 72 range 0 .. 7;
      blue_mask_shift at 80 range 0 .. 7;
   end record;
   type video_mode_access is access all limine_video_mode;
   pragma Convention (C, video_mode_access);
   type video_mode_access_array is array (Positive range <>) of video_mode_access;
   type video_mode_access_array_access is access all video_mode_access_array;
   pragma Convention (C, video_mode_access_array_access);

   type anon_array1093 is array (0 .. 6) of aliased Unsigned_8 with Pack => True;

   --
   type limine_framebuffer (mode_count : Positive) is record
      address : System.Address;
      width : aliased Unsigned_64;
      height : aliased Unsigned_64;
      pitch : aliased Unsigned_64;
      bpp : aliased Unsigned_16;
      memory_model : aliased Unsigned_8;
      red_mask_size : aliased Unsigned_8;
      red_mask_shift : aliased Unsigned_8;
      green_mask_size : aliased Unsigned_8;
      green_mask_shift : aliased Unsigned_8;
      blue_mask_size : aliased Unsigned_8;
      blue_mask_shift : aliased Unsigned_8;
      unused : anon_array1093;
      edid_size : aliased Unsigned_64;
      edid : System.Address;
      modes : video_mode_access_array_access (1 .. mode_count);
   end record;
   for limine_framebuffer use record
      address at 0 range 0 .. 63;
      width at 8 range 0 .. 63;
      height at 16 range 0 .. 63;
      pitch at 24 range 0 .. 63;
      bpp at 32 range 0 .. 15;
      memory_model at 34 range 0 .. 7;
      red_mask_size at 35 range 0 .. 7;
      red_mask_shift at 36 range 0 .. 7;
      green_mask_size at 37 range 0 .. 7;
      green_mask_shift at 38 range 0 .. 7;
      blue_mask_size at 39 range 0 .. 7;
      blue_mask_shift at 40 range 0 .. 7;
      unused at 41 range 0 .. 55;
      edid_size at 96 range 0 .. 63;
      edid at 104 range 0 .. 63;
      mode_count at 192 range 0 .. 63;
      modes at 200 range 0 .. 63;
   end record;
   type Framebuffer_Access is access all limine_framebuffer;
   pragma Convention (C, Framebuffer_Access);
   type Framebuffer_Access_Array is array (Positive range <>) of aliased Framebuffer_Access;
   type Framebuffer_Access_Array_Access is access all Framebuffer_Access_Array;
   pragma Convention (C, Framebuffer_Access_Array_Access);

   --
   type limine_framebuffer_response (framebuffer_count : Positive) is record
      revision : Unsigned_64;
      framebuffers : Framebuffer_Access_Array_Access (1 .. framebuffer_count);
   end record;
   type Framebuffer_Response_Access is access all limine_framebuffer_response;
   pragma Convention (C, Framebuffer_Response_Access);
   --
   type limine_framebuffer_request is record
      id       : limine_id;
      revision : Unsigned_64 := 0;
      response : Framebuffer_Response_Access := null;
   end record;
   for limine_framebuffer_request use record
      id at 0 range 0 .. 255;
      revision at 32 range 0 .. 63;
      response at 40 range 0 .. 63;
   end record;

   --
   type limine_executable_cmdline_response is record
      revision : aliased Unsigned_64;
      cmdline : Interfaces.C.Strings.chars_ptr;
   end record
   with Convention => C_Pass_By_Copy;
   type Executable_Cmdline_Response_Access is access all limine_executable_cmdline_response;
   pragma Convention (C, Executable_Cmdline_Response_Access);

   type limine_executable_cmdline_request is record
      id : aliased limine_id;
      revision : aliased Unsigned_64;
      response : Executable_Cmdline_Response_Access;
   end record
   with Convention => C_Pass_By_Copy;



   -------------------------------
   -- Limine Requests Instances --
   -------------------------------
   hhdm_request : constant limine_hhdm_request;
   pragma Import (C, hhdm_request, "hhdm_request");
   hhdm_response : hhdm_response_access renames hhdm_request.response;

   mem_map_request : constant limine_memmap_request;
   pragma Import (C, mem_map_request, "memmap_request");
   limine_memmap_response : Mem_Map_Response_Access renames mem_map_request.response;

   framebuffer_request : constant limine_framebuffer_request;
   pragma Import (C, framebuffer_request, "framebuffer_request");
   framebuffer_response : Framebuffer_Response_Access renames framebuffer_request.response;

   executable_cmdline_request : constant limine_executable_cmdline_request;
   pragma Import (C, executable_cmdline_request, "executable_cmdline_request");
   executable_cmdline_response : Executable_Cmdline_Response_Access renames executable_cmdline_request.response;



   --  package Mem_Map_Entry_Conversions is new
   --     System.Address_To_Access_Conversions (Mem_Map_Entry);
   --  function To_Mem_Map_Access (Addr : System.Address) return Mem_Map_Entry_Access is (Mem_Map_Entry_Access (Mem_Map_Entry_Conversions.To_Pointer (Addr)));

end Limine;