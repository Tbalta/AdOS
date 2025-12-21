with System.Storage_Elements; use System.Storage_Elements;

package Ramdisk is
   pragma Pure;
   function Read_Block (Ramdisk_Start : System.Address; LBA : Natural; buffer : out Storage_Array) return Integer;

private
   SECTOR_SIZE : constant Integer := 2_048;
end Ramdisk;