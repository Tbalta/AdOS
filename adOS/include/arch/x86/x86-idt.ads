with Interfaces; use Interfaces;

package x86.idt is
   pragma Preelaborate;
   pragma Suppress (Index_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);

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

   type interrupt_vector_t is array (0 .. 255) of idt_entry;
   interrupt_vector : interrupt_vector_t
   with
     Export,
     Alignment => 16,
     Convention => Assembler,
     External_Name => "interrupt_descriptor_table",
     Volatile;

   type error_vector_t is array (0 .. 31) of Unsigned_32;
   type error_vector_ptr_t is access error_vector_t;

   type idt_ptr_t is record
      limit : Unsigned_16;
      base  : Unsigned_32;
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
   procedure handler
     (interrupt_code : Unsigned_32; error_code : Unsigned_32; eip : Unsigned_32; cs : Unsigned_32);
   pragma Export (C, handler, "handler");

   subtype Byte is Interfaces.Unsigned_8;
   type Byte_Array is array (Positive range <>) of Byte;
   subtype Record_Bytes is Byte_Array (1 .. idt_entry'Size / Byte'Size);
   function Convert (Input : idt_entry) return Record_Bytes;

private
end x86.idt;
