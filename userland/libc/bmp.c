#include "bmp.h"
#include <stdlib.h>
#include "syscall.h"
#include "stdio.h"

void load_rgba(bmp_image_t *image)
{
    if (image->rgba_buffer == NULL)
    {
        image->rgba_buffer = malloc(image->height * image->width * sizeof (rgba_pixel_t));
    }

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
            image->rgba_buffer[h * width + w].r = palette[pixel].r;
            image->rgba_buffer[h * width + w].g = palette[pixel].g;
            image->rgba_buffer[h * width + w].b = palette[pixel].b;
            image->rgba_buffer[h * width + w].a = 0;
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
    image->rgba_buffer = NULL;
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
    if (dib_header.header_size != 40 && dib_header.header_size != 124)
    {
        close(fd);
        return -1;
    }
    read(fd, &dib_header.BITMAPINFOHEADER, dib_header.header_size - sizeof(uint32_t));

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


static  inline int min(int a, int b)
{
    if (a < b)
        return a;

    return b;
}

int display_indexed(bmp_image_t const *image, framebuffer_information_t const *fb_info, char* framebuffer, box_t dest_box)
{
    bool keep_aspect_ratio = true;
    
    int image_pixel_size = min(dest_box.width / image->width, dest_box.height / image->height);
    int framebuffer_start = (dest_box.y * fb_info->width) + dest_box.x;
    for (int h = 0; h < dest_box.height; h++)
    {
        char *buffer_line_start = framebuffer +framebuffer_start + (h * fb_info->width);
        char *image_line_start = image->bmp_buffer + ((h / image_pixel_size) * image->width);
        for (int w = 0; w < image->width; w++)
        {
            memset(buffer_line_start + (w * image_pixel_size), image_line_start[w], image_pixel_size * sizeof(char));
        }
    }
}

int display_rgba(const bmp_image_t *image, framebuffer_information_t const *fb_info, rgba_pixel_t* framebuffer, box_t dest_box)
{
    bool keep_aspect_ratio = true;
    
    int image_pixel_size = min(dest_box.width / image->width, dest_box.height / image->height);
    int framebuffer_start = (dest_box.y * fb_info->width) + dest_box.x;

    for (int h = 0; h < image->height * image_pixel_size; h++)
    {
        rgba_pixel_t *buffer_line_start = framebuffer + framebuffer_start + (h * fb_info->width);
        rgba_pixel_t *image_line_start = image->rgba_buffer + ((h / image_pixel_size) * image->width);
        for (int w = 0; w < image->width; w++)
        {
           // printf("%d[%d]\n",  &image_line_start[w], (fb_info->bpp / 8));
            for (int i = 0; i < image_pixel_size; i++)
            {
                memcpy(&buffer_line_start[(w * image_pixel_size + i)], &image_line_start[w], (fb_info->bpp / 8));
            }
        }
    }
}

int rotate_left (bmp_image_t* dest, const bmp_image_t *image)
{
    dest->width = image->height;
    dest->height = image->width;
    dest->rgba_buffer = malloc(dest->width * dest->height * sizeof (rgba_pixel_t));
    dest->bmp_buffer = malloc(dest->width * dest->height * sizeof (char));
    for (int col = 0; col < image->width; col++)
    {
        for (int row = 0; row < image->height; row++)
        {
            int src_index = (row * image->width) + col;
            int dest_line = (dest->width - 1 ) - col;
            int dest_col = row;
            int dest_index = (dest_line * dest->width) + dest_col;
            dest->rgba_buffer[dest_index] = image->rgba_buffer[src_index];
            dest->bmp_buffer[dest_index] = image->bmp_buffer[src_index];
        }
    }
}