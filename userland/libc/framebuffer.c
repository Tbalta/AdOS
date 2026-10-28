#include <framebuffer.h>
#include <syscall.h>
#include "vga.h"

int open_framebuffer()
{
#if defined(__i386__)
    return set_vga_mode(320, 200, 256);
#elif defined(__x86_64__)
    return open("dev/limine/framebuffer", 0);
#else
    return -1;
#endif
}


int get_framebuffer_info(framebuffer_information_t *info)
{
#if defined(__i386__)
    info->width = 320;
    info->height = 200;
    info->pitch = 320;
    info->bpp = 8;
    info->red_mask_size = 0;
    info->red_mask_shift = 0;
    info->green_mask_size = 0;
    info->green_mask_shift = 0;
    info->blue_mask_size = 0;
    info->blue_mask_shift = 0;
    return 0;
#elif defined(__x86_64__)
    int fd = open("dev/limine/info", 0);
    if (fd == -1)
    {
        return -1;
    }

    int result = read(fd, info, sizeof(framebuffer_information_t));
    if (result == -1)
    {
        return -1;
    }

    return 0;
#else
    return -1;
#endif
}