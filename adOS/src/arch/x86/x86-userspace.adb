with System.Machine_Code; use System.Machine_Code;
with SERIAL;
with Loggers;
package body x86.Userspace is
   use Standard.ASCII;
   package Logger renames Loggers;

   procedure Jump_To_Userspace (Entry_Point : Virtual_Address; CR3 : x86.vmm.CR3_register) is
      use System;
      New_Stack : constant Virtual_Address := x86.vmm.Kernel_Alloc (CR3, 4096, True, True) + Storage_Offset (4096);
   begin
      Logger.Log_Info
        ("Jumping to userspace at " & Entry_Point'Image & " with stack at " & New_Stack'Image);
      x86.vmm.Load_CR3 (CR3);
      x86.vmm.Enable_Paging;

      --!format off
      Asm
        ("movq $10, %%rax" & LF &
         "pushq  $(4 * 8) | 3" & LF &  -- New Data Segment
         "pushq %0" & LF &  -- New Stack Pointer
         "pushfq" & LF &  -- EFLAGS
         "pushq $(3 * 8) | 3" & LF &  -- CS
         "pushq %1" & LF &  -- Entry_Point
         "xor %%rax, %%rax" & LF &
         "mov $(4 * 8) | 3, %%ax" & LF &
         "mov %%ax, %%ds" & LF &
         "mov %%ax, %%es" & LF &
         "mov %%ax, %%fs" & LF &
         "mov %%ax, %%gs" & LF &
         "iretq",
         Inputs   => (System.Address'Asm_Input ("g", New_Stack),
                      System.Address'Asm_Input ("g", Entry_Point)),
         Volatile => True,
         Clobber  => "rax");
      --!format on

      Logger.Log_Info
        ("Jumped to userspace at " & Entry_Point'Image & " with stack at " & New_Stack'Image);



   end Jump_To_Userspace;


end x86.Userspace;
