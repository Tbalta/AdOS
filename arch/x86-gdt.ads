with Interfaces; use Interfaces;
with System;     use System;
package x86.gdt is
   pragma Preelaborate (x86.gdt);

   procedure initialize_gdt;
   procedure set_gdt_entry
     (index       : Integer; base : System.Address; limit : Unsigned_32;
      access_byte : Unsigned_8; flags : Unsigned_8);

   type segment_descriptor is record
      limit_low   : Unsigned_16;
      base_low    : Unsigned_16;
      base_mid    : Unsigned_8;
      access_byte : Unsigned_8;
      limit_high  : Unsigned_8 range 0 .. 3;
      flags       : Unsigned_8 range 0 .. 3;
      base_high   : Unsigned_8;
   end record with
      Size => 64;

   for segment_descriptor use record
      limit_low   at 0 range  0 .. 15;
      base_low    at 0 range 16 .. 31;
      base_mid    at 0 range 32 .. 39;
      access_byte at 0 range 40 .. 47;
      limit_high  at 0 range 48 .. 51;
      flags       at 0 range 52 .. 55;
      base_high   at 0 range 56 .. 63;
   end record;

   GDT_ENTRY_COUNT : constant Integer := 6;
   type Global_Descriptor_Table_T is
     array (0 .. (GDT_ENTRY_COUNT - 1)) of segment_descriptor;
   Global_Descriptor_Table : Global_Descriptor_Table_T with
      Alignment => 16;

   type Global_Descriptor_Pointer_T is record
      limit : Unsigned_16;
      base  : System.Address;
   end record with
      Size => 48;

   for Global_Descriptor_Pointer_T use record
      limit at 0 range  0 .. 15;
      base  at 0 range 16 .. 47;
   end record;

   gdt_pointer : Global_Descriptor_Pointer_T with
      Export        => True,
      Convention    => C,
      External_Name => "gdt_pointer";
private
   procedure load_gdt (gdtptr_loc : Interfaces.Unsigned_32) with
      Import        => True,
      Convention    => C,
      External_Name => "load_gdt";

   subtype Byte is Interfaces.Unsigned_8;
   type Byte_Array is array (Positive range <>) of Byte;
   subtype Record_Bytes is
     Byte_Array (1 .. Global_Descriptor_Pointer_T'Size / Byte'Size);
   function Convert (Input : Global_Descriptor_Pointer_T) return Record_Bytes;

end x86.gdt;
