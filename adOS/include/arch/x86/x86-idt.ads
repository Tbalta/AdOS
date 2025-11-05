with Interfaces; use Interfaces;
with Ada.Interrupts; use Ada.Interrupts;

package x86.idt is
   pragma Preelaborate;
   pragma Suppress (Index_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);

   type stack_frame (Privilege_Level_Change : Boolean := False) is record
      eax            : Unsigned_32;
      ebx            : Unsigned_32;
      ecx            : Unsigned_32;
      edx            : Unsigned_32;
      esi            : Unsigned_32;
      edi            : Unsigned_32;
      interrupt_code : Unsigned_32;
      error_code     : Unsigned_32;

      eip    : Unsigned_32;
      cs     : Unsigned_32;
      eflags : Unsigned_32;

      case Privilege_Level_Change is
         when True =>
            old_esp : Unsigned_32;
            old_ss  : Unsigned_32;

         when False =>
            null;
      end case;
   end record
   with Pack => True, Volatile;

   --!format off
   for stack_frame use
     record
         eax             at 0 range 0 .. 31;
         ebx             at 4 range 0 .. 31;
         ecx             at 8 range 0 .. 31;
         edx             at 12 range 0 .. 31;
         esi             at 16 range 0 .. 31;
         edi             at 20 range 0 .. 31;
         interrupt_code  at 24 range 0 .. 31;
         error_code      at 28 range 0 .. 31;
         eip             at 32 range 0 .. 31;
         cs              at 36 range 0 .. 31;
         eflags          at 40 range 0 .. 31;
         old_esp         at 44 range 0 .. 31;
         old_ss          at 48 range 0 .. 31;
     end record;
   --!format on

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
   for error_vector_t'Component_Size use 32;
   type error_vector_ptr_t is access error_vector_t;

   type idt_ptr_t is record
      limit : Unsigned_16;
      base  : System.Address;
   end record
   with Size => 48;
   for idt_ptr_t use
     record
       limit at 0 range 0 .. 15;
       base at 0 range 16 .. 47;
     end record;

   error_vector : error_vector_t;
   pragma Import (C, error_vector, "x86_handler_vector");
   procedure init_idt;
   procedure Handler (stf : access stack_frame);
   pragma Export (C, handler, "ada_interrupt_handler");

private
end x86.idt;
