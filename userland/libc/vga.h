#ifndef __VGA_H
#define __VGA_H

#include "syscall.h"

int set_vga_mode (int width, int height, int color_depth);
void load_image (char* framebuffer, const char* path, int width, int height);
#endif