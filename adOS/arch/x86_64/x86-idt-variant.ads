------------------------------------------------------------------------------
--                             X86.IDT.VARIANT                              --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces;     use Interfaces;
with Ada.Interrupts; use Ada.Interrupts;

package x86.idt.Variant is
   pragma Preelaborate;

   subtype Register_Type is Unsigned_64;

   type stack_frame (Privilege_Level_Change : Boolean := False) is record
      rax            : Unsigned_64;
      rbx            : Unsigned_64;
      rcx            : Unsigned_64;
      rdx            : Unsigned_64;
      rsi            : Unsigned_64;
      rdi            : Unsigned_64;
      r8             : Unsigned_64;
      r9             : Unsigned_64;
      r10            : Unsigned_64;
      r11            : Unsigned_64;
      r12            : Unsigned_64;
      r13            : Unsigned_64;
      r14            : Unsigned_64;
      r15            : Unsigned_64;

      interrupt_code : Unsigned_64;
      error_code     : Unsigned_64;

      Instruction_Pointer : System.Address;
      cs     : Unsigned_64;
      rflags : Unsigned_64;

      case Privilege_Level_Change is
         when True =>
            old_esp : Unsigned_64;
            old_ss  : Unsigned_64;

         when False =>
            null;
      end case;
   end record
   with Pack => True, Volatile;
   pragma Unchecked_Union(stack_frame);

   --!format off
   for stack_frame use
     record
       rax at 0 range 0 .. 63;
       rbx at 8 range 0 .. 63;
       rcx at 16 range 0 .. 63;
       rdx at 24 range 0 .. 63;
       rsi at 32 range 0 .. 63;
       rdi at 40 range 0 .. 63;
       r8  at 48 range 0 .. 63;
       r9  at 56 range 0 .. 63;
       r10 at 64 range 0 .. 63;
       r11 at 72 range 0 .. 63;
       r12 at 80 range 0 .. 63;
       r13 at 88 range 0 .. 63;
       r14 at 96 range 0 .. 63;
       r15 at 104 range 0 .. 63;
       interrupt_code at 112 range 0 .. 63;
       error_code at 120 range 0 .. 63;
       Instruction_Pointer at 128 range 0 .. 63;
       cs at 136 range 0 .. 63;
       rflags at 144 range 0 .. 63;
       old_esp at 152 range 0 .. 63;
       old_ss at 160 range 0 .. 63;
     end record;
   --!format on

   type Page_Fault_Error_Code is record
      Present           : Boolean := False;
      Write             : Boolean := False;
      User_Mode         : Boolean := False;
      Instruction_Fetch : Boolean := False;
   end record
   with Size => 64;

   for Page_Fault_Error_Code use
     record
       Present at 0 range 0 .. 0;
       Write at 0 range 1 .. 1;
       User_Mode at 0 range 2 .. 2;
       Instruction_Fetch at 0 range 4 .. 4;
     end record;

   -- Figure 7-8. 64-Bit IDT Gate Descriptors --
--    +-------------------------------------------------------------------+
--    |31                                                                0|  12
--    |                       reserved                                    |
--    +-------------------------------------------------------------------+

--    +-------------------------------------------------------------------+
--    |31                                                                0|  8
--    |                       Offset[63:32]                               |
--    +-------------------------------------------------------------------+

--    +---------------------------------+----+-----+---+------+------+----+
--    |31                             16| 15 |14 13|12 |11   8|7    3|2  0|  4
--    |           Offset                | P  | DPL | 0 | Type | 0    | IST|
--    +---------------------------------+----+-----+---+------+------+----+

--    +---------------------------------+---------------------------------+
--    |31                             16|15                              0|  0
--    |              Segment Selector   |    Offset[15:0]                 |  
--    +-------------------------------------------------------------------+
   type idt_entry is record
      offset_low  : Unsigned_16;
      selector    : Unsigned_16;

      IST         : Unsigned_3;
      zero_1      : Unsigned_5;
      entry_type  : gate_type;
      zero_2      : Unsigned_1;
      DPL         : Cpu_Privilege_Level;
      present     : Boolean;

      offset_high : Unsigned_48;
   end record
      with Size => 4 * 32;

   for idt_entry use
     record
       offset_low at 0 range 0 .. 15;
       selector at 0 range 16 .. 31;

       IST at 4 range 0 .. 2;
       zero_1 at 4 range 3 .. 7;
       entry_type at 4 range 8 .. 11;
       zero_2 at 4 range 12 .. 12;
       DPL at 4 range 13 .. 14;
       present at 4 range 15 .. 15;

       offset_high at 4 range 16 .. 63;
     end record;

   function Create_Entry
     (ISR       : System.Address;
      selector  : Unsigned_16;
      DPL       : Cpu_Privilege_Level;
      type_attr : gate_type) return idt_entry;

   
   procedure Print_Stack_Frame (stf : access Stack_Frame);
   function Get_Syscall_Number (stf : access stack_frame) return Unsigned_64 is (stf.rax);
   function Get_Arg1 (stf : access stack_frame) return Unsigned_64 is (stf.rbx);
   function Get_Arg2 (stf : access stack_frame) return Unsigned_64 is (stf.rcx);
   function Get_Arg3 (stf : access stack_frame) return Unsigned_64 is (stf.rdx);
   function Get_Arg4 (stf : access stack_frame) return Unsigned_64 is (stf.rsi);
   function Get_Arg5 (stf : access stack_frame) return Unsigned_64 is (stf.rdi);
   procedure Set_Syscall_Value (stf : access stack_frame; Value : Unsigned_64);

private
end x86.idt.Variant;
