with System.Machine_Code; use System.Machine_Code;
with SERIAL;

package body x86.Userspace is
   use Standard.ASCII;

   procedure Jump_To_Userspace (Entry_Point : Virtual_Address; CR3 : x86.vmm.CR3_register) is

      New_Stack : constant Virtual_Address := x86.vmm.kmalloc (CR3, 4096);
   begin
      SERIAL.send_line
        ("Jumping to userspace at " & Entry_Point'Image & " with stack at " & New_Stack'Image);
      x86.vmm.Enable_Paging;

      --!format off
      Asm (
         "mov $10, %%eax"           & LF &
         "push  $(4 * 8) | 3"       & LF &
         "push %%eax"               & LF &
         "pushf"                    & LF &
         "push $(3 * 8) | 3"        & LF &
         "push %0"                  & LF &
         "xor %%eax, %%eax"         & LF &
         "mov $(4 * 8) | 3, %%ax"   & LF &
         "mov %%ax, %%ds"           & LF &
         "mov %%ax, %%es"           & LF &
         "mov %%ax, %%fs"           & LF &
         "mov %%ax, %%gs"           & LF &
         "iret",
         Inputs   => System.Address'Asm_Input ("g", Entry_Point),
         Volatile => True,
         Clobber  => "eax");
      --!format on

      SERIAL.send_line
        ("Jumped to userspace at " & Entry_Point'Image & " with stack at " & New_Stack'Image);



   end Jump_To_Userspace;


end x86.Userspace;
