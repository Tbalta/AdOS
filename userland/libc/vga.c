#include <stdbool.h>
#include "syscall.h"
#include "stdio.h"
#include <stddef.h>
#include "vga.h"
int set_vga_mode (int width, int height, int color_depth)
{
    int vga_width = open("vga_width", 0);
    int vga_height = open("vga_height", 0);
    int color = open("vga_color_depth", 0);
    int vga_mode = open("vga_mode", 0);
    bool success = true;

    if (vga_width == -1 || vga_height == -1 || color == -1 || vga_mode == -1){
        success = false;
        goto set_vga_mode_close;
    }
    
    if (write (vga_height, &height, sizeof (int)) == -1){
        success = false;
        goto set_vga_mode_close;
    }

    if (write (color, &color_depth, sizeof (int)) == -1){
        success = false;
        goto set_vga_mode_close;
    }
    
    if (write (vga_width, &width, sizeof (int)) == -1){
        success = false;
        goto set_vga_mode_close;
    }

    int vga_graphic = 1;
    if (write (vga_mode, &vga_graphic, sizeof (int)) == -1){
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

    if (color != -1){
        close (color);
    }

    if (vga_mode != -1){
        close (vga_mode);
    }
    if (success)
    {
        return open("vga_frame_buffer", 0);
    }
    return -1;
}

void load_image (char* framebuffer, const char* path, int width, int height)
{
    if (framebuffer == NULL)
    {
        return;
    }

    int image = open(path, 0);
    if (image == -1)
    {
        return;
    }

    char bmp_header[14];
    read (image, bmp_header, sizeof (bmp_header));
    int start = *(int*)(bmp_header + 10);
    lseek (image, start, SEEK_SET);

    for (int i = 0; i < height; i++)
    {
        read(image, framebuffer + (i * width), width);
        int padding = (((8 * width + 31) / 32) * 4) - width;
        lseek (image, padding, SEEK_CUR);
    }

    close (image);
}

int set_palette (vga_color_t *palette, int palette_fd)
{
    if (palette_fd == -1)
    {
        return -1;
    }

    write (palette_fd, palette, VGA_PALETTE_SIZE * sizeof (vga_color_t));
        
    return 0;
}
