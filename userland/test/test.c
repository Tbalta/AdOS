#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5

#include <stdio.h>
#include <stdbool.h>
#include <syscall.h>
#include <vga.h>
#include <framebuffer.h>
#include <bmp.h>



int main() {
    printf("Hello World!\n");
    int framebuffer = open_framebuffer();
    framebuffer_information_t info;
    get_framebuffer_info(&info);

    box_t framebuffer_box = {
        .height = info.height,
        .width  = info.width,
        .x = 0,
        .y = 0,
    };

    if (framebuffer == -1)
    {
        printf("Unable to open framebuffer\n");
        while (true)
        {
            /* code */
        }
    }

    printf ("Starting AdOS\n");

    bmp_image_t ados_bmp;
    open_bmp("ados.bmp", &ados_bmp);
    load_rgba(&ados_bmp);

    
    rgba_pixel_t *screen = mmap(NULL, info.width * info.height * (info.bpp / 8), 0, 0, framebuffer, 0);
    printf("Framebuffer mapped at %d\n", screen);

    #if defined(__i386__)
        display_indexed(&ados_bmp, &info, (char*)screen, framebuffer_box);
    #elif defined(__x86_64__)
        display_rgba(&ados_bmp, &info, screen, framebuffer_box);
    #endif


    while (1)
    {
        // asm volatile ("hlt");
    }    
}