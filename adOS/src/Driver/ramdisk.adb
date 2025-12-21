with System.Storage_Elements; use System.Storage_Elements;
with System.Address_To_Access_Conversions;

package body Ramdisk is

   function Read_Block (Ramdisk_Start : System.Address; LBA : Natural; buffer : out Storage_Array) return Integer is

      subtype Read_Array is Storage_Array (1 .. buffer'Length);
      package Conversions is new System.Address_To_Access_Conversions (Read_Array);
      Address : System.Address := Ramdisk_Start + Storage_Count (LBA * SECTOR_SIZE);

      Src    : aliased Conversions.Object_Pointer := Conversions.To_Pointer (Address);
   begin
      buffer := Src.all;
      return buffer'Length;
   end Read_Block;
   
end Ramdisk;