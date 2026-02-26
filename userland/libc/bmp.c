#include "bmp.h"
#include <stdlib.h>
#include "syscall.h"
#include "stdio.h"

void bmp_to_rgba(bmp_image_t const *image, rgba_pixel_t *rgba_buffer)
{
    int width = image->width;
    int height = image->height;
    bmp_palette_entry_t *palette = image->palette;
    uint8_t *bmp_buffer = image->bmp_buffer;

    const int padding = (((8 * width + 31) / 32) * 4) - width;
    for (int h = 0; h < height; h++)
    {
        for (int w = 0; w < width; w++)
        {
            uint8_t pixel = bmp_buffer[(padding * h) + h * width + w];
            rgba_buffer[h * width + w].r = palette[pixel].r;
            rgba_buffer[h * width + w].g = palette[pixel].g;
            rgba_buffer[h * width + w].b = palette[pixel].b;
            rgba_buffer[h * width + w].a = 0;
        }
    }
}

int open_bmp(const char *path, bmp_image_t *image)
{
    int fd = open(path, 0);
    if (fd == -1)
    {
        return -1;
    }

    bmp_file_header_t file_header;
    read(fd, &file_header, sizeof(bmp_file_header_t));

    if (file_header.signature[0] != 'B' || file_header.signature[1] != 'M')
    {
        printf("Not a valid BMP file\n");
        close(fd);
        return -1;
    }

    DIB_Header_t dib_header;
    read(fd, &dib_header.header_size, sizeof(uint32_t));
    printf("DIB header size: %d\n", dib_header.header_size);
    if (dib_header.header_size != 40)
    {
        close(fd);
        return -1;
    }
    read(fd, &dib_header.BITMAPINFOHEADER, sizeof(bmp_info_header_t));

    image->width = dib_header.BITMAPINFOHEADER.width;
    image->height = dib_header.BITMAPINFOHEADER.height;
    image->palette = malloc(sizeof(bmp_palette_entry_t) * dib_header.BITMAPINFOHEADER.colors_in_color_table);
    printf("Colors in color table: %d\n", dib_header.BITMAPINFOHEADER.colors_in_color_table);

    printf("Current offset: %d\n", lseek(fd, 0, SEEK_CUR));

    read(fd, image->palette, sizeof(bmp_palette_entry_t) * dib_header.BITMAPINFOHEADER.colors_in_color_table);
    printf("palette[0]: %d, %d, %d\n", image->palette[0].r, image->palette[0].g, image->palette[0].b);
    image->bmp_buffer = malloc(dib_header.BITMAPINFOHEADER.image_size);
    lseek(fd, file_header.data_offset, SEEK_SET);
    read(fd, image->bmp_buffer, dib_header.BITMAPINFOHEADER.image_size);
    close(fd);
}