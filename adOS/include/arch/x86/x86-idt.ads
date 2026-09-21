------------------------------------------------------------------------------
--                             X86.IDT.VARIANT                              --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces;     use Interfaces;
with Ada.Interrupts; use Ada.Interrupts;

package x86.idt is
   pragma Preelaborate;


   type gate_type is
     (interrupt_gate, trap_gate)
   with Size => 4;
   for gate_type use
     (interrupt_gate => 16#E#,
      trap_gate => 16#F#);

   type Cpu_Privilege_Level is
     (CPL0, CPL1, CPL2, CPL3);
   for Cpu_Privilege_Level use
     (CPL0 => 0,
      CPL1 => 1,
      CPL2 => 2,
      CPL3 => 3);

   type idt_ptr_t is record
      limit : Unsigned_16;
      base  : System.Address;
   end record;
   pragma Pack (idt_ptr_t);


   procedure init_idt;

private
   type error_vector_t is array (Interrupt_Id range 0 .. 31) of System.Address;
   for error_vector_t'Component_Size use System.Address'Size;
   type error_vector_ptr_t is access error_vector_t;

   error_vector : error_vector_t;
   pragma Import (C, error_vector, "x86_handler_vector");
end x86.idt;
