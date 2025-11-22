with SERIAL;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Machine_Code;     use System.Machine_Code;
with Log;
with Ada.Interrupts;          use Ada.Interrupts;
with Ada.Interrupts.Names;    use Ada.Interrupts.Names;
with Syscall;
with x86.vmm;
with Ada.Unchecked_Conversion;
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

   procedure load_idt (idt_ptr : idt_ptr_t) is
   begin
      ASM
        ("lidt (%0)",
         Inputs     => System.Address'Asm_Input ("r", idt_ptr'Address),
         Volatile => True);
   end load_idt;

   procedure handle_page_fault (stf : access stack_frame) is
      function To_Error_Code is new Ada.Unchecked_Conversion (Unsigned_32, Page_Fault_Error_Code);
      function Get_CR2 return Unsigned_32 is
         CR2_Value : Unsigned_32;
      begin
         ASM
           ("mov %%cr2, %0",
            Outputs  => Interfaces.Unsigned_32'Asm_Output ("=r", CR2_Value),
            Volatile => True);
         return CR2_Value;
      end Get_CR2;

      error_code       : Page_Fault_Error_Code := To_Error_Code (stf.error_code);
      faulting_address : constant Unsigned_32 := Get_CR2;
   begin
      SERIAL.send_line ("Page Fault at address: " & faulting_address'Image);

      if error_code.Present then
         SERIAL.send_line (" - caused by a protection violation.");
      else
         SERIAL.send_line (" - caused by a non-present page.");
      end if;

      if error_code.Write then
         SERIAL.send_line (" - during a write operation.");
      else
         SERIAL.send_line (" - during a read operation.");
      end if;

      if error_code.User_Mode then
         SERIAL.send_line (" - while in user mode.");
      else
         SERIAL.send_line (" - while in supervisor mode.");
      end if;

      while True loop
         ASM ("hlt", Volatile => True);
      end loop;

   end handle_page_fault;

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
      eax            : Unsigned_32 renames stf.eax;
      ebx            : Unsigned_32 renames stf.ebx;
      ecx            : Unsigned_32 renames stf.ecx;
      edx            : Unsigned_32 renames stf.edx;
      esi            : Unsigned_32 renames stf.esi;
      edi            : Unsigned_32 renames stf.edi;
      process_CR3    : x86.vmm.CR3_register := x86.vmm.Get_Current_CR3;
      syscall_result : Syscall.Syscall_Result (signed => False);
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

      if interrupt_code = 14 then
         handle_page_fault (stf);
      end if;

      if interrupt_code = 128 then
         Syscall.Handle_Syscall (eax, ebx, ecx, edx, esi, edi, process_CR3, syscall_result);
      end if;

      eax := syscall_result.Unsigned_Value;

      --  while True loop
      --     ASM ("hlt", Volatile => True);
      --  end loop;

   end handler;
end x86.idt;
