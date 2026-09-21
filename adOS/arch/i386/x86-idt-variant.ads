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

   subtype Register_Type is Unsigned_32;

   type stack_frame (Privilege_Level_Change : Boolean := False) is record
      eax            : Unsigned_32;
      ebx            : Unsigned_32;
      ecx            : Unsigned_32;
      edx            : Unsigned_32;
      esi            : Unsigned_32;
      edi            : Unsigned_32;
      interrupt_code : Unsigned_32;
      error_code     : Unsigned_32;

      Instruction_Pointer    : System.Address;
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
       eax at 0 range 0 .. 31;
       ebx at 4 range 0 .. 31;
       ecx at 8 range 0 .. 31;
       edx at 12 range 0 .. 31;
       esi at 16 range 0 .. 31;
       edi at 20 range 0 .. 31;
       interrupt_code at 24 range 0 .. 31;
       error_code at 28 range 0 .. 31;
       Instruction_Pointer at 32 range 0 .. 31;
       cs at 36 range 0 .. 31;
       eflags at 40 range 0 .. 31;
       old_esp at 44 range 0 .. 31;
       old_ss at 48 range 0 .. 31;
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

   type idt_entry is record
      offset      : Unsigned_16;
      selector    : Unsigned_16;
      entry_type  : gate_type;
      zero        : Unsigned_8 range 0 .. 1;
      DPL         : Cpu_Privilege_Level;
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

   function Create_Entry
     (ISR       : System.Address;
      selector  : Unsigned_16;
      DPL       : Cpu_Privilege_Level;
      type_attr : gate_type) return idt_entry;


   procedure Print_Stack_Frame (stf : access Stack_Frame);
   function Get_Syscall_Number (stf : access stack_frame) return Unsigned_32 is (stf.eax);
   function Get_Arg1 (stf : access stack_frame) return Unsigned_32 is (stf.ebx);
   function Get_Arg2 (stf : access stack_frame) return Unsigned_32 is (stf.ecx);
   function Get_Arg3 (stf : access stack_frame) return Unsigned_32 is (stf.edx);
   function Get_Arg4 (stf : access stack_frame) return Unsigned_32 is (stf.esi);
   function Get_Arg5 (stf : access stack_frame) return Unsigned_32 is (stf.edi);
   procedure Set_Syscall_Value (stf : access stack_frame; Value : Unsigned_32);


private
end x86.idt.Variant;
