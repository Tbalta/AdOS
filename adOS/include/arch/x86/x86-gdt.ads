with x86.Variant; use x86.Variant;
with x86.variant.gdt; use x86.variant.gdt;
with Interfaces; use Interfaces;
with System;     use System;
with System.Storage_Elements; use System.Storage_Elements;

package x86.gdt is
   pragma Preelaborate;


   procedure initialize_gdt;
   procedure Set_Interrupt_Stack (Address : Virtual_Address; Size : Storage_Count) renames x86.Variant.gdt.Set_Interrupt_Stack;
   function Craft_Segment_Descriptor
     (base        : System.Address;
      limit       : Unsigned_32;
      access_byte : Unsigned_8;
      flags       : Unsigned_8) return Segment_Descriptor;



private
   type Global_Descriptor_Table_T is array (Segment_Type) of Descriptor_Entry;
   Global_Descriptor_Table : Global_Descriptor_Table_T
      with Alignment => 16;

   procedure load_gdt (gdtptr_loc : System.Address);
   pragma Import (C, load_gdt, "load_gdt");

   gdt_pointer : Global_Descriptor_Pointer_T;
   pragma Export (C, gdt_pointer, "gdt_pointer");

end x86.gdt;