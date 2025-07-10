int _start() {

    asm volatile ("int $0x80");
    while (1)
    {
        asm volatile ("hlt");
    }
    
}