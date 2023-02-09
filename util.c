#include <stdint.h>

__attribute__((__visibility__("default")))
int _end = 0;

static inline void outb(uint16_t port, uint8_t val)
{
    asm volatile("outb %0, %1"
                 :
                 : "a"(val), "Nd"(port));
}

void setup_PIC()
{
    static const char *data = "\x20\x11\xa0\x11\x21\x20\xa1\x28\x21\x4\xa1\x2\x21\x1\xa1\x1\x21\x0\xa1\x0";
    for(uint32_t i = 0; i < 10 * 2; i+=2)
        outb((uint16_t)data[i], data[i+1]);
}