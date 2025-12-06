#include <stdio.h>
#include <stdbool.h>
#include <syscall.h>
#include "snake.h"
#include <vga.h>

void *memset(void *s, char c, size_t n)
{
	char *p = s;

	for (size_t i = 0; i < n; ++i)
		p[i] = c;

	return s;
}


void draw_box (void *buffer, int x, int y, int w, int h, int color)
{
    int start = (y * 320) + x;

    for (int row = 0; row < h; row++)
    {
        int line_start = start + (row * 320);
        memset (buffer + line_start, color, w );
    }
}

void busy_wait_ms (int systick_fd, int ms)
{
    int base_systick;
    if (read(systick_fd, &base_systick, sizeof (base_systick)) == -1)
    {
        return;
    }
    int systick = base_systick;

    while (systick < base_systick + ms)
    {
        if (read (systick_fd, &systick, sizeof (systick)) == -1)
        {
            return;
        }
    }
    
}

static unsigned long int next = 1;

int rand(void) // RAND_MAX assumed to be 32767
{
    next = next * 1103515245 + 12345;
    return (unsigned int)(next/65536) % 32768;
}


int _start() {
    int tty = open("tty0", 0);
    while (tty == -1)
    {
    }

    int vga = set_vga_mode (320, 200, 256);
    if (vga == -1)
    {
        write (tty, "Unable to open vga", 19);
        while (true)
        {
            /* code */
        }
    }

    char *vga_buff = mmap(NULL, 320*200, 0, 0, vga, 0);
    if (vga_buff == NULL)
    {
        write (tty, "Unable to map vga_buff", 23);
        while (true)
        {
            /* code */
        }
    }

    int systick_fd = open("systick", 0);
    if (systick_fd == -1)
    {
        write (tty, "Unable to open systick", 23);
        while (true)
        {
        }
    }

    int keyboard_fd = open("keyboard", 0);
    if (keyboard_fd == -1)
    {
        write (tty, "Unable to open keyboard", 24);
        while (true)
        {
        }
    }


    char buff[256];

    
    int systick = 0;
    int tick = 0;
    int x = 0;
    int y = 0;
    int direction_x = 0;
    int direction_y = 0;
    int next_fruit = 0;

    direction_t prev_direction = RIGHT;
    direction_t direction = RIGHT;

    #define MAX_BODY_PART 256
    point_t body[MAX_BODY_PART];

    int head = 0;
    int tail = 0;

    body [head] = (point_t){
        .x = x,
        .y = y,
    };
    
    point_t fruit;
    bool fruit_valid = false;
    
    memset (vga_buff, 215, 320 * 200);
    int step = 10;
    draw_box (vga_buff, body[head].x, body[head].y, step, step, 185);
    
    while (1)
    {

        busy_wait_ms (systick_fd, 25);

        int n = snprintf (buff, sizeof (buff), "tick: %d\n", tick);
        write (tty, buff, n);

        if (next_fruit == 0 && !fruit_valid)
        {
            fruit = (point_t){
                .x = (((rand() % (320 - step)) + step - 1) / step) * step,
                .y = (((rand() % (200 - step)) + step - 1) / step) * step,
            };
            fruit_valid = true;
        }
        
        int key = -1;
        while (read (keyboard_fd, &key, sizeof (int)) != -1 && key != -1)
        {
            switch (key)
            {
                case 17:
                    direction = UP;
                    break;
                case 31:
                    direction = DOWN;
                    break;
                case 30:
                    direction = LEFT;
                    break;
                case 32:
                    direction = RIGHT;
                    break; 
                default:
                    break;
            }
        }

        switch (direction)
        {
            case LEFT:
                if (prev_direction != RIGHT)
                {
                    direction_x = -1;
                    direction_y = 0;
                    prev_direction = LEFT;
                }
                break;
            case RIGHT:
                if (prev_direction != LEFT)
                {
                    direction_x = 1;
                    direction_y = 0;
                    prev_direction = RIGHT;
                }
                break;
            case UP:
                if (prev_direction != DOWN)
                {
                    direction_x = 0;
                    direction_y = -1;
                    prev_direction = UP;
                }
                break;
            case DOWN:
                if (prev_direction != UP)
                {
                    direction_x = 0;
                    direction_y = 1;
                    prev_direction = DOWN;
                }
                break;
            default:
                break;
        }
        
        head = (head + 1) % MAX_BODY_PART;
        x += (direction_x * step);
        y += (direction_y * step);
        body [head] = (point_t){
            .x = x,
            .y = y,
        };
        if (x < 0 || y < 0)
        {
            break;
        }
        if (y >= 200 || x >= 320)
        {
            break;
        }

        for (int i = tail; i != head; i = (i + 1) % MAX_BODY_PART)
        {

            if (body[i].x == body[head].x && body[i].y == body [head].y)
            {
                goto lost;
            }
        }
        
        if (fruit_valid)
        {
            draw_box (vga_buff, fruit.x, fruit.y, step, step, 210);
        }

        draw_box (vga_buff, body[head].x, body[head].y, step, step, 185);
        if (fruit_valid && fruit.x == body[head].x && fruit.y == body [head].y)
        {
            fruit_valid = false;
            next_fruit = rand() % 10;
        } else {
            draw_box (vga_buff, body[tail].x, body[tail].y, step, step, 215);
            tail = (tail + 1) % MAX_BODY_PART;
        }

        if (!fruit_valid)
        {
            next_fruit--;
        }
        tick++;
        n = snprintf (buff, sizeof (buff), "%d : %d\n", (unsigned) body[head].x, (unsigned)body[head].y);
        write (tty, buff, n);
    }
    
lost:
    load_image (vga_buff, "test.bmp");

    while (1)
    {
        // asm volatile ("hlt");
    }    
}