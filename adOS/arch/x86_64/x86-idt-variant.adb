------------------------------------------------------------------------------
--                             X86.IDT.VARIANT                              --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with System;
with Loggers;
with Util;

with Arch; use Arch;
package body x86.idt.Variant is
   package Logger renames Loggers.Serial_Logger;

   function To_Hex is new Util.To_Hex (Register_Type);
   function To_Hex is new Util.To_Hex (System.Address);

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
      Logger.Log_Info ("rax:" & To_Hex (stf.rax));
      Logger.Log_Info ("rbx:" & To_Hex (stf.rbx));
      Logger.Log_Info ("rcx:" & To_Hex (stf.rcx));
      Logger.Log_Info ("rdx:" & To_Hex (stf.rdx));
      Logger.Log_Info ("rsi:" & To_Hex (stf.rsi));
      Logger.Log_Info ("rdi:" & To_Hex (stf.rdi));
      Logger.Log_Info ("interrupt_code:" & stf.interrupt_code'Image);
      Logger.Log_Info ("error_code:" & stf.error_code'Image);

      Logger.Log_Info ("rip:" & To_Hex (stf.Instruction_Pointer));
      Logger.Log_Info ("cs:" & stf.cs'Image);
      Logger.Log_Info ("rflags:" & To_Hex (stf.rflags));

      Logger.Log_Info ("old_rsp:" & To_Hex (stf.old_esp));
      Logger.Log_Info ("old_ss:" & stf.old_ss'Image);
   end Print_Stack_Frame;

   procedure Set_Syscall_Value (stf : access stack_frame; Value : Unsigned_64)
   is
   begin
      stf.rax := Value;
   end Set_Syscall_Value;
end x86.idt.Variant;
