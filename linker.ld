
KERNEL_SEC_STACK_SIZE = 0x1000;

ENTRY (loader)
SECTIONS
{
  . = 0x00100000;
  .mbheader : {
    *(.mbheader)
  }
  .text : {
    *(.text)
  }
  .rodata ALIGN (0x1000) : {
    *(.rodata)
  }
  .data ALIGN (0x1000) : {
    *(.data)
  }
  .bss : {
    sbss = .;
    *(COMMON)
    *(.bss)
    ebss = .;

    . = ALIGN (4K);
		kernel_stack_bottom = .;
		. += KERNEL_SEC_STACK_SIZE;
		kernel_stack_top = .;
  }
}
