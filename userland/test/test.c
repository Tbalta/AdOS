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
    
    unsigned char vga_line[320] = {0};
    char bmp_header[14];
    char read_buffer[100];

    printf ("Starting AdOS\n");

    bmp_image_t ados_bmp;
    open_bmp("ados.bmp", &ados_bmp);
    load_rgba(&ados_bmp);

    
    rgba_pixel_t *screen = mmap(NULL, info.width * info.height * (info.bpp / 8), 0, 0, framebuffer, 0);
    printf("Framebuffer mapped at %d\n", screen);

    display_rgba(&ados_bmp, &info, screen, framebuffer_box);

    // for (int w = 0; w < 320; w++)
    // {
    //     for (int h = 0; h < 200; h++)
    //     {
    //         screen[w + (h * info.width)] = ados_bmp_rgb[w + (h * 320)];
    //     }
    // }

    while (1)
    {
        // asm volatile ("hlt");
    }    
}