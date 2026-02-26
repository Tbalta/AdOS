#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5

#include <stdio.h>
#include <stdbool.h>
#include <syscall.h>
#include <vga.h>
#include <framebuffer.h>
#include <bmp.h>

static rgba_pixel_t ados_bmp_rgb[320 * 200];


int main() {
    printf("Hello World!\n");
    int framebuffer = open_framebuffer();
    framebuffer_information_t info;
    get_framebuffer_info(&info);

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
    bmp_to_rgba(&ados_bmp, ados_bmp_rgb);
    // int ados = open("ados.bmp", 0);
    // read (ados, bmp_header, sizeof (bmp_header));
    
    // int start = *(int*)(bmp_header + 10);
    // printf ("bmp_start: %d\n", start);
    // lseek (ados, start, SEEK_SET);

    // for (int i = 0; i < info.height; i++)
    // {
    //     for (int j = 0; j < info.width * (info.bpp / 8); j++)
    //     {
    //         write(framebuffer, "\x00", 1);
    //         // vga_line[j] = 0;
    //     }
    //     // int count = read(ados, vga_line, sizeof(vga_line));
    //     // write(framebuffer, vga_line, count);
    // }
    
    rgba_pixel_t *screen = mmap(NULL, info.width * info.height * (info.bpp / 8), 0, 0, framebuffer, 0);
    printf("Framebuffer mapped at %d\n", screen);

    for (int w = 0; w < 320; w++)
    {
        for (int h = 0; h < 200; h++)
        {
            screen[w + (h * info.width)] = ados_bmp_rgb[w + (h * 320)];
        }
    }

    while (1)
    {
        // asm volatile ("hlt");
    }    
}