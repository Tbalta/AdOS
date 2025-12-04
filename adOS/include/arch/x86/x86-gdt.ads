with Interfaces; use Interfaces;
with System;     use System;

package x86.gdt is
   pragma Preelaborate (x86.gdt);

   procedure initialize_gdt;
   procedure set_gdt_entry
     (index       : Integer;
      base        : System.Address;
      limit       : Unsigned_32;
      access_byte : Unsigned_8;
      flags       : Unsigned_8);

   type segment_descriptor is record
      limit_low   : Unsigned_16;
      base_low    : Unsigned_16;
      base_mid    : Unsigned_8;
      access_byte : Unsigned_8;
      limit_high  : Unsigned_8 range 0 .. 3;
      flags       : Unsigned_8 range 0 .. 3;
      base_high   : Unsigned_8;
   end record
   with Size => 64;

   for segment_descriptor use
     record
       limit_low at 0 range 0 .. 15;
       base_low at 0 range 16 .. 31;
       base_mid at 0 range 32 .. 39;
       access_byte at 0 range 40 .. 47;
       limit_high at 0 range 48 .. 51;
       flags at 0 range 52 .. 55;
       base_high at 0 range 56 .. 63;
     end record;

   type TSS_Entry is record
      prev_tss : System.Address := 0;
      esp0     : System.Address := 0;
      ss0      : Unsigned_16 := 0;
      IOPB     : Unsigned_16 := 0;
   end record
   with Size => 16#68# * 8, Alignment => 32;

   for TSS_Entry use
     record
       prev_tss at 0 range 0 .. 31;
       esp0 at 4 range 0 .. 31;
       ss0 at 8 range 0 .. 15;

     end record;

   tss : TSS_Entry
   with Export => True, Convention => C, External_Name => "tss_entry";

   stack : aliased array (1 .. 4096) of Unsigned_8
   with Export => True, Convention => C, External_Name => "tss_stack";

   GDT_ENTRY_COUNT         : constant Integer :=
     6; -- Null, Kernel Code, Kernel Data, User Code, User Data, TSS
   type Global_Descriptor_Table_T is array (0 .. (GDT_ENTRY_COUNT - 1)) of segment_descriptor;
   Global_Descriptor_Table : Global_Descriptor_Table_T
   with Alignment => 16;

   type Global_Descriptor_Pointer_T is record
      limit : Unsigned_16;
      base  : System.Address;
   end record
   with Size => 48;

   for Global_Descriptor_Pointer_T use
     record
       limit at 0 range 0 .. 15;
       base at 0 range 16 .. 47;
     end record;

   gdt_pointer : Global_Descriptor_Pointer_T
   with Export => True, Convention => C, External_Name => "gdt_pointer";
private
   procedure load_gdt (gdtptr_loc : Interfaces.Unsigned_32)
   with Import => True, Convention => C, External_Name => "load_gdt";

end x86.gdt;
