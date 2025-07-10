with System.Storage_Elements; use System.Storage_Elements;
with SERIAL;                  use SERIAL;
with System.Machine_Code;     use System.Machine_Code;
with x86.gdt;
package body x86.gdt is
   use Standard.ASCII;
   pragma Suppress (Index_Check);
   pragma Suppress (Range_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);

   procedure set_gdt_entry
     (index       : Integer; base : System.Address; limit : Unsigned_32;
      access_byte : Unsigned_8; flags : Unsigned_8)
   is
      base_integer : constant Unsigned_32 := Unsigned_32 (To_Integer (base));
   begin
      Global_Descriptor_Table (index) :=
        (base_low    => Unsigned_16 (base_integer and 16#FFFF#),
         base_mid    => Unsigned_8 (Shift_Right (base_integer, 16) and 16#FF#),
         base_high   => Unsigned_8 (Shift_Right (base_integer, 24)),
         limit_low   => Unsigned_16 (limit), flags => (flags and 16#F#),
         access_byte => (access_byte),
         limit_high  => Unsigned_8 ((Shift_Right (limit, 16)) and 16#F#));
   end set_gdt_entry;


   procedure flush_tss is
   begin 
      ASM (
         "xor %%eax, %%eax" & LF &
         "mov $(5 * 8), %%ax" & LF &
         "ltr %%ax",
            Volatile => True,
            Clobber => "eax");
   end flush_tss;

   function Convert (Input : Global_Descriptor_Pointer_T) return Record_Bytes
   is
      Result : constant Record_Bytes;
      for Result'Address use Input'Address;
      pragma Import (Convention => Ada, Entity => Result);
   begin
      return Result;
   end Convert;

   procedure initialize_gdt is
      base_address : constant System.Address := To_Address (0);
      limit        : constant Unsigned_32    := 16#F_FFFF#;

      procedure memset
        (Address : System.Address; Value : Unsigned_8; Size : Unsigned_32);
      pragma Import (C, memset, "memset");
   begin
      set_gdt_entry (0, base_address, 0, 0, 0); -- Null descriptor
      set_gdt_entry
        (1, base_address, limit, 16#9A#, 16#C#); -- Kernel Code descriptor
      set_gdt_entry
        (2, base_address, limit, 16#92#, 16#C#); -- Kernel Data descriptor
      set_gdt_entry
        (3, base_address, limit, 16#FA#, 16#C#); -- User Code descriptor
      set_gdt_entry
        (4, base_address, limit, 16#F2#, 16#C#); -- User Data descriptor

      set_gdt_entry (5, tss'Address, (tss'Size / 8), 16#89#, 16#0#); -- TSS descriptor
      memset (tss'Address, 0, tss'Size / 8);

      SERIAL.send_line ("tss'Address: " & tss'Address'Image);
      SERIAL.send_line ("tss'Size: " & Integer ((tss'Size / 8) - 1)'Image);

      tss.prev_tss := 0;
      tss.esp0     := stack'Address + To_Address (stack'Length * 8); -- Stack for kernel mode
      tss.ss0      := 16#10#; -- Kernel Data Segment

      gdt_pointer.limit := (Global_Descriptor_Table'Size - 1) / 8;
      gdt_pointer.base  := Global_Descriptor_Table'Address;

      send_line ("gdt_pointer'Address: " & gdt_pointer'Address'Image);
      send_line ("gdt_pointer.base: " & gdt_pointer.base'Image);
      send_line ("gdt_pointer.limit: " & gdt_pointer.limit'Image);
     
      for i in Global_Descriptor_Table'Range loop
         send_line
           ("GDT[" & Integer (i)'Image & "] = " &
            " Base: " & Global_Descriptor_Table (i).base_low'Image &
            " Mid: " & Global_Descriptor_Table (i).base_mid'Image &
            " High: " & Global_Descriptor_Table (i).base_high'Image &
            " Limit: " & Global_Descriptor_Table (i).limit_low'Image &
            " Flags: " & Global_Descriptor_Table (i).flags'Image &
            " Access Byte: " & Global_Descriptor_Table (i).access_byte'Image &
            " Limit High: " & Global_Descriptor_Table (i).limit_high'Image);
      end loop;
      load_gdt (Unsigned_32 (To_Integer (gdt_pointer'Address)));
      send_line ("gdt loaded");
      flush_tss;
      send_line ("tss flushed");
   end initialize_gdt;
end x86.gdt;
