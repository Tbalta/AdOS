// #include <stdint.h>
#include "multiboot.h"
#include "log.h"
#include <limine.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

__attribute__((__visibility__("default"))) int _end = 0;

__attribute__((used, section(".limine_requests")))
static volatile uint64_t limine_base_revision[] = LIMINE_BASE_REVISION(4);

// The Limine requests can be placed anywhere, but it is important that
// the compiler does not optimise them away, so, usually, they should
// be made volatile or equivalent, _and_ they should be accessed at least
// once or marked as used with the "used" attribute as done here.

__attribute__((used, section(".limine_requests")))
static volatile struct limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST_ID,
    .revision = 0
};

// Finally, define the start and end markers for the Limine requests.
// These can also be moved anywhere, to any .c file, as seen fit.

__attribute__((used, section(".limine_requests_start")))
static volatile uint64_t limine_requests_start_marker[] = LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".limine_requests_end")))
static volatile uint64_t limine_requests_end_marker[] = LIMINE_REQUESTS_END_MARKER;


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
    // Ensure the bootloader actually understands our base revision (see spec).
    if (LIMINE_BASE_REVISION_SUPPORTED(limine_base_revision) == false) {
        hcf();
    }

    // Ensure we got a framebuffer.
    if (framebuffer_request.response == NULL
     || framebuffer_request.response->framebuffer_count < 1) {
        hcf();
    }

    // Fetch the first framebuffer.
    struct limine_framebuffer *framebuffer = framebuffer_request.response->framebuffers[0];

    // Note: we assume the framebuffer model is RGB with 32-bit pixels.
    for (size_t i = 0; i < 100; i++) {
        volatile uint32_t *fb_ptr = framebuffer->address;
        fb_ptr[i * (framebuffer->pitch / 4) + i] = 0xffffff - i * 0x010101; // White to black diagonal.
    }

    // We're done, just hang...
    hcf();
}

// void loader_x64(void)
// {
//     extern void _ada_main(void);
//     extern void adainit(void);

//     adainit();
//     _ada_main();

//     while (1)
//         asm volatile("hlt");
// }