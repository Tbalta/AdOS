------------------------------------------------------------------------------
--                             X86.VARIANT.GDT                              --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with System.Storage_Elements; use System.Storage_Elements;
with SERIAL;                  use SERIAL;
with System.Machine_Code;     use System.Machine_Code;
with Loggers;
with Util;
with x86.gdt;

package body x86.Variant.gdt is
   package Logger renames Loggers;

   procedure Init_TSS is 
   begin
      Logger.Log_Info
        ("TSS ="
         & " Address: "
         & tss'Address'Image
         & " Size: "
         & Integer ((tss'Size / 8) - 1)'Image);
   end  Init_TSS;


   function Get_Segment (Segment : Segment_Type) return Descriptor_Entry
   is
      base_address : constant System.Address := To_Address (0);
      limit        : constant Unsigned_32 := 16#F_FFFF#;
      use x86.gdt;
   begin
      case Segment is
         when Null_Segment => return (False, Craft_Segment_Descriptor (base_address, 0, 0, 0));
         when Kernel_Code => return (False, Craft_Segment_Descriptor (base_address, limit, 16#9A#, 16#A#));
         when Kernel_Data => return (False, Craft_Segment_Descriptor (base_address, limit, 16#92#, 16#C#));
         when User_Code => return (False, Craft_Segment_Descriptor (base_address, limit, 16#FA#, 16#A#));
         when User_Data => return (False, Craft_Segment_Descriptor (base_address, limit, 16#F2#, 16#C#));
         when TSS_Low   => return (False, Craft_Segment_Descriptor (tss'Address, (tss'Size / 8), 16#89#, 16#0#));
         when TSS_High  => return (True, (base_high => Unsigned_32 (Shift_Right (Unsigned_64 (To_Integer (tss'Address)), 32)), zero => 0));
      end case;
   end Get_Segment;

   procedure Set_Interrupt_Stack (Address : Virtual_Address; Size : Storage_Count) is
      function To_Hex is new Util.To_Hex (Virtual_Address);
   begin
      Logger.Log_Info ("Setting Interrupt stack at: " & To_Hex (Address + Size));
      tss.RSP0 := To_Address (Address) + Size;
   end Set_Interrupt_Stack;

end x86.Variant.gdt;
