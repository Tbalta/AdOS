#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5

#include "stdio.h"

#define syscall_3(num, arg1, arg2, arg3, ret) ({ \
    asm volatile ( \
        "mov $" #num ", %%eax\n"        /* syscall number */ \
        "mov %1, %%ebx\n"       /* first argument */ \
        "mov %2, %%ecx\n"       /* second argument */ \
        "mov %3, %%edx\n"       /* third argument */ \
        "int $0x80\n"           /* call kernel */ \
        "mov %%eax, %0\n"       /* return value in ret */ \
        : "=m" (ret) \
        : "m" (arg1), "m" (arg2), "m" (arg3) \
        : "%eax", "%ebx", "%ecx", "%edx" \
    ); \
})


int write (int fd, const void *buf, unsigned int count)
{
    int ret;
    syscall_3(4, fd, buf, count, ret);
    return ret;
}

int read (int fd, void *buf, unsigned int count)
{
    int ret;
    syscall_3(3, fd, buf, count, ret);
    return ret;
}

int open (const char *pathname, int flags)
{
    int ret;
    int zero = 0;
    syscall_3(5, pathname, flags, zero, ret);
    return ret;
}


int _start() {
    unsigned char vga_line[320] = {0};
    char bmp_header[14];
    char read_buffer[100];

    int tty = open("tty0", 0);

    int ados = open("ados.bmp", 0);


    read (ados, bmp_header, sizeof (bmp_header));

    int start = *(int*)(bmp_header + 10);
    int n = snprintf (read_buffer, sizeof(read_buffer), "bmp_start: %d\n", start);
    write(tty, read_buffer, n);
    
    unsigned char dummy;
    for (int i = 14; i < start ; i += sizeof (dummy))
    {
        read(ados, &dummy, sizeof (dummy));
    }
    
    int vga = open("vga", 0);
    for (int i = 0; i < 200; i++)
    {
        int count = read(ados, vga_line, sizeof(vga_line));
        if (count != sizeof (vga_line))
        {
            write(tty, "not enough data read", 21);
            while (1);
        }
        write(vga, vga_line, sizeof(vga_line));
    }

    while (1)
    {
        // asm volatile ("hlt");
    }    
}