#include <framebuffer.h>
#include <syscall.h>

int open_framebuffer()
{
    return open("dev/limine/framebuffer", 0);
}


int get_framebuffer_info(framebuffer_information_t *info)
{
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
}

