// #include <stdint.h>
#include "multiboot.h"
#include "log.h"
__attribute__((__visibility__("default"))) int _end = 0;

// static inline void outb(uint16_t port, uint8_t val)
// {
//     asm volatile("outb %0, %1"
//                  :
//                  : "a"(val), "Nd"(port));
// }

// void setup_PIC()
// {
//     static const char *data = "\x20\x11\xa0\x11\x21\x20\xa1\x28\x21\x4\xa1\x2\x21\x1\xa1\x1\x21\x0\xa1\x0";
//     for(uint32_t i = 0; i < 10 * 2; i+=2)
//         outb((uint16_t)data[i], data[i+1]);
// }

void __gnat_last_chance_handler()
{
    while (1)
        asm volatile("hlt");
}

extern void printf(const char *fmt, ...);
void printcmdline(multiboot_info_t *mbi)
{
    printf("plouf");
}

void __gnat_personality_v0()
{
}

void _Unwind_Resume()
{
}

void print_mmap(multiboot_info_t *mbi)
{
    LOG("cmdline = %s", (char *)mbi->cmdline);
    multiboot_memory_map_t *mmap = (multiboot_memory_map_t *)mbi->mmap_addr;
    LOG("mmap_addr = 0x%x, mmap_length = 0x%x", (unsigned)mbi->mmap_addr, (unsigned)mbi->mmap_length);
    extern int kernel_end;
    LOG("kernel_end = 0x%x, 0x%x", (unsigned)&kernel_end, kernel_end);
    unsigned long long mmap_entry_count = mbi->mmap_length / sizeof(multiboot_memory_map_t);

    for (unsigned long long i = 0; i < mmap_entry_count; i++)
    {
        LOG(" size = 0x%x, base_addr = 0x%x%x, length = 0x%x%x, type = 0x%x",
            (unsigned)mmap[i].size,
            (unsigned)(mmap[i].addr >> 32),
            (unsigned)(mmap[i].addr & 0xffffffff),
            (unsigned)(mmap[i].len >> 32),
            (unsigned)(mmap[i].len & 0xffffffff),
            (unsigned)mmap[i].type);
    }
}

void PANIC(const char *text)
{
    LOG("PANIC: %s", text);
    while (1)
        asm volatile("hlt");
}

int plouf()
{
    return 3;
}