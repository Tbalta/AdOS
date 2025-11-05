with SERIAL;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Machine_Code;     use System.Machine_Code;
with Log;
with Ada.Interrupts;          use Ada.Interrupts;
with Ada.Interrupts.Names;    use Ada.Interrupts.Names;


package body x86.idt is
   pragma Suppress (Index_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);

   package Logger renames Log.Serial_Logger;

   procedure add_entry
     (index     : Interrupt_ID;
      ISR       : System.Address;
      selector  : Unsigned_16;
      DPL       : Unsigned_8;
      type_attr : gate_type)
   is
      offset : Unsigned_32 := Unsigned_32 (To_Integer (ISR));
   begin
      interrupt_vector (index) :=
        (offset      => Unsigned_16 (offset),
         selector    => selector,
         DPL         => DPL and 2#11#,
         present     => True,
         offset_high => Unsigned_16 (Shift_Right (offset, 16)),
         entry_type  => type_attr,
         zero        => 0);
   end add_entry;

   procedure load_idt (idt_ptr : idt_ptr_t)
   is
   begin
      ASM
        ("lidt (%0)",
         Inputs     => System.Address'Asm_Input ("r", idt_ptr'Address),
         Volatile => True);
   end load_idt;

   procedure init_idt is
      procedure timer_callback;
      procedure syscall;
      pragma Import (C, timer_callback, "isr_stub_32");
      pragma Import (C, syscall, "isr_stub_128");
      idt_ptr : idt_ptr_t;
   begin
      for i in error_vector_t'Range loop
         add_entry (i, error_vector (i), 8, 0, trap_gate_32_bits);
      end loop;
      add_entry (TIMER_INTERRUPT, timer_callback'Address, 8, 0, interrupt_32_bits);
      add_entry (SYSCALL_INTERRUPT, syscall'Address, 8, 3, interrupt_32_bits);
      idt_ptr.base := interrupt_vector'Address;
      idt_ptr.limit := interrupt_vector'Size / 8 - 1;

      Logger.Log_Info ("idt = size: " & idt_ptr.limit'Image & " base: " & idt_ptr.base'Image);
      load_idt (idt_ptr);
   end init_idt;

   procedure handler (stf : access stack_frame) is
      interrupt_code : Unsigned_32 renames stf.interrupt_code;
      error_code     : Unsigned_32 renames stf.error_code;
      eip            : Unsigned_32 renames stf.eip;
      cs             : Unsigned_32 renames stf.cs;
   begin
      SERIAL.send_line
        ("error_code = "
         & error_code'Image
         & " interrupt_code = "
         & interrupt_code'Image
         & " eip = "
         & eip'Image
         & " cs = "
         & cs'Image);

      while True loop
         ASM ("hlt", Volatile => True);
      end loop;

   end handler;
end x86.idt;
