------------------------------------------------------------------------------
--                                 X86.PMM                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with Limine;                  use Limine;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Address_To_Access_Conversions;
with Interfaces;              use Interfaces;

package x86.pmm is
   pragma Preelaborate;
   use all type System.Address;

   PMM_PAGE_SIZE : constant Storage_Count := 4_096;

   type multiboot_mmap is array (Natural range <>) of aliased Mem_Map_Entry with Pack;
   type PMM_Bitmap_Entry is (PMM_Bitmap_Entry_Free, PMM_Bitmap_Entry_Used) with Size => 1;

   type PMM_Bitmap is array (Natural range <>) of PMM_Bitmap_Entry with Component_Size => 1;


   -- pmm_map_header_entry store the lenght and base address of a free memory region
   -- This is used for converting pmm_map offsets to physical addresses
   type PMM_Header_Entry is record
      length    : Unsigned_64;
      base_addr : Physical_Address;
   end record
   with Convention => C;
   type PMM_Headers_Array is array (Positive range <>) of PMM_Header_Entry with Convention => C;

   procedure Init (Mem_Map : Mem_Map_Response);
   procedure Print_PMM_Info;

   --  type PMM_Header_Info is record
   --     Bitmap_Length : Positive;
   --     Header_Count  : Positive;
   --     Bitmap        : System.Address;
   --     Headers       : System.Address;
   --  end record
   --  with Convention => C;
   --  package PMM_Header_Conv is new System.Address_To_Access_Conversions (PMM_Header_Info);

   function check (cond : Boolean; msg : String) return Boolean;

   -----------------------
   -- Address_To_Offset --
   -----------------------
   function Address_To_Offset_Unchecked (addr : Physical_Address) return Natural;

   function Address_To_Offset (addr : Physical_Address) return Natural
   with
     Post =>
       check
         (Integer_Address ((Storage_Count (addr) / PMM_PAGE_SIZE) * PMM_PAGE_SIZE)
          = To_Integer (Offset_To_Address_Unchecked (Address_To_Offset'Result)),
          addr'Image
          & " /= "
          & Offset_To_Address_Unchecked (Address_To_Offset'Result)'Image
          & " offset: "
          & Address_To_Offset'Result'Image);
   -----------------------
   -- Offset_To_Address --
   -----------------------
   function Offset_To_Address_Unchecked (paroffset : Natural) return Physical_Address;

   function Offset_To_Address (paroffset : Natural) return Physical_Address
   with
     Post =>
       check
         (paroffset = Address_To_Offset_Unchecked (Offset_To_Address'Result),
          "Offset_To_Address: "
          & paroffset'Image
          & " /="
          & Address_To_Offset_Unchecked (Offset_To_Address'Result)'Image);

   function Get_Next_Free_Page return Natural;

   function Get_Pmm_Start_Address return Virtual_Address;
   function Get_Pmm_End_Address return Virtual_Address;
   function Is_System_Address (addr : Physical_Address) return Boolean;

   function Allocate_Page return Physical_Address
   with
     Post =>
       check (Get_Next_Free_Page'Old = Address_To_Offset (Allocate_Page'Result), "Incorrect Page allocated") and
       check (Get_Next_Free_Page'Old < Get_Next_Free_Page, "No page allocated returned: " & Get_Next_Free_Page'Image & " old was " & Get_Next_Free_Page'Old'Image) and
       check (not Is_System_Address (Allocate_Page'Result), "Allocate_Page: Allocating system page (" & Address_To_Offset (Allocate_Page'Result)'Image & ")");

   procedure Free_Page (addr : Physical_Address)
   with Pre => check (not Is_System_Address (addr) , "Free_Page: Trying to free system page"),
        Post => check (Get_Next_Free_Page <= Address_To_Offset (addr), "Free_Page: Page not freed");

private
   type PMM_Info_Settings is record
      Header_Count : Positive;
      Bitmap_Length : Positive;
   end record;
   for PMM_Info_Settings use record
      Header_Count at 0 range 0 .. 63;
      Bitmap_Length at 8 range 0 .. 63;
   end record;
   type PMM_Info (Header_Count : Positive; Bitmap_Length : Positive) is record
         Headers       : PMM_Headers_Array (1 .. Header_Count);
         Bitmap        : PMM_Bitmap (1 .. Bitmap_Length);
   end record;
   for PMM_Info use record
      Header_Count at 0 range 0 .. 63;
      Bitmap_Length at 8 range 0 .. 63;
   end record;
   type PMM_Info_Access is access all PMM_Info;

   PMM_Header_Address        : System.Address;
   PMM_Bitmap_End_Address    : System.Address;
   Number_Of_Remaining_Pages : Natural;
   PMM_Info_Ptr              : PMM_Info_Access := null;


end x86.pmm;
