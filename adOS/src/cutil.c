// #include <stdint.h>
#include "multiboot.h"
#include "log.h"
__attribute__((__visibility__("default"))) int _end = 0;

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

struct stackframe_t {
    unsigned int eax, ebx, ecx, edx, esi, edi;
    unsigned int int_no;
    unsigned int err_code;
    unsigned int eip;
    unsigned int cs;
    unsigned int eflags;
} __attribute__((packed));


void print_mmap(multiboot_info_t *mbi)
{
    LOG("cmdline = %s", (char *)mbi->cmdline);
    multiboot_memory_map_t *mmap = (multiboot_memory_map_t *)mbi->mmap_addr;
    LOG("mmap_addr = 0x%x, mmap_length = 0x%x", (unsigned)mbi->mmap_addr, (unsigned)mbi->mmap_length);
    extern int __kernel_end;
    LOG("kernel_end = 0x%x, 0x%x", (unsigned)&__kernel_end, __kernel_end);
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

void PANIC(const char *msg)
{
    LOG("PANIC: %s", msg);
    while (1)
        asm volatile("hlt");
}


void  handler(volatile struct stackframe_t frame)
{
    extern void ada_interrupt_handler(volatile struct stackframe_t *frame);
    // LOG("Interrupt %d occurred at EIP: 0x%x", frame.int_no, frame.eip);
    ada_interrupt_handler(&frame);
}