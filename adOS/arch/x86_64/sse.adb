with System.Machine_Code; use System.Machine_Code;
package body SSE is
      use Standard.ASCII;

   
   procedure Enable_SSE is
   begin
      Asm (
         "mov %%cr0, %%rax"  & LF &
         "and $0xFFFB, %%ax" & LF & --	;clear coprocessor emulation CR0.EM

         "or $0x2, %%ax"     & LF & -- ;set coprocessor monitoring  CR0.MP
         "mov %%rax, %%cr0"  & LF &
         "mov %%cr4, %%rax"  & LF &
         "or $0x600, %%ax" & LF & -- ;set CR4.OSFXSR and CR4.OSXMMEXCPT at the same time
         "mov %%rax, %%cr4",
         Volatile=> True);

      Asm ("fxsave (%0)",
         Volatile => True,
         Inputs   => System.Address'Asm_Input ("r", fxsave_region'Address));

   end Enable_SSE;
   
end SSE;