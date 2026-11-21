------------------------------------------------------------------------------
--                             X86-PMM-VARIANT                              --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces;              use Interfaces;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
with Loggers;
with Util;
with x86.vmm;
package body x86.pmm.Variant is
   package Logger renames Loggers;

   function Memory_Available (MB : Mem_Map_Entry) return Boolean is
   begin
      return MB.flags = LIMINE_MEMMAP_USABLE;
   end Memory_Available;

   function Base_Address (MB : Mem_Map_Entry) return Physical_Address is
   begin
      return Physical_Address (MB.base);
   end Base_Address;

   function Entry_Length (MB : Mem_Map_Entry) return Unsigned_64 is
   begin
      return Unsigned_64 (MB.length);
   end Entry_Length;

   function Find_PMM_Start (Storage_Size_Needed : Storage_Count; Mem_Map : Entry_Map_Array) return Virtual_Address
   is
      Mem_Map_Address : Virtual_Address := Virtual_Address'First;
   begin
      for Index in Mem_Map'Range loop
            if Memory_Available (Mem_Map (Index)) and 
               Entry_Length (Mem_Map (Index)) > Unsigned_64 (Storage_Size_Needed)
            then
               Mem_Map_Address := x86.vmm.To_Virtual_Address (Base_Address (Mem_Map (Index)));
            end if;
      end loop;

      return Mem_Map_Address;
   end Find_PMM_Start;


   procedure Mask_Kernel_Pages is
   begin
      -- Kernel masking not needed for x86_64
      null;
   end Mask_Kernel_Pages;

   procedure Print_PMM_Info is

      function To_Hex is new Util.To_Hex(Physical_Address);
      function To_Hex is new Util.To_Hex(Storage_Count);
      function To_Hex is new Util.To_Hex(Integer_Address);

      procedure Print_Region (First_Index, Last_Index : Natural) is
         Start_Address : Physical_Address := Offset_To_Address (First_Index);
         End_Address : Physical_Address := Offset_To_Address (Last_Index);
         To_Hex_Size  : Natural := Physical_Address'Size / 4;

      begin
         Logger.Log_Info ("   " & To_Hex (Start_Address, To_Hex_Size) & " " & To_Hex (End_Address, To_Hex_Size) & " " & PMM_Info_Ptr.Bitmap (First_Index)'Image & " " & First_Index'Image & ".." & Last_Index'Image);
      end Print_Region;

      Total_Free : Natural := 0;
      Total_Used : Natural := 0;

      Pmm_Start : Integer_Address := Integer_Address (PMM_Info_Ptr.all'Address);
      Pmm_End   : Integer_Address := Pmm_Start + Integer_Address ((PMM_Info_Ptr.all'Size + 7) / 8);
   begin
      Logger.Log_Info ("PMM Info:");
      Logger.Log_Info ("PMM is stored at: " & To_Hex (Pmm_Start, 16) & " - " & To_Hex (Pmm_End, 16));
      for Region in PMM_Info_Ptr.Headers'Range loop
         declare
            First_Index : Natural := Address_To_Offset (PMM_Info_Ptr.Headers (Region).base_addr);
            Last_Index : Natural := Address_To_Offset (PMM_Info_Ptr.Headers (Region).base_addr + Storage_Count (PMM_Info_Ptr.Headers (Region).length) - 1);
            Current_Index : Natural := First_Index;
         begin
            if PMM_Info_Ptr.Bitmap (First_Index) = PMM_Bitmap_Entry_Free then
                  Total_Free := Total_Free + 1;
            else
                  Total_Used := Total_Used + 1;
            end if;

            for Index in (Current_Index + 1) .. Last_Index loop
               if PMM_Info_Ptr.Bitmap (Index) /= PMM_Info_Ptr.Bitmap (Current_Index) then
                  Print_Region (Current_Index, Index - 1);
                  Current_Index := Index;
               end if;

               if PMM_Info_Ptr.Bitmap (Index) = PMM_Bitmap_Entry_Free then
                  Total_Free := Total_Free + 1;
               else
                  Total_Used := Total_Used + 1;
               end if;
            end loop;
            Print_Region (Current_Index, Last_Index);
         end;
      end loop;

      Logger.Log_Info ("Total free pages: " & Total_Free'Image);
      Logger.Log_Info ("Total used pages: " & Total_Used'Image);
      Logger.Log_Info ("Total memory: " & To_Hex (Storage_Count (Total_Free + Total_Used) * PMM_PAGE_SIZE));

   end Print_PMM_Info;

end x86.pmm.Variant;
