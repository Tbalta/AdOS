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
    const char path[] = "test2.txt";
    int fd = open(path, 0);
    int tty = open("tty0", 0);

    char read_buffer[100];
    int n = snprintf (read_buffer, sizeof(read_buffer), "Read: ");

    n += read(fd, read_buffer + n, sizeof(read_buffer) - n - 1);
    read_buffer[n] = '\0';
    n = snprintf(read_buffer, 100, "%s\n", read_buffer);

    write(tty, read_buffer, n);
    while (1)
    {
        // asm volatile ("hlt");
    }    
}