#ifndef __BMP_H
#define __BMP_H


#include <stdint.h>
#include <stdbool.h>
#include <framebuffer.h>

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
    uint8_t      *bmp_buffer;
    rgba_pixel_t *rgba_buffer;
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

struct CIEXYZ {
    uint32_t ciexyzX;
    uint32_t ciexyzY;
    uint32_t ciexyzZ;
};
typedef struct CIEXYZ CIEXYZ;
struct CIEXYZTRIPLE {
    CIEXYZ ciexyzRed;
    CIEXYZ ciexyzGreen;
    CIEXYZ ciexyzBlue;
};
typedef struct CIEXYZTRIPLE CIEXYZTRIPLE_t;
struct bmp_info_header_v5{
  int32_t         V5Width;
  int32_t         bV5Height;
  uint16_t        bV5Planes;
  uint16_t        bV5BitCount;
  uint32_t        bV5Compression;
  uint32_t        bV5SizeImage;
  int32_t         bV5XPelsPerMeter;
  int32_t         bV5YPelsPerMeter;
  uint32_t        bV5ClrUsed;
  uint32_t        bV5ClrImportant;
  uint32_t        bV5RedMask;
  uint32_t        bV5GreenMask;
  uint32_t        bV5BlueMask;
  uint32_t        bV5AlphaMask;
  uint32_t        bV5CSType;
  CIEXYZTRIPLE_t  bV5Endpoints;
  uint32_t        bV5GammaRed;
  uint32_t        bV5GammaGreen;
  uint32_t        bV5GammaBlue;
  uint32_t        bV5Intent;
  uint32_t        bV5ProfileData;
  uint32_t        bV5ProfileSize;
  uint32_t        bV5Reserved;
}__attribute__((packed));
typedef struct bmp_info_header_v5 bmp_info_header_v5_t;





struct DIB_Header
{
    uint32_t header_size;
    union
    {
        bmp_info_header_t BITMAPINFOHEADER;
        bmp_info_header_v5_t BITMAPV5HEADER;
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


void load_rgba(bmp_image_t *image);
int open_bmp(const char *path, bmp_image_t *image);
int display(bmp_image_t const *image, framebuffer_information_t const *fb_info, rgba_pixel_t *rgba_buffer);
int display_rgba(bmp_image_t const *image, framebuffer_information_t const *fb_info, rgba_pixel_t* framebuffer, box_t dest_box);
#endif /* __BMP_H */