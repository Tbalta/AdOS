with SERIAL;
with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;
with Aligned_System_Address;
with config;                  use config;

package body x86.pmm is

   function check (cond : Boolean; msg : String) return Boolean is
   begin
      if (not cond) then
         SERIAL.send_line ("PMM: " & msg);
      end if;
      return cond;
   end check;

   ------------------------------
   -- Physical_Address Utility --
   ------------------------------
   function To_Integer (Value : Physical_Address) return Integer_Address is
   begin
      return Integer_Address (Value);
   end To_Integer;

   function To_Address (Value : Physical_Address) return System.Address is
   begin
      return System.Address (Value);
   end To_Address;

   -----------------------
   -- Address_To_Offset --
   -----------------------
   function Address_To_Offset (addr : Physical_Address) return Natural
   is (Address_To_Offset_Unchecked (addr));

   function Address_To_Offset_Unchecked (addr : Physical_Address) return Natural is
      package Util is new PMM_Utils (PMM_Header_Address);
      use Util;
      Offset : Natural := 0;
   begin
      for Index in Util.Headers.all'Range loop
         if addr in
              Physical_Address (Headers (Index).base_addr)
              .. Physical_Address
                   (Headers (Index).base_addr + Storage_Offset (Headers (Index).length))
         then
            return Offset + Natural (To_Address (addr) - Headers (Index).base_addr) / PMM_PAGE_SIZE;
         end if;
         Offset := Offset + Natural (Headers (Index).length) / PMM_PAGE_SIZE;
      end loop;
      return -1;
   end Address_To_Offset_Unchecked;

   -----------------------
   -- Offset_To_Address --
   -----------------------
   function Offset_To_Address_Unchecked (paroffset : Natural) return Physical_Address is
      package Util is new PMM_Utils (PMM_Header_Address);
      use Util;
      Offset : Natural := paroffset;
   begin
      for Index in Headers'Range loop
         if Offset < Positive (Headers (Index).length) / PMM_PAGE_SIZE then
            return
              Physical_Address
                (Headers (Index).base_addr + Storage_Offset (Offset * PMM_PAGE_SIZE));
         else
            Offset := Offset - Positive (Headers (Index).length) / PMM_PAGE_SIZE;
         end if;
      end loop;
      return Physical_Address (0);
   end Offset_To_Address_Unchecked;

   function Offset_To_Address (paroffset : Natural) return Physical_Address
   is (Offset_To_Address_Unchecked (paroffset));

   function Get_Next_Free_Page return Natural is
      package Util is new PMM_Utils (PMM_Header_Address);
      use Util;
   begin
      for Index in Util.Bitmap'Range loop
         if Util.Bitmap (Index) = PMM_Bitmap_Entry_Free then
            return Index;
         end if;
      end loop;
      return -1;
   end Get_Next_Free_Page;

   function Allocate_Page return Physical_Address is
      package Util is new PMM_Utils (PMM_Header_Address);
      use Util;
      Offset : Natural := Get_Next_Free_Page;
      Result : Physical_Address;
   begin
      Util.Bitmap (Offset) := PMM_Bitmap_Entry_Used;
      Result := Offset_To_Address (Offset);
      SERIAL.send_line
        ("PMM: Allocated page at " & To_Address (Result)'Image & " with offset " & Offset'Image);
      return Result;
   end Allocate_Page;

   procedure Free_Page (addr : Physical_Address) is
      package Util is new PMM_Utils (PMM_Header_Address);
      use Util;
      Offset : Natural := Address_To_Offset (addr);

   begin
      if Offset = -1 then
         return;
      end if;
      Util.Bitmap (Offset) := PMM_Bitmap_Entry_Free;
   end Free_Page;

   --  pragma Suppress (All_Checks);
   procedure Init (MB : multiboot_mmap) is
      package ASA is new Aligned_System_Address (PMM_PAGE_SIZE);
      use ASA;

      pmmEntryCount     : Positive := 1;
      pmmHeaderCount    : Integer := 0;
      firstValidAddress : Unsigned_32 := 0;
      subtype Positive_Aligned_Address is Aligned_Address
      with Dynamic_Predicate => (To_Integer (Positive_Aligned_Address) > 0);
      subtype Aligned_Storage_Offset is Storage_Offset
      with Dynamic_Predicate => (Positive (Aligned_Storage_Offset) mod PMM_PAGE_SIZE = 0);

      PMM_Bitmap_Address : Positive_Aligned_Address;
      PMM_Headers        : access PMM_Header_Info := PMM_Header_Conv.To_Pointer (To_Address (Kernel_End));
   begin
      PMM_Header_Address := To_Address (Kernel_End);
      --  Computing pmm map entry count.
      for Index in MB'Range loop
         if MB (Index).entry_type = MULTIBOOT_MEMORY_AVAILABLE then
            SERIAL.send_line
              ("Found available memory at "
               & Unsigned_32 (MB (Index).base_addr)'Image
               & " of size "
               & Unsigned_32 (MB (Index).length)'Image);
            pmmEntryCount := pmmEntryCount + Positive (MB (Index).length) / PMM_PAGE_SIZE;
            pmmHeaderCount := pmmHeaderCount + 1;
         end if;
      end loop;

      SERIAL.send_line ("Found " & pmmHeaderCount'Image & " Headers.");
      SERIAL.send_line ("Setting pmm header.");
      SERIAL.send_line ("kernel_end: " & Kernel_End'Image);

      ------------------------------------------------------------------------
      declare
         -- Setting pmm header.
         PMM_Header_Array_Start : System.Address := PMM_Header_Address + ((PMM_Header_Info'Size + 7) / 8);
         subtype PMM_Header_Array is PMM_Headers_Array (1 .. pmmHeaderCount);
         package PMM_Header_Array_Conversion is new System.Address_To_Access_Conversions (PMM_Header_Array);


         PMM_Header_IDX         : Positive := 1;
         Headers                : access PMM_Header_Array := PMM_Header_Array_Conversion.To_Pointer (PMM_Header_Array_Start);

      begin
         SERIAL.send_line ("PMM_Header start at: " & PMM_Header_Address'Image);
         SERIAL.send_line ("PMM_Header number of element: " & pmmHeaderCount'Image);
         PMM_Headers.Header_Count := pmmHeaderCount;
         PMM_Headers.Headers := PMM_Header_Array_Start;
         for Index in MB'Range loop
            if MB (Index).entry_type = MULTIBOOT_MEMORY_AVAILABLE then
               Headers (PMM_Header_IDX).base_addr :=
                 To_Address (Integer_Address (MB (Index).base_addr));
               Headers (PMM_Header_IDX).length := Unsigned_64 (MB (Index).length);
               SERIAL.send_line ("setting header: " & PMM_Header_IDX'Image);
               PMM_Header_IDX := PMM_Header_IDX + 1;
            end if;
         end loop;
         PMM_Bitmap_Address := Align (PMM_Header_Array_Start + ((PMM_Header_Array'Size + 7) / 8));
         PMM_Headers.Bitmap_Length := pmmEntryCount;
         PMM_Headers.Bitmap := PMM_Bitmap_Address;
         SERIAL.send_line ("PMM_Bitmap start at: " & PMM_Bitmap_Address'Image);
         SERIAL.send_line ("PMM_Bitmap number of element: " & pmmEntryCount'Image);
      end;

      ------------------------------------------------------------------------
      SERIAL.send_line ("Setting pmm map.");
      declare
         -- Setting pmm map.
         package Util is new PMM_Utils (PMM_Header_Address);
         use Util;
         PMM_Bitmap_End_Address : Positive_Aligned_Address :=
           Align (PMM_Bitmap_Address + ((PMM_Bitmap'Size + 1) / 8));
      begin
         SERIAL.send_line
           ("Address_To_Offset"
            & Address_To_Offset (Physical_Address (PMM_Bitmap_End_Address))'Image
            & " "
            & Offset_To_Address (Address_To_Offset (To_Address (4_098)))'Image);
         --  Masking the kernel memory.
         SERIAL.send_line
           ("Masking kernel memory. (0 - " & Address_To_Offset (Kernel_End)'Image & ")");
         for Index in 0 .. Positive (Address_To_Offset (Kernel_End)) loop
            Util.Bitmap (Index) := PMM_Bitmap_Entry_Used;
         end loop;

         -- Masking the headers and the bitmap.
         for Index
           in Positive (Address_To_Offset (Physical_Address (PMM_Header_Address)))
           .. Positive (Address_To_Offset (Physical_Address (PMM_Bitmap_End_Address)))
         loop
            Util.Bitmap (Index) := PMM_Bitmap_Entry_Used;
         end loop;
      end;
   end Init;
end x86.pmm;
