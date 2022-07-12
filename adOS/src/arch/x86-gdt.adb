with System.Storage_Elements; use System.Storage_Elements;
with SERIAL;                  use SERIAL;
package body x86.gdt is
   pragma Suppress (Index_Check);
   pragma Suppress (Range_Check);

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

      send_string ("gdt is set");
      gdt_pointer.limit := (Global_Descriptor_Table'Size - 1) / 8;
      gdt_pointer.base  := Global_Descriptor_Table'Address;
      send_uint (Unsigned_32 (gdt_pointer.limit));
      send_string (" ");
      send_uint (Unsigned_32 (To_Integer (gdt_pointer.base)));
      send_string (" ");
      send_hex (Unsigned_32 (To_Integer (gdt_pointer.base)));
      send_string (" ");
      send_hex (Unsigned_32 (To_Integer (gdt_pointer'Address)));
      send_string ("dump of gdt");
      declare
         test : constant Record_Bytes := Convert (gdt_pointer);
      begin
         for item in test'Range loop
            send_string (" ");
            send_hex (Unsigned_32 (test (item)));
         end loop;
      end;
      load_gdt (Unsigned_32 (To_Integer (gdt_pointer'Address)));
   end initialize_gdt;
end x86.gdt;
