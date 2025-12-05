#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5

#include <stdio.h>
#include <stdbool.h>
#include <syscall.h>

bool set_vga_mode (int width, int height, int color_depth)
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

    return success;
}

void *memset(void *s, char c, size_t n)
{
	char *p = s;

	for (size_t i = 0; i < n; ++i)
		p[i] = c;

	return s;
}


void draw_box (void *buffer, int x, int y, int w, int h)
{
    int start = (y * 320) + x;

    for (int row = 0; row < h; row++)
    {
        int line_start = start + (row * 320);
        memset (buffer + line_start, 70, w );
    }
}

int _start() {
    if (!set_vga_mode (320, 200, 256))
    {
        while (true)
        {
            /* code */
        }
    }
    int vga = open("vga_frame_buffer", 0);
    char *vga_buff = mmap(NULL, 320*200, 0, 0, vga, 0);

    int systick_fd = open("systick", 0);
    
    int systick = 0;
    int tick = 0;
    int x = 0;
    int y = 10;
    int direction = 1;
    while (1)
    {
        do
        {
            read(systick_fd, &systick, sizeof (systick));
        } while (systick % 50 != 0);

        memset (vga_buff, 30, 320 * 200);
        draw_box (vga_buff, x, y, 30, 30);

        if (direction < 0)
        {
            if (x <= 0)
            {
                direction = -direction;
            }
        } else
        {
            if (x + 30 > 320)
            {
                direction = -direction;
            }
        }
        
        x += direction;
        tick++;
    }


    while (1)
    {
        // asm volatile ("hlt");
    }    
}