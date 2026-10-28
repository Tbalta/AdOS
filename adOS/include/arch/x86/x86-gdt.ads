with Interfaces; use Interfaces;
with System;     use System;
with System.Storage_Elements; use System.Storage_Elements;

package x86.gdt is
   pragma Preelaborate;


      -- Figure 3-8. Segment Descriptor
   type Segment_Descriptor is record
      limit_low   : Unsigned_16;
      base_low    : Unsigned_16;
      base_mid    : Unsigned_8;
      access_byte : Unsigned_8;
      limit_high  : Unsigned_4;
      flags       : Unsigned_4;
      base_high   : Unsigned_8;
   end record
   with Size => 64;

   for Segment_Descriptor use
     record
       limit_low at 0 range 0 .. 15;
       base_low at 0 range 16 .. 31;
       base_mid at 0 range 32 .. 39;
       access_byte at 0 range 40 .. 47;
       limit_high at 0 range 48 .. 51;
       flags at 0 range 52 .. 55;
       base_high at 0 range 56 .. 63;
     end record;

   type Global_Descriptor_Pointer_T is record
      limit : Unsigned_16;
      base  : System.Address;
   end record;
   pragma Pack (Global_Descriptor_Pointer_T);


   procedure initialize_gdt;
--    procedure Set_Interrupt_Stack (Address : Virtual_Address; Size : Storage_Count) renames x86.gdt.Variant.Set_Interrupt_Stack;
   function Craft_Segment_Descriptor
     (base        : System.Address;
      limit       : Unsigned_32;
      access_byte : Unsigned_8;
      flags       : Unsigned_8) return Segment_Descriptor;



private
   procedure load_gdt (gdtptr_loc : System.Address);
   pragma Import (C, load_gdt, "load_gdt");
end x86.gdt;