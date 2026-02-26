#ifndef __BMP_H
#define __BMP_H


#include <stdint.h>
#include <stdbool.h>

struct rgba_pixel {
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t a;
} __attribute__((packed));
typedef struct rgba_pixel __attribute__((packed)) rgba_pixel_t;

struct bmp_palette_entry
{
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t reserved;
} __attribute__((packed));
typedef struct bmp_palette_entry bmp_palette_entry_t;


struct bmp_image {
    uint8_t *bmp_buffer;
    int width;
    int height;
    bmp_palette_entry_t *palette;
};
typedef struct bmp_image bmp_image_t;

struct bmp_file_header {
    char signature[2];
    uint32_t file_size;
    uint16_t reserved1;
    uint16_t reserved2;
    uint32_t data_offset;
} __attribute__((packed));
typedef struct bmp_file_header bmp_file_header_t;

struct bmp_info_header {
    int32_t width;
    int32_t height;
    uint16_t planes;
    uint16_t bits_per_pixel;
    uint32_t compression;
    uint32_t image_size;
    int32_t x_pixels_per_meter;
    int32_t y_pixels_per_meter;
    uint32_t colors_in_color_table;
    uint32_t important_color_count;
} __attribute__((packed));
typedef struct bmp_info_header bmp_info_header_t;



struct DIB_Header
{
    uint32_t header_size;
    union
    {
        bmp_info_header_t BITMAPINFOHEADER;
    };
    
} __attribute__((packed));
typedef struct DIB_Header DIB_Header_t;


#define BI_RGB 0
#define BI_RLE8 1
#define BI_RLE4 2
#define BI_BITFIELDS 3
#define BI_JPEG 4
#define BI_PNG 5
#define BI_ALPHABITFIELDS 6
#define BI_CMYK 11
#define BI_CMYKRLE8 12
#define BI_CMYKRLE4 13


void bmp_to_rgba(bmp_image_t const *image, rgba_pixel_t *rgba_buffer);
int open_bmp(const char *path, bmp_image_t *image);

#endif /* __BMP_H */