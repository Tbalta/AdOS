// #include <stdint.h>
#include "multiboot.h"
#include "log.h"
#include <limine.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>



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


void *memcpy(void *restrict dest, const void *restrict src, size_t n) {
    uint8_t *restrict pdest = (uint8_t *restrict)dest;
    const uint8_t *restrict psrc = (const uint8_t *restrict)src;

    for (size_t i = 0; i < n; i++) {
        pdest[i] = psrc[i];
    }

    return dest;
}

void *memset(void *s, int c, size_t n) {
    uint8_t *p = (uint8_t *)s;

    for (size_t i = 0; i < n; i++) {
        p[i] = (uint8_t)c;
    }

    return s;
}

void *memmove(void *dest, const void *src, size_t n) {
    uint8_t *pdest = (uint8_t *)dest;
    const uint8_t *psrc = (const uint8_t *)src;

    if (src > dest) {
        for (size_t i = 0; i < n; i++) {
            pdest[i] = psrc[i];
        }
    } else if (src < dest) {
        for (size_t i = n; i > 0; i--) {
            pdest[i-1] = psrc[i-1];
        }
    }

    return dest;
}

int memcmp(const void *s1, const void *s2, size_t n) {
    const uint8_t *p1 = (const uint8_t *)s1;
    const uint8_t *p2 = (const uint8_t *)s2;

    for (size_t i = 0; i < n; i++) {
        if (p1[i] != p2[i]) {
            return p1[i] < p2[i] ? -1 : 1;
        }
    }

    return 0;
}

// Halt and catch fire function.
static void hcf(void) {
    for (;;) {
        asm ("hlt");
    }
}

// The following will be our kernel's entry point.
// If renaming kmain() to something else, make sure to change the
// linker script accordingly.
void loader_x64(void) {
    extern void adainit(void);
    extern void _ada_main(struct limine_memmap_response *memmap_response);
    LOG("Hello from adOS kernel!");
    adainit();
    LOG("Ada runtime initialized.");
    _ada_main(0);

    // We're done, just hang...
       for (;;) {
        asm ("hlt");
    }
}