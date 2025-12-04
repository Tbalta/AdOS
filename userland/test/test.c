#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5

#include "stdio.h"
#include <stdbool.h>

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

bool set_vga_mode (int width, int height, int color_depth)
{
    int vga_width = open("vga_width", 0);
    int vga_height = open("vga_height", 0);
    int vga_graphic_mode = open("vga_graphic_mode", 0);
    int vga_enable = open("vga_enable", 0);
    bool success = true;

    if (vga_width == -1 || vga_height == -1 || vga_graphic_mode == -1 || vga_enable == -1){
        success = false;
        goto set_vga_mode_close;
    }
    
    if (write (vga_height, &height, sizeof (int)) == -1){
        success = false;
        goto set_vga_mode_close;
    }

    if (write (vga_graphic_mode, &color_depth, sizeof (int)) == -1){
        success = false;
        goto set_vga_mode_close;
    }
    
    if (write (vga_width, &width, sizeof (int)) == -1){
        success = false;
        goto set_vga_mode_close;
    }

    int enable = 1;
    if (write (vga_enable, &enable, sizeof (int)) == -1){
        success = false;
        goto set_vga_mode_close;
    }

set_vga_mode_close:
    if (vga_width != -1){
        close (vga_width);
    }

    if (vga_height != -1){
        close (vga_height);
    }

    if (vga_graphic_mode != -1){
        close (vga_graphic_mode);
    }

    if (vga_enable != -1){
        close (vga_enable);
    }

    return success;
}

int _start() {
    if (!set_vga_mode (320, 200, 256))
    {
        while (true)
        {
            /* code */
        }
    }
    
    unsigned char vga_line[320] = {0};
    char bmp_header[14];
    char read_buffer[100];
    
    int tty = open("tty0", 0);
    
    int ados = open("ados.bmp", 0);
    read (ados, bmp_header, sizeof (bmp_header));
    
    int start = *(int*)(bmp_header + 10);
    int n = snprintf (read_buffer, sizeof(read_buffer), "bmp_start: %d\n", start);
    write(tty, read_buffer, n);
    lseek (ados, start, SEEK_SET);
    
    int vga = open("vga_frame_buffer", 0);
    char *vga_buff = mmap(NULL, 320*200, 0, 0, vga, 0);
    for (int i = 0; i < 200; i++)
    {
        int count = read(ados, vga_buff + (i * 320), sizeof(vga_line));
    }

    while (1)
    {
        // asm volatile ("hlt");
    }    
}