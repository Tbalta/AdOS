int _start() {

    asm volatile ("mov $0x90, %eax");
    asm volatile ("int $0x80");
    while (1)
    {
        asm volatile ("hlt");
    }
    
}