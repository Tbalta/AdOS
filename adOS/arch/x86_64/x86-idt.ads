with Interfaces;     use Interfaces;
with Ada.Interrupts; use Ada.Interrupts;

package x86.idt is
   pragma Preelaborate;
   --  pragma Suppress (Index_Check);
   --  pragma Suppress (Overflow_Check);
   --  pragma Suppress (All_Checks);

   type stack_frame (Privilege_Level_Change : Boolean := False) is record
      rax            : Unsigned_64;
      rbx            : Unsigned_64;
      rcx            : Unsigned_64;
      rdx            : Unsigned_64;
      rsi            : Unsigned_64;
      rdi            : Unsigned_64;
      interrupt_code : Unsigned_64;
      error_code     : Unsigned_64;

      rip    : Unsigned_64;
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
       interrupt_code at 48 range 0 .. 63;
       error_code at 56 range 0 .. 63;
       rip at 64 range 0 .. 63;
       cs at 72 range 0 .. 63;
       rflags at 80 range 0 .. 63;
       old_esp at 88 range 0 .. 63;
       old_ss at 96 range 0 .. 63;
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

   type Handler_Proc is access procedure (stf : stack_frame);

   type gate_type is
     (interrupt_64_bits, trap_gate_64_bits)
   with Size => 4;
   for gate_type use
     (interrupt_64_bits => 16#E#,
      trap_gate_64_bits => 16#F#);

   type Cpu_Privilege_Level is
     (CPL0, CPL1, CPL2, CPL3);
   for Cpu_Privilege_Level use
     (CPL0 => 0,
      CPL1 => 1,
      CPL2 => 2,
      CPL3 => 3);


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
         --    Dynamic_Predicate => (
         --     present = True and zero_1 = 0 and zero_2 = 0);

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

   type interrupt_vector_t is array (Interrupt_Id'Range) of idt_entry;
   interrupt_vector : interrupt_vector_t
   with
     Export,
     Alignment => 16,
     External_Name => "interrupt_descriptor_table",
     Volatile;

   type error_vector_t is array (Interrupt_Id range 0 .. 31) of System.Address;
   for error_vector_t'Component_Size use 64;
   type error_vector_ptr_t is access error_vector_t;

   type idt_ptr_t is record
      limit : Unsigned_16;
      base  : System.Address;
   end record
   with Size => 80;
   for idt_ptr_t use
     record
       limit at 0 range 0 .. 15;
       base at 0 range 16 .. 79;
     end record;

   error_vector : error_vector_t;
   pragma Import (C, error_vector, "x86_handler_vector");
   procedure init_idt;
   procedure Handler (stf : access stack_frame);
   pragma Export (C, handler, "ada_interrupt_handler");

private
end x86.idt;
