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
   package Logger renames Loggers;

   function To_Hex is new Util.To_Hex (Register_Type);
   function To_Hex is new Util.To_Hex (System.Address);

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
      Logger.Log_Info ("eax:" & To_Hex (stf.eax));
      Logger.Log_Info ("ebx:" & To_Hex (stf.ebx));
      Logger.Log_Info ("ecx:" & To_Hex (stf.ecx));
      Logger.Log_Info ("edx:" & To_Hex (stf.edx));
      Logger.Log_Info ("esi:" & To_Hex (stf.esi));
      Logger.Log_Info ("edi:" & To_Hex (stf.edi));
      Logger.Log_Info ("interrupt_code:" & stf.interrupt_code'Image);
      Logger.Log_Info ("error_code:" & stf.error_code'Image);

      Logger.Log_Info ("eip:" & To_Hex (stf.Instruction_Pointer));
      Logger.Log_Info ("cs:" & stf.cs'Image);
      Logger.Log_Info ("eflags:" & To_Hex (stf.eflags));

      Logger.Log_Info ("old_esp:" & To_Hex (stf.old_esp));
      Logger.Log_Info ("old_ss:" & stf.old_ss'Image);
   end Print_Stack_Frame;

   procedure Set_Syscall_Value (stf : access stack_frame; Value : Unsigned_32)
   is
   begin
      stf.eax := Value;
   end Set_Syscall_Value;
   
end x86.idt.Variant;
