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
   with Size => 32;

   for Page_Fault_Error_Code use
     record
       Present at 0 range 0 .. 0;
       Write at 0 range 1 .. 1;
       User_Mode at 0 range 2 .. 2;
       Instruction_Fetch at 0 range 4 .. 4;
     end record;

   type Handler_Proc is access procedure (stf : stack_frame);

   type gate_type is
     (task_gate, interrupt_16_bits, trap_gate_16_bits, interrupt_32_bits, trap_gate_32_bits)
   with Size => 4;
   for gate_type use
     (task_gate         => 16#5#,
      interrupt_16_bits => 16#6#,
      trap_gate_16_bits => 16#7#,
      interrupt_32_bits => 16#E#,
      trap_gate_32_bits => 16#F#);

   type idt_entry is record
      offset      : Unsigned_16;
      selector    : Unsigned_16;
      entry_type  : gate_type;
      zero        : Unsigned_8 range 0 .. 1;
      DPL         : Unsigned_8 range 0 .. 3;
      present     : Boolean;
      offset_high : Unsigned_16;
   end record
   with Size => 64;
   for idt_entry use
     record
       offset at 0 range 0 .. 15;
       selector at 0 range 16 .. 31;
       entry_type at 0 range 40 .. 43;
       zero at 0 range 44 .. 44;
       DPL at 0 range 45 .. 46;
       present at 0 range 47 .. 47;
       offset_high at 0 range 48 .. 63;
     end record;

   type interrupt_vector_t is array (Interrupt_Id'Range) of idt_entry;
   interrupt_vector : interrupt_vector_t
   with
     Export,
     Alignment => 16,
     Convention => Assembler,
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
