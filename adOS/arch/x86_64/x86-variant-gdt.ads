------------------------------------------------------------------------------
--                             X86.VARIANT.GDT                              --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces; use Interfaces;
with System;     use System;
with System.Storage_Elements; use System.Storage_Elements;
package x86.Variant.gdt is
   pragma Preelaborate;

   type Segment_Type is (Null_Segment, Kernel_Code, Kernel_Data, User_Code, User_Data, TSS_Low, TSS_High);
   for Segment_Type use (Null_Segment => 0, Kernel_Code => 1, Kernel_Data => 2, User_Code => 3, User_Data => 4, TSS_Low => 5, TSS_High => 6);
   
   procedure Init_TSS;
   procedure Set_Interrupt_Stack (Address : Virtual_Address; Size : Storage_Count);

      ------------------------------------------------------------------
      -- Figure 9-4. Format of TSS and LDT Descriptors in 64-bit Mode --
      ------------------------------------------------------------------
--    +-----------------------------------+----------+--------------------+
--    |31                               13|12       8|7                  0|  4
--    |              reserved             | zero     |     reserved       |  
--    +-----------------------------------+----------+--------------------+

--    +---------------------------------+---------------------------------+
--    |31                                                                0|  0
--    |              base[63:32]                                          |  
--    +-------------------------------------------------------------------+
   type TSS_Descriptor_High is record
      base_high : Unsigned_32;
      zero : Unsigned_4 := 0;
   end record
      with Size => 64,
         Dynamic_Predicate => zero = 0;
   for TSS_Descriptor_High use
       record
         base_high at 0 range 0 .. 31;
         zero at 4 range 8 .. 12;
       end record;

   -- In 64-bit a descriptor is either a classical segment or a the higher part of the TSS
   type Descriptor_Entry (TSS_Second_Part : Boolean := False) is record
      case TSS_Second_Part is
         when False =>
            descriptor : segment_descriptor;
         when True =>
            tss_descriptor : TSS_Descriptor_High;
      end case;
   end record
      with Size => 64;
   pragma Unchecked_Union (Descriptor_Entry);
   function Get_Segment (Segment : Segment_Type) return Descriptor_Entry;

   ------------------------------------
   -- Figure 9-11. 64-Bit TSS Format --
   ------------------------------------
   type TSS_Entry is record
      RSP0     : System.Address := 0;
      RSP1     : System.Address := 0;
      RSP2     : System.Address := 0;
      IST1     : System.Address := 0;
      IST2     : System.Address := 0;
      IST3     : System.Address := 0;
      IST4     : System.Address := 0;
      IST5     : System.Address := 0;
      IST6     : System.Address := 0;
      IST7     : System.Address := 0;
      IOPB     : Unsigned_16 := 0;
   end record
   with Size => 104 * 8;

   for TSS_Entry use
     record
         RSP0 at 4  range 0 .. 63;
         RSP1 at 12 range 0 .. 63;
         RSP2 at 20 range 0 .. 63;
         IST1 at 36 range 0 .. 63;
         IST2 at 44 range 0 .. 63;
         IST3 at 52 range 0 .. 63;
         IST4 at 60 range 0 .. 63;
         IST5 at 68 range 0 .. 63;
         IST6 at 76 range 0 .. 63;
         IST7 at 84 range 0 .. 63;
         IOPB at 100 range 15 .. 31;
     end record;

private
   tss : TSS_Entry;
end x86.Variant.gdt;
