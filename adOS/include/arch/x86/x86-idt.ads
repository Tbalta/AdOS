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
with Arch;           use Arch;
package x86.idt is
   pragma Preelaborate;

   -- Vol.3.3.5.1 - Table 3-2. System-Segment and Gate-Descriptor Types
   type gate_type is (interrupt_gate, trap_gate)
      with Size => 4;
   for gate_type use (interrupt_gate => 16#E#, trap_gate => 16#F#);

   type Cpu_Privilege_Level is
     (CPL0, CPL1, CPL2, CPL3);
   for Cpu_Privilege_Level use
     (CPL0 => 0,
      CPL1 => 1,
      CPL2 => 2,
      CPL3 => 3);

   -- Vol.3.2.4.1 Figure 2-6. Memory Management Registers
   type idt_ptr_t is record
      limit : Unsigned_16;
      base  : System.Address;
   end record;
   pragma Pack (idt_ptr_t);

   -- Vol.3.7.15 - Figure 7-11. Page-Fault Error Code
   type Page_Fault_Error_Code is record
      Present           : Boolean := False;
      Write             : Boolean := False;
      User_Mode         : Boolean := False;
      Instruction_Fetch : Boolean := False;
   end record
   with Size => Register_Type'Size;

   for Page_Fault_Error_Code use
     record
       Present at 0 range 0 .. 0;
       Write at 0 range 1 .. 1;
       User_Mode at 0 range 2 .. 2;
       Instruction_Fetch at 0 range 4 .. 4;
     end record;


   procedure init_idt;

private
   type error_vector_t is array (Interrupt_Id range 0 .. 31) of System.Address;
   for error_vector_t'Component_Size use System.Address'Size;
   type error_vector_ptr_t is access error_vector_t;

   error_vector : error_vector_t;
   pragma Import (C, error_vector, "x86_handler_vector");
end x86.idt;
