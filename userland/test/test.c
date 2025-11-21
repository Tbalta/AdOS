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

    char buffer[100];
    buffer[0] = 'R';
    buffer[1] = 'E';
    buffer[2] = 'A';
    buffer[3] = 'D';
    buffer[4] = ':';
    buffer[5] = ' ';

    int c = read(fd, buffer + 6, sizeof(buffer) - 6);
    if (c < 0)
    {
        buffer[6] = 'E';
        buffer[7] = 'R';
        buffer[8] = 'R';
        buffer[9] = 'O';
        buffer[10] = 'R';
        c = 5;
    }
    else
    {
        c += 5;
    }

    buffer[c + 6] = '\n';
    buffer[c + 7] = '\0';

    write(tty, buffer, c + 7);
    while (1)
    {
    }
    
    asm volatile ("mov $0x90, %eax");
    asm volatile ("int $0x80");
}