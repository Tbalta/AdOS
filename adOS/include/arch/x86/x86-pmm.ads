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

  subtype Physical_Address is System.Address;



  type multiboot_mmap is array (Natural range <>) of multiboot_mmap_entry with
   Pack;
  type PMM_Bitmap_Entry is (PMM_Bitmap_Entry_Free, PMM_Bitmap_Entry_Used) with
   Size => 1;


  -- pmm_map_header_entry store the lenght and base address of a free memory region
  -- This is used for converting pmm_map offsets to physical addresses
  type PMM_Header_Entry is record
    length    : Unsigned_64;
    base_addr : System.Address;
  end record with
   Convention => C;
  type PMM_Headers_Array is array (Positive range <>) of PMM_Header_Entry with
   Convention => C;

  procedure Init (MB : multiboot_mmap);

  type PMM_Header_Info is record
    Bitmap_Length : Positive;
    Header_Count  : Positive;
    Bitmap        : System.Address;
    Headers       : System.Address;
  end record with
   Convention => C;
  package PMM_Header_Conv is new System.Address_To_Access_Conversions
   (PMM_Header_Info);

  PMM_Header_Address : System.Address;
  function check (cond : Boolean; msg : String) return Boolean;

  -----------------------
  -- Address_To_Offset --
  -----------------------
  function Address_To_Offset_Unchecked
   (addr : Physical_Address) return Natural;

  function Address_To_Offset (addr : Physical_Address) return Natural with
   Post =>
    check
     (Integer_Address ((Positive (addr) / PMM_PAGE_SIZE) * PMM_PAGE_SIZE) =
      To_Integer (Offset_To_Address_Unchecked (Address_To_Offset'Result)),
      To_Integer (addr)'Image & " /= " &
      To_Integer (Offset_To_Address_Unchecked (Address_To_Offset'Result))'
       Image &
      " offset: " & Address_To_Offset'Result'Image);
  -----------------------
  -- Offset_To_Address --
  -----------------------
  function Offset_To_Address_Unchecked
   (paroffset : Natural) return Physical_Address;
  
  function Offset_To_Address (paroffset : Natural) return Physical_Address with
   Post =>
    check
     (paroffset = Address_To_Offset_Unchecked (Offset_To_Address'Result),
      "Offset_To_Address: " & paroffset'Image & " /=" &
      Address_To_Offset_Unchecked (Offset_To_Address'Result)'Image);

  function Get_Next_Free_Page return Natural;

  function Allocate_Page return Physical_Address with
   Post =>
    check
     (Get_Next_Free_Page > Address_To_Offset (Allocate_Page'Result),
      "Allocate_Page: Free page available but not returned");

  procedure Free_Page (addr : Physical_Address) with
   Post =>
    check
     (Get_Next_Free_Page <= Address_To_Offset (addr),
      "Free_Page: Page not freed");

  generic
    PMM_Address : System.Address;
  package PMM_Utils is
    PMM_Info : access PMM_Header_Info :=
     PMM_Header_Conv.To_Pointer (PMM_Address);

    subtype PMM_Headers is PMM_Headers_Array (1 .. PMM_Info.Header_Count);
    type PMM_Bitmap is
     array (0 .. (PMM_Info.Bitmap_Length - 1)) of PMM_Bitmap_Entry with
     Convention => C, Pack => True;
    package PMM_Header_Conv is new System.Address_To_Access_Conversions
     (PMM_Headers);
    package PMM_Bitmap_Conv is new System.Address_To_Access_Conversions
     (PMM_Bitmap);

    Headers : access PMM_Headers :=
     PMM_Header_Conv.To_Pointer (PMM_Info.Headers);
    Bitmap : access PMM_Bitmap := PMM_Bitmap_Conv.To_Pointer (PMM_Info.Bitmap);
  end PMM_Utils;
end x86.pmm;
