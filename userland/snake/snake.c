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

void *memcpy(void *dest, const void *src, size_t n)
{
	const char *s = src;
	char *d = dest;

	for (size_t i = 0; i < n; i++)
		*d++ = *s++;

	return dest;
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

void draw_image (void *buffer, const char *image, dimensions_t buffer_dims, dimensions_t image_dims, point_t buffer_position, point_t image_position, dimensions_t crop)
{
    int buffer_start = (buffer_position.y * buffer_dims.width) + buffer_position.x;
    int image_start =  (image_position.y * image_dims.width) + image_position.x;

    for (int row = 0; row < crop.height; row++)
    {
        int buffer_line_start  = buffer_start + (row * buffer_dims.width);
        int image_line_start = image_start + (row * image_dims.width);
        memcpy (buffer + buffer_line_start, image + image_line_start, crop.width);
    }
}

void copy_image (void *buffer, const char *image, dimensions_t buffer_dims)
{
    draw_image (buffer, image, buffer_dims, buffer_dims,  (point_t){0, 0}, (point_t){0, 0}, buffer_dims);
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

void rotate_left (char *dest, const char *image, int width, int height)
{
    for (int col = 0; col < width; col++)
    {
        for (int row = 0; row < height; row++)
        {
            int src_index = (row * width) + col;
            int dest_line = (width - 1 ) - col;
            int dest_col = row;
            int dest_index = (dest_line * width) + dest_col;
            dest[dest_index] = image[src_index];
        }
    }
}

int next_mod (int a, int mod)
{
    return (a + 1) % mod;
}
int prev_mod (int a, int mod)
{
    return (a - 1 + mod) % mod;
}


static char head_bmp_down[10*10];
static char head_bmp_right[10*10];
static char head_bmp_up[10*10];
static char head_bmp_left[10*10];
static char head_dead_bmp_down[10*10];
static char head_dead_bmp_right[10*10];
static char head_dead_bmp_up[10*10];
static char head_dead_bmp_left[10*10];
static char body_bmp [10*10];
static char body_boom_bmp [10*10];
static char apple_bmp [10*10];

static char garden[320*200];
static char press_to_play_bmp[320 * 50];

int _start() {

    char* snake_heads[] = {
        head_bmp_down,
        head_bmp_up,
        head_bmp_left,
        head_bmp_right,
    };
    char* snake_dead_heads[] = {
        head_dead_bmp_down,
        head_dead_bmp_up,
        head_dead_bmp_left,
        head_dead_bmp_right,
    };

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

    load_image (head_bmp_down, "head.bmp", 10, 10);
    rotate_left (head_bmp_right, head_bmp_down, 10, 10);
    rotate_left (head_bmp_up, head_bmp_right, 10, 10);
    rotate_left (head_bmp_left, head_bmp_up, 10, 10);

    load_image (head_dead_bmp_down, "dead.bmp", 10, 10);
    rotate_left (head_dead_bmp_right, head_dead_bmp_down, 10, 10);
    rotate_left (head_dead_bmp_up, head_dead_bmp_right, 10, 10);
    rotate_left (head_dead_bmp_left, head_dead_bmp_up, 10, 10);
    
    load_image (body_bmp, "body.bmp", 10, 10);
    load_image (body_boom_bmp, "boom.bmp", 10, 10);
    load_image (apple_bmp, "apple.bmp", 10, 10);
    load_image (garden, "garden.bmp", 320, 200);
    load_image (press_to_play_bmp, "text.bmp", 320, 50);



    dimensions_t garden_dims = {.width = 320, .height = 200};
    dimensions_t body_part_dims = {.width = 10, .height = 10};


    char buff[256];

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
    int step = 10;

    int key = -1;
    while (1)
    {
        // main game loop
        load_image (vga_buff, "start.bmp", 320, 200);
        while (1)
        {
            draw_image (vga_buff, press_to_play_bmp, garden_dims, (dimensions_t){320, 50}, (point_t){0, 150}, (point_t){0, 0}, (dimensions_t){320, 50});
            busy_wait_ms (systick_fd, 75);
            while (read (keyboard_fd, &key, sizeof (int)) != -1 && key != 57 && key != -1);
            if (key == 57)
            {
                break;
            }
            draw_box (vga_buff, 0, 150, 320, 50, 153);
            busy_wait_ms (systick_fd, 50);
            while (read (keyboard_fd, &key, sizeof (int)) != -1 && key != 57 && key != -1);
            if (key == 57)
            {
                break;
            }
        }

        
        // init
        x = 0;
        y = 10;
        head = 0;
        tail = 0;
        fruit_valid = false;
        next_fruit = 0;
        tick = 0;
        body [head] = (point_t){
            .x = x,
            .y = y,
        };
        prev_direction = RIGHT;
        direction = RIGHT;
        copy_image (vga_buff, garden, garden_dims);    
        while (1)
        {

            busy_wait_ms (systick_fd, 25);

            int n = snprintf (buff, sizeof (buff), "tick: %d\n", tick);
            write (tty, buff, n);

            if (next_fruit <= 0 && !fruit_valid)
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
                    case 72:
                        direction = UP;
                        break;
                    case 80:
                        direction = DOWN;
                        break;
                    case 75:
                        direction = LEFT;
                        break;
                    case 77:
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
            
            x += (direction_x * step);
            y += (direction_y * step);
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
                
                if (body[i].x == x && body[i].y == y)
                {
                    goto lost;
                }
            }
            
            head = (head + 1) % MAX_BODY_PART;
            body [head] = (point_t){
                .x = x,
                .y = y,
            };
            if (fruit_valid)
            {
                draw_image (vga_buff, apple_bmp, garden_dims, body_part_dims, fruit, (point_t){0, 0}, body_part_dims);
            }

            draw_image (vga_buff, snake_heads [prev_direction], garden_dims, body_part_dims, body[head], (point_t){0, 0}, body_part_dims);

            
            if (next_mod (tail, MAX_BODY_PART) != head)
            {
                int body_position = prev_mod (head, MAX_BODY_PART);
                draw_image (vga_buff, body_bmp, garden_dims, body_part_dims, body[body_position], (point_t){0, 0}, body_part_dims);
            }


            if (fruit_valid && fruit.x == body[head].x && fruit.y == body [head].y)
            {
                fruit_valid = false;
                next_fruit = (rand() % 10) + 1;
            } else {
                draw_image (vga_buff, garden, garden_dims, garden_dims, body[tail], body[tail], body_part_dims);
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
    draw_image (vga_buff, snake_dead_heads [prev_direction], garden_dims, body_part_dims, body[head],  (point_t){0, 0}, body_part_dims);
    busy_wait_ms (systick_fd, 100);

    for (int i = tail; i != head; i = next_mod (i, MAX_BODY_PART))
    {
        draw_image (vga_buff, body_boom_bmp, garden_dims, body_part_dims, body[i],  (point_t){0, 0}, body_part_dims);
        busy_wait_ms (systick_fd, 25);
    }
    
    for (int i = tail; i != head; i = next_mod (i, MAX_BODY_PART))
    {
        draw_image (vga_buff, garden, garden_dims, garden_dims, body[i], body[i], body_part_dims);
        busy_wait_ms (systick_fd, 25);
    }


    load_image (vga_buff, "lost.bmp", 320, 200);
    busy_wait_ms (systick_fd, 200);
}
    while (1)
    {
        // asm volatile ("hlt");
    }    

}