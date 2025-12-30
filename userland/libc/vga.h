#ifndef __VGA_H
#define __VGA_H

#include "syscall.h"
#include "stdint.h"

typedef struct
{
    uint8_t red;
    uint8_t green;
    uint8_t blue;
} vga_color_t;

#define VGA_PALETTE_SIZE 256

int set_vga_mode (int width, int height, int color_depth);
void load_image (char* framebuffer, const char* path, int width, int height);
int set_palette (vga_color_t *palette, int palette_fd);
#endif