#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5

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


int _start() {
    const char message[] = "Hello World from Userland!\n";
    int read = write(1, message, sizeof(message) - 1);
    write(read, message, sizeof(message) - 1);
    while (1)
    {
    }
    
    asm volatile ("mov $0x90, %eax");
    asm volatile ("int $0x80");
}