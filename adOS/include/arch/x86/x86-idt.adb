------------------------------------------------------------------------------
--                               X86.VARIANT                                --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Pic;
-- with SERIAL;
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
-- with x86.Port_IO;
with Programmable_Interval_Timer;
with Keyboard;
with Util;

with x86.idt.Variant;   use x86.idt.Variant;
package body x86.idt is
   package Logger renames Loggers.Serial_Logger;

   type interrupt_vector_t is array (Interrupt_Id'Range) of idt_entry;
   interrupt_vector : interrupt_vector_t
   with Alignment => 16, Volatile;

   function To_Hex is new Util.To_Hex (System.Address);

   procedure load_idt (idt_ptr : idt_ptr_t) is
   begin
      ASM
        ("lidt (%0)", Inputs => System.Address'Asm_Input ("r", idt_ptr'Address), Volatile => True);
   end load_idt;


   procedure handle_page_fault (stf : access stack_frame) is
      function To_Error_Code is new Ada.Unchecked_Conversion (Register_Type, Page_Fault_Error_Code);
      function Get_CR2 return System.Address is
         CR2_Value : System.Address;
      begin
         ASM
           ("mov %%cr2, %0",
            Outputs  => System.Address'Asm_Output ("=r", CR2_Value),
            Volatile => True);
         return CR2_Value;
      end Get_CR2;

      error_code       : Page_Fault_Error_Code := To_Error_Code (stf.error_code);
      faulting_address : constant System.Address := Get_CR2;
   begin
      -- x86.pmm.Print_PMM_Info;
      Print_Stack_Frame (stf);
      if error_code.User_Mode then
         Logger.Log_Info ("Userland memory:");
         x86.vmm.Print_Mapped_Memory (x86.vmm.Get_Current_CR3);
      else
         Logger.Log_Info ("Kernel memory:");
         x86.vmm.Print_Mapped_Memory (x86.vmm.Get_Kernel_CR3);
      end if;
      Logger.Log_Error ("Page Fault at : " & To_Hex (stf.Instruction_Pointer));
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

   procedure Handle_Debug (stf : access stack_frame) is
   begin
      Print_Stack_Frame (stf);
      while True loop
         null;
      end loop;
   end Handle_Debug;

   procedure init_idt is
      procedure timer_callback;
      procedure keyboard_callback;
      procedure syscall;
      procedure debug;
      pragma Import (C, timer_callback, "isr_stub_32");
      pragma Import (C, keyboard_callback, "isr_stub_33");
      pragma Import (C, syscall, "isr_stub_128");
      pragma Import (C, debug, "isr_stub_129");
      idt_ptr : idt_ptr_t;
   begin
      for i in error_vector_t'Range loop
         interrupt_vector (i) :=  Create_Entry (error_vector (i), 8, CPL0, trap_gate);
      end loop;
      
      interrupt_vector (TIMER_INTERRUPT) := Create_Entry (timer_callback'Address, 8, CPL3, interrupt_gate);
      interrupt_vector (KEYBOARD_INTERRUPT) := Create_Entry (keyboard_callback'Address, 8, CPL3, interrupt_gate);
      interrupt_vector (SYSCALL_INTERRUPT) := Create_Entry (syscall'Address, 8, CPL3, interrupt_gate);
      interrupt_vector (129) := Create_Entry (debug'Address, 8, CPL3, interrupt_gate);
      idt_ptr.base := interrupt_vector'Address;
      idt_ptr.limit := interrupt_vector'Size / 8 - 1;

      Logger.Log_Info ("idt = size: " & idt_ptr.limit'Image & " base: " & idt_ptr.base'Image);
      load_idt (idt_ptr);
      Logger.Log_Ok ("IDT initialized");
   end init_idt;

   procedure handle_timer is
   begin
      Programmable_Interval_Timer.Handle_Systick;
   end handle_timer;

   procedure handle_keyboard is
   begin
      Keyboard.Handle_Keyboard;
   end handle_keyboard;


   procedure Interrupt_Handler (stf : access stack_frame);
   pragma Export (C, Interrupt_Handler, "ada_interrupt_handler");
   procedure Interrupt_Handler (stf : access stack_frame) is
      interrupt_code : Register_Type renames stf.interrupt_code;

      process_CR3    : x86.vmm.CR3_register := x86.vmm.Get_Current_CR3;
      Syscall_Result : Syscall.Syscall_Result (signed => False);
   begin
      x86.vmm.Set_Process_CR3 (process_CR3);
      --  Logger.Log_Info ("Interrupt: " & interrupt_code'Image);
      if interrupt_code = 128 then
         Syscall.Handle_Syscall (
            number => Get_Syscall_Number (stf),
            arg1 => Get_Arg1 (stf),
            arg2 => Get_Arg2 (stf),
            arg3 => Get_Arg3 (stf),
            arg4 => Get_Arg4 (stf),
            arg5 => Get_Arg5 (stf),
            process => process_CR3,
            result => Syscall_Result);
         Set_Syscall_Value (stf, syscall_result.Unsigned_Value);
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

      if interrupt_code = 129 then
         Handle_Debug (stf);
      end if;

      x86.vmm.Load_CR3 (process_CR3);
   end Interrupt_Handler;
end x86.idt;
