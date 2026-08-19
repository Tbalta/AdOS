#ifndef __FRAMEBUFFER_H
#define __FRAMEBUFFER_H

#include <stdint.h>




struct framebuffer_information
{
    uint64_t width;
    uint64_t height;
    uint64_t pitch;
    uint16_t bpp;
    uint8_t red_mask_size;
    uint8_t red_mask_shift;
    uint8_t green_mask_size;
    uint8_t green_mask_shift;
    uint8_t blue_mask_size;
    uint8_t blue_mask_shift;
}__attribute__((packed));
typedef struct framebuffer_information framebuffer_information_t;

struct box
{
    int x;
    int y;
    int width;
    int height;
};
typedef struct box box_t;

int open_framebuffer();
int get_framebuffer_info(framebuffer_information_t *info);

#endif