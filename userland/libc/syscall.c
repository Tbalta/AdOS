#include "syscall.h"

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

#define syscall_5(num, arg1, arg2, arg3, arg4, arg5, ret) ({ \
    asm volatile ( \
        "mov $" #num ", %%eax\n"/* syscall number */ \
        "mov %1, %%ebx\n"       /* 1st argument */ \
        "mov %2, %%ecx\n"       /* 2nd argument */ \
        "mov %3, %%edx\n"       /* 3rd argument */ \
        "mov %4, %%esi\n"       /* 4th argument */ \
        "mov %5, %%edi\n"       /* 5th argument */ \
        "int $0x80\n"           /* syscall */ \
        "mov %%eax, %0\n"       /* ret */ \
        : "=m" (ret) \
        : "m" (arg1), "m" (arg2), "m" (arg3), "m" (arg4), "m" (arg5)  \
        : "%eax", "%ebx", "%ecx", "%edx", "%esi", "%edi"\
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

int close (int fd)
{
    int ret;
    int zero = 0;
    syscall_3(6, fd, zero, zero, ret);
    return ret;
}
int open (const char *pathname, int flags)
{
    int ret;
    int zero = 0;
    syscall_3(5, pathname, flags, zero, ret);
    return ret;
}

int lseek (int fd, int offset, int whence)
{
    int ret;
    int zero = 0;
    syscall_3(19, fd, offset, whence, ret);
    return ret;
}

void* mmap(void *addr, int length, int prot, int flags, int fd, int offset)
{
    void* ret;
    syscall_5(90, addr, length, prot, flags, fd, ret);
    return ret;
}