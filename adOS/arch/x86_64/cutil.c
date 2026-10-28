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

struct stackframe_t {
    uint64_t eax, ebx, ecx, edx, esi, edi, r8, r9, r10, r11, r12, r13, r14, r15;
    uint64_t int_no;
    uint64_t err_code;
    uint64_t eip;
    uint64_t cs;
    uint64_t eflags;
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

void print_debug(const char *msg)
{
    LOG("DEBUG: %s", msg);
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
volatile struct limine_framebuffer_response framebuffer_response;
volatile struct limine_memmap_response memmap_response;
volatile struct limine_hhdm_response hhdm_response;
volatile struct limine_executable_cmdline_response executable_cmdline_response;
volatile struct limine_executable_address_response executable_address_response;
// static char astack[4096 * 15] __attribute__((aligned(16)));

// void stack_check(void) {
//     for (int i = 0; i < sizeof (astack); i++) {
//         if (astack[i] != 0xA) {
//             LOG("max stack usage: %d bytes", sizeof (astack) - i);
//             return;
//         }
//     }
// }

void loader_x64(void) {
    extern void adainit(void);
    extern void _ada_main(struct limine_memmap_response *memmap_response);
    extern struct limine_framebuffer_request framebuffer_request;
    extern struct limine_memmap_request memmap_request;
    extern struct limine_hhdm_request hhdm_request;
    extern struct limine_executable_cmdline_request executable_cmdline_request;
    extern struct limine_executable_address_request executable_address_request;

    framebuffer_response = *framebuffer_request.response;
    memmap_response = *memmap_request.response;
    hhdm_response = *hhdm_request.response;
    executable_cmdline_response = *executable_cmdline_request.response;
    executable_address_response = *executable_address_request.response;

    LOG("Hello from adOS kernel!");
    adainit();
    LOG("Ada runtime initialized.");
    _ada_main(0);

    for (;;) {
        asm ("hlt");
    }
}