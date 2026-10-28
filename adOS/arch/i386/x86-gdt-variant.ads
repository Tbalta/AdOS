------------------------------------------------------------------------------
--                             X86.GDT.VARIANT                              --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces; use Interfaces;
with System;     use System;
with System.Storage_Elements; use System.Storage_Elements;
package x86.gdt.Variant is
   pragma Preelaborate;

   type Segment_Type is (Null_Segment, Kernel_Code, Kernel_Data, User_Code, User_Data, TSS_Low);
   for Segment_Type use (Null_Segment => 0, Kernel_Code => 1, Kernel_Data => 2, User_Code => 3, User_Data => 4, TSS_Low => 5);

   procedure Init_TSS;
   procedure Set_Interrupt_Stack (Address : Virtual_Address; Size : Storage_Count);

   subtype Descriptor_Entry is segment_descriptor;
   function Get_Segment (Segment : Segment_Type) return Descriptor_Entry;

   -- Vol-3.9.2.1 Figure 9-2. 32-Bit Task-State Segment (TSS)
   type TSS_Entry is record
      prev_tss : Address := 0;
      esp0     : Address := 0;
      ss0      : Unsigned_16 := 0;
      IOPB     : Unsigned_16 := 0;
   end record
   with Size => 16#68# * 8;

   for TSS_Entry use
     record
       prev_tss at 0 range 0 .. 31;
       esp0 at 4 range 0 .. 31;
       ss0 at 8 range 0 .. 15;

     end record;

private
   tss : TSS_Entry;

   stack : aliased array (1 .. 8192) of aliased Unsigned_8
   with Export => True,
        Convention => C,
        External_Name => "tss_stack",
        Size => 8192 * 8;

end x86.gdt.Variant;
