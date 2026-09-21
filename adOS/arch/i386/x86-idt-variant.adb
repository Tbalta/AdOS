------------------------------------------------------------------------------
--                             X86.IDT.VARIANT                              --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Pic;
with SERIAL;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Machine_Code;     use System.Machine_Code;
with Loggers;
with Ada.Interrupts;          use Ada.Interrupts;
with Ada.Interrupts.Names;    use Ada.Interrupts.Names;
with Syscall;
with x86.vmm;
with Ada.Unchecked_Conversion;
with x86.Port_IO;
with Programmable_Interval_Timer;
with Keyboard;
with Util;
package body x86.idt.Variant is
   package Logger renames Loggers;

   function Create_Entry
     (ISR       : System.Address;
      selector  : Unsigned_16;
      DPL       : Cpu_Privilege_Level;
      type_attr : gate_type)
      return idt_entry
   is
      offset : Unsigned_32 := Unsigned_32 (To_Integer (ISR));
   begin
      return
        (offset      => Unsigned_16 (offset and 16#FFFF#),
         selector    => selector,
         DPL         => DPL,
         present     => True,
         offset_high => Unsigned_16 (Shift_Right (offset, 16)),
         entry_type  => type_attr,
         zero        => 0);
   end Create_Entry;

   procedure Print_Stack_Frame (stf : access Stack_Frame)
   is
   begin
      Logger.Log_Info ("eax:" & stf.eax'Image);
      Logger.Log_Info ("ebx:" & stf.ebx'Image);
      Logger.Log_Info ("ecx:" & stf.ecx'Image);
      Logger.Log_Info ("edx:" & stf.edx'Image);
      Logger.Log_Info ("esi:" & stf.esi'Image);
      Logger.Log_Info ("edi:" & stf.edi'Image);
      Logger.Log_Info ("interrupt_code:" & stf.interrupt_code'Image);
      Logger.Log_Info ("error_code:" & stf.error_code'Image);

      Logger.Log_Info ("eip:" & stf.Instruction_Pointer'Image);
      Logger.Log_Info ("cs:" & stf.cs'Image);
      Logger.Log_Info ("eflags:" & stf.eflags'Image);

      Logger.Log_Info ("old_esp:" & stf.old_esp'Image);
      Logger.Log_Info ("old_ss:" & stf.old_ss'Image);
   end Print_Stack_Frame;

   procedure Set_Syscall_Value (stf : access stack_frame; Value : Unsigned_32)
   is
   begin
      stf.eax := Value;
   end Set_Syscall_Value;
   
end x86.idt.Variant;
