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
with x86.pmm;
with x86.vmm;
with Ada.Unchecked_Conversion;
with x86.Port_IO;
with Programmable_Interval_Timer;
with Keyboard;
with Util;
package body x86.idt.Variant is
   package Logger renames Loggers.Serial_Logger;

   function Create_Entry
     (ISR       : System.Address;
      selector  : Unsigned_16;
      DPL       : Cpu_Privilege_Level;
      type_attr : gate_type) return idt_entry
   is
      offset : Unsigned_64 := Unsigned_64 (To_Integer (ISR));
   begin
      return 
        (offset_low  => Unsigned_16 (offset and 16#FFFF#),
         selector    => selector,
         IST         => 0,
         DPL         => DPL,
         present     => True,
         offset_high => Unsigned_48 (Shift_Right (offset, 16)),
         entry_type  => type_attr,
         zero_1      => 0,
         zero_2      => 0);
   end Create_Entry;

   procedure Print_Stack_Frame (stf : access Stack_Frame)
   is
   begin
      Logger.Log_Info ("rax:" & stf.rax'Image);
      Logger.Log_Info ("rbx:" & stf.rbx'Image);
      Logger.Log_Info ("rcx:" & stf.rcx'Image);
      Logger.Log_Info ("rdx:" & stf.rdx'Image);
      Logger.Log_Info ("rsi:" & stf.rsi'Image);
      Logger.Log_Info ("rdi:" & stf.rdi'Image);
      Logger.Log_Info ("interrupt_code:" & stf.interrupt_code'Image);
      Logger.Log_Info ("error_code:" & stf.error_code'Image);

      Logger.Log_Info ("rip:" & stf.Instruction_Pointer'Image);
      Logger.Log_Info ("cs:" & stf.cs'Image);
      Logger.Log_Info ("rflags:" & stf.rflags'Image);

      Logger.Log_Info ("old_rsp:" & stf.old_esp'Image);
      Logger.Log_Info ("old_ss:" & stf.old_ss'Image);

   end Print_Stack_Frame;

   procedure Set_Syscall_Value (stf : access stack_frame; Value : Unsigned_64)
   is
   begin
      stf.rax := Value;
   end Set_Syscall_Value;
end x86.idt.Variant;
