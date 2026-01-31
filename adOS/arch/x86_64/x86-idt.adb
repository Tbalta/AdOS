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
package body x86.idt is
   package Logger renames Loggers;

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
        (offset      => Unsigned_16 (offset and 16#FFFF#),
         selector    => selector,
         DPL         => DPL and 2#11#,
         present     => True,
         offset_high => Unsigned_16 (Shift_Right (offset, 16)),
         entry_type  => type_attr,
         zero        => 0);
   end add_entry;

   procedure load_idt (idt_ptr : idt_ptr_t) is
   begin
      ASM
        ("lidt (%0)", Inputs => System.Address'Asm_Input ("r", idt_ptr'Address), Volatile => True);
   end load_idt;

   procedure handle_page_fault (stf : access stack_frame) is
      function To_Error_Code is new Ada.Unchecked_Conversion (Unsigned_64, Page_Fault_Error_Code);
      function To_Hex is new Util.To_Hex (Unsigned_64);
      function Get_CR2 return Unsigned_64 is
         CR2_Value : Unsigned_64;
      begin
         ASM
           ("mov %%cr2, %0",
            Outputs  => Interfaces.Unsigned_64'Asm_Output ("=r", CR2_Value),
            Volatile => True);
         return CR2_Value;
      end Get_CR2;

      error_code       : Page_Fault_Error_Code := To_Error_Code (stf.error_code);
      faulting_address : constant Unsigned_64 := Get_CR2;
   begin

      if error_code.User_Mode then
         Logger.Log_Info ("Userland memory:");
         x86.vmm.Print_Mapped_Memory (x86.vmm.Get_Process_CR3);
      else
         Logger.Log_Info ("Kernel memory:");
         x86.vmm.Print_Mapped_Memory (x86.vmm.Get_Kernel_CR3);
      end if;
      Logger.Log_Error ("Page Fault at : " & To_Hex (stf.rip));
      Logger.Log_Error ("Faulting address is: " & To_Hex (faulting_address));
      if error_code.Present then
         Logger.Log_Error (" - caused by a protection violation.");
      else
         Logger.Log_Error (" - caused by a non-present page.");
      end if;

      if error_code.Write then
         Logger.Log_Error (" - during a write operation.");
      else
         Logger.Log_Error (" - during a read operation.");
      end if;

      if error_code.User_Mode then
         Logger.Log_Error (" - while in user mode.");
      else
         Logger.Log_Error (" - while in supervisor mode.");
      end if;

      while True loop
         ASM ("hlt", Volatile => True);
      end loop;

   end handle_page_fault;

   procedure init_idt is
      procedure timer_callback;
      procedure keyboard_callback;
      procedure syscall;
      pragma Import (C, timer_callback, "isr_stub_32");
      pragma Import (C, keyboard_callback, "isr_stub_33");
      pragma Import (C, syscall, "isr_stub_128");
      idt_ptr : idt_ptr_t;
   begin
      for i in error_vector_t'Range loop
         add_entry (i, error_vector (i), 8, 0, trap_gate_32_bits);
      end loop;
      add_entry (TIMER_INTERRUPT, timer_callback'Address, 8, 3, interrupt_32_bits);
      add_entry (KEYBOARD_INTERRUPT, keyboard_callback'Address, 8, 3, interrupt_32_bits);
      add_entry (SYSCALL_INTERRUPT, syscall'Address, 8, 3, interrupt_32_bits);
      idt_ptr.base := interrupt_vector'Address;
      idt_ptr.limit := interrupt_vector'Size / 8 - 1;

      Logger.Log_Info ("idt = size: " & idt_ptr.limit'Image & " base: " & idt_ptr.base'Image);
      load_idt (idt_ptr);
      Logger.Log_Ok ("IDT initialized");
   end init_idt;

   procedure handle_timer is
      procedure outb is new x86.Port_Io.Outb (Unsigned_8);
   begin
      Programmable_Interval_Timer.Handle_Systick;
   end handle_timer;

   procedure handle_keyboard is
      procedure outb is new x86.Port_Io.Outb (Unsigned_8);
   begin
      Keyboard.Handle_Keyboard;
   end handle_keyboard;

   procedure handler (stf : access stack_frame) is
      interrupt_code : Unsigned_64 renames stf.interrupt_code;
      error_code     : Unsigned_64 renames stf.error_code;
      rip            : Unsigned_64 renames stf.rip;
      cs             : Unsigned_64 renames stf.cs;
      rax            : Unsigned_64 renames stf.rax;
      rbx            : Unsigned_64 renames stf.rbx;
      rcx            : Unsigned_64 renames stf.rcx;
      rdx            : Unsigned_64 renames stf.rdx;
      rsi            : Unsigned_64 renames stf.rsi;
      rdi            : Unsigned_64 renames stf.rdi;
      process_CR3    : x86.vmm.CR3_register := x86.vmm.Get_Current_CR3;
      syscall_result : Syscall.Syscall_Result (signed => False);
   begin
      x86.vmm.Set_Process_CR3 (process_CR3);
      if interrupt_code = 128 then
         Syscall.Handle_Syscall (rax, rbx, rcx, rdx, rsi, rdi, process_CR3, syscall_result);
         rax := syscall_result.Unsigned_Value;
      end if;

      if interrupt_code = 14 then
         handle_page_fault (stf);
      end if;

      if interrupt_code = 32 then
         handle_timer;
         Pic.Send_EOI (Pic.IRQ_Number (interrupt_code));
      end if;

      if interrupt_code = 33 then
         handle_keyboard;
         Pic.Send_EOI (Pic.IRQ_Number (interrupt_code));
      end if;


      --  while True loop
      --     ASM ("hlt", Volatile => True);
      --  end loop;
      x86.vmm.Load_CR3 (process_CR3);
   end handler;
end x86.idt;
