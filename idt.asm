

global load_idt
section .text

load_idt:
    mov eax, [esp+4]  ; Get the pointer to the GDT, passed as a parameter.
    lidt [eax]        ; Load the new GDT pointer
    ret