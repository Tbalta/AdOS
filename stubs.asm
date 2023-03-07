extern handler

section .text
common_handler:
    cli
    call handler
    add esp, 8
    sti
    iret


%macro isr_no_err 1
global isr_stub_%+%1
isr_stub_%+%1:
    push DWORD 0
    push DWORD %1
    jmp common_handler
%endmacro

%macro isr_err 1
global isr_stub_%+%1
isr_stub_%+%1:
    push DWORD %1
    jmp common_handler
%endmacro


isr_no_err 0
isr_no_err 1
isr_no_err 2
isr_no_err 3
isr_no_err 4
isr_no_err 5
isr_no_err 6
isr_no_err 7
isr_err 8
isr_no_err 9
isr_err 10
isr_err 11
isr_err 12
isr_err 13
isr_err 14
isr_no_err 15
isr_no_err 16
isr_err 17
isr_no_err 18
isr_no_err 19
isr_no_err 20
isr_err 21
isr_no_err 22
isr_no_err 23
isr_no_err 24
isr_no_err 25
isr_no_err 26
isr_no_err 27
isr_no_err 28
isr_no_err 29
isr_err    30
isr_no_err 31
isr_no_err 32

section .rodata
global x86_handler_vector
x86_handler_vector:
%assign i 0 
%rep    32 
    dd isr_stub_%+i ; use DQ instead if targeting 64-bit
%assign i i+1 
%endrep