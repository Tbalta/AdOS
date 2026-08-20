#include <stdio.h>
#include <stdbool.h>
#include <syscall.h>
#include "snake.h"
#include <bmp.h>
#include <framebuffer.h>

void draw_box (void *buffer, int x, int y, int w, int h, int color)
{
    int start = (y * 320) + x;

    for (int row = 0; row < h; row++)
    {
        int line_start = start + (row * 320);
        memset (buffer + line_start, color, w );
    }
}

// void draw_image (void *buffer, const char *image, dimensions_t buffer_dims, dimensions_t image_dims, point_t buffer_position, point_t image_position, dimensions_t crop)
// {
//     int buffer_start = (buffer_position.y * buffer_dims.width) + buffer_position.x;
//     int image_start =  (image_position.y * image_dims.width) + image_position.x;

//     for (int row = 0; row < crop.height; row++)
//     {
//         int buffer_line_start  = buffer_start + (row * buffer_dims.width);
//         int image_line_start = image_start + (row * image_dims.width);
//         memcpy (buffer + buffer_line_start, image + image_line_start, crop.width);
//     }
// }

static  inline int min(int a, int b)
{
    if (a < b)
        return a;

    return b;
}

void draw_image (void *buffer, const bmp_image_t *image, const framebuffer_information_t *fb_info, box_t buffer_destination, box_t crop)
{
    int buffer_offset = (buffer_destination.y * fb_info->width) + buffer_destination.x;
    int image_offset  =  (crop.y * image->width) + crop.x;
    
    int scale_factor = min(buffer_destination.width / crop.width, buffer_destination.height / crop.height);

    for (int row = 0; row < crop.height * scale_factor; row++)
    {
        for (int w = 0; w < crop.width; w++)
        {
            int buffer_line_start  = (buffer_offset + (row * fb_info->width) + (w * scale_factor)) * (fb_info->bpp / 8);
            int image_line_start   = (image_offset + ((row / scale_factor) * image->width) + w) * (fb_info->bpp / 8);
            for (int i = 0; i < scale_factor; i++)
            {
                #if defined(__i386__)
                    memcpy (buffer + buffer_line_start + i, ((void*)image->bmp_buffer) + image_line_start, 1);
                #elif defined(__x86_64__)
                    memcpy (buffer + buffer_line_start + (i * (fb_info->bpp / 8)), ((void*)image->rgba_buffer) + image_line_start, (fb_info->bpp / 8));
                #endif
            }
        }
    }
}

static inline box_t get_image_box (const bmp_image_t *image)
{
    return (box_t){
        .x = 0,
        .y = 0,
        .width = image->width,
        .height = image->height,
    };
}


void draw_at (void *buffer, const bmp_image_t *image, const framebuffer_information_t *fb_info, box_t buffer_destination)
{
    draw_image(buffer, image, fb_info, buffer_destination, get_image_box(image));
}

// void copy_image (void *buffer, const char *image, dimensions_t buffer_dims)
// {
//     draw_image (buffer, image, buffer_dims, buffer_dims,  (point_t){0, 0}, (point_t){0, 0}, buffer_dims);
// }


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

// void rotate_left (char *dest, const char *image, int width, int height)
// {
//     for (int col = 0; col < width; col++)
//     {
//         for (int row = 0; row < height; row++)
//         {
//             int src_index = (row * width) + col;
//             int dest_line = (width - 1 ) - col;
//             int dest_col = row;
//             int dest_index = (dest_line * width) + dest_col;
//             dest[dest_index] = image[src_index];
//         }
//     }
// }

int next_mod (int a, int mod)
{
    return (a + 1) % mod;
}
int prev_mod (int a, int mod)
{
    return (a - 1 + mod) % mod;
}


static bmp_image_t head_bmp_down;
static bmp_image_t head_bmp_right;
static bmp_image_t head_bmp_up;
static bmp_image_t head_bmp_left;
static bmp_image_t head_dead_bmp_down;
static bmp_image_t head_dead_bmp_right;
static bmp_image_t head_dead_bmp_up;
static bmp_image_t head_dead_bmp_left;
static bmp_image_t body_bmp;
static bmp_image_t body_boom_bmp;
static bmp_image_t apple_bmp;
static bmp_image_t lost_bmp;

static bmp_image_t garden_bmp;
static bmp_image_t press_to_play_bmp;

static bmp_image_t start_bmp;

bool are_directions_opposite (direction_t dir1, direction_t dir2)
{
    if ((dir1 == LEFT && dir2 == RIGHT) || (dir1 == RIGHT && dir2 == LEFT))
    {
        return true;
    }
    if ((dir1 == UP && dir2 == DOWN) || (dir1 == DOWN && dir2 == UP))
    {
        return true;
    }
    return false;
}

bool is_direction_valid (direction_t new_direction, direction_t current_direction)
{
    return !are_directions_opposite (new_direction, current_direction) && new_direction != NONE;
}

direction_t get_next_direction (int keyboard_fd, direction_t prev_direction)
{
    int key = -1;
    while (read (keyboard_fd, &key, sizeof (int)) != -1 && key != -1)
    {
        int direction = NONE;
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

        if (is_direction_valid (direction, prev_direction) && direction != prev_direction)
        {
            return direction;
        }
    }
    return prev_direction;
}

int map(int value, int from_low, int from_high, int to_low, int to_high)
{
    return (value - from_low) * (to_high - to_low) / (from_high - from_low) + to_low;
}

int main() {   
    bmp_image_t *snake_heads[] = {
        &head_bmp_down,
        &head_bmp_up,
        &head_bmp_left,
        &head_bmp_right,
    };
    bmp_image_t *snake_dead_heads[] = {
        &head_dead_bmp_down,
        &head_dead_bmp_up,
        &head_dead_bmp_left,
        &head_dead_bmp_right,
    };
    
    int tty = 0;
    while (tty == -1)
    {
    }

    int framebuffer_fd = open_framebuffer();
    if (framebuffer_fd == -1)
    {
        printf ("Unable to open framebuffer\n");
        while (true)
        {
            /* code */
        }
    }
 
    framebuffer_information_t fb_info;
    if (get_framebuffer_info(&fb_info) == -1)
    {
        printf ("Unable to get framebuffer info\n");
        while (true)        {
            /* code */
        }
     }

    char *framebuffer = mmap(NULL, fb_info.width * fb_info.height * (fb_info.bpp / 8), 0, 0, framebuffer_fd, 0);
    if (framebuffer == NULL)
    {
        printf ("Unable to map framebuffer\n");
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

    open_bmp ("head.bmp", &head_bmp_down);
    load_rgba(&head_bmp_down);

    rotate_left (&head_bmp_right, &head_bmp_down);
    rotate_left (&head_bmp_up, &head_bmp_right);
    rotate_left (&head_bmp_left, &head_bmp_up);

    open_bmp ("dead.bmp", &head_dead_bmp_down);
    load_rgba(&head_dead_bmp_down);
    rotate_left (&head_dead_bmp_right, &head_dead_bmp_down);
    rotate_left (&head_dead_bmp_up, &head_dead_bmp_right);
    rotate_left (&head_dead_bmp_left, &head_dead_bmp_up);
    
    open_bmp ("body.bmp", &body_bmp);
    load_rgba(&body_bmp);

    open_bmp ("boom.bmp", &body_boom_bmp);
    load_rgba(&body_boom_bmp);

    open_bmp ("apple.bmp", &apple_bmp);
    load_rgba(&apple_bmp);

    open_bmp ("garden.bmp", &garden_bmp);
    load_rgba(&garden_bmp);

    open_bmp ("text.bmp", &press_to_play_bmp);
    load_rgba(&press_to_play_bmp);

    open_bmp ("start.bmp", &start_bmp);
    load_rgba(&start_bmp);
    
    open_bmp ("lost.bmp", &lost_bmp);
    load_rgba(&lost_bmp);


    dimensions_t garden_dims = {.width = 320, .height = 200};
    int scale_factor = min(fb_info.width / garden_dims.width, fb_info.height / garden_dims.height);

    dimensions_t body_part_dims = {
        .width = 10 * scale_factor,
        .height = 10 * scale_factor
    };

    box_t framebuffer_box = {
        .height = fb_info.height,
        .width  = fb_info.width,
        .x = 0,
        .y = 0,
    };

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
    
    box_t fruit = {
        .x = 0,
        .y = 0,
        .width = body_part_dims.width,
        .height = body_part_dims.height
    };
    bool fruit_valid = false;
    int step = 10 * scale_factor;

    int key = -1;

    while (1)
    {
        // main game loop
        // display_rgba (&start_bmp, &fb_info, framebuffer, framebuffer_box);
        draw_at (framebuffer, &start_bmp, &fb_info, framebuffer_box);
            // while (1)
            // {
            // busy_wait_ms (systick_fd, 750);
            // }

        while (1)
        {
            #if defined(__i386__)
                display_indexed(&press_to_play_bmp, &fb_info, (char*)framebuffer, (box_t){.x = (fb_info.width - press_to_play_bmp.width) / 2, .y = fb_info.height - press_to_play_bmp.height, .width = press_to_play_bmp.width, .height = press_to_play_bmp.height});
            #elif defined(__x86_64__)
                display_rgba(&press_to_play_bmp, &fb_info, framebuffer, (box_t){.x = (fb_info.width - press_to_play_bmp.width) / 2, .y = fb_info.height - press_to_play_bmp.height, .width = press_to_play_bmp.width, .height = press_to_play_bmp.height});
            #endif
            // draw_image (vga_buff, press_to_play_bmp, garden_dims, (dimensions_t){320, 50}, (point_t){0, 150}, (point_t){0, 0}, (dimensions_t){320, 50});
            busy_wait_ms (systick_fd, 750);
            while (read (keyboard_fd, &key, sizeof (int)) != -1 && key != 57 && key != -1);
            if (key == 57)
            {
                break;
            }
            // draw_box (vga_buff, 0, 150, 320, 50, 153);
            busy_wait_ms (systick_fd, 500);
            while (read (keyboard_fd, &key, sizeof (int)) != -1 && key != 57 && key != -1);
            if (key == 57)
            {
                break;
            }
        }
        
        printf("continue\n");
        
        // init
        x = 0;
        y = step;
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

        #if defined(__i386__)
            display_indexed(&garden_bmp, &fb_info, (char*)framebuffer, framebuffer_box);
        #elif defined(__x86_64__)
            display_rgba(&garden_bmp, &fb_info, framebuffer, framebuffer_box);
        #endif
        while (1)
        {

            busy_wait_ms (systick_fd, 250);

            if (next_fruit <= 0 && !fruit_valid)
            {
                fruit.x = (((rand() % (fb_info.width - step)) + step - 1) / step) * step;
                fruit.y = (((rand() % (fb_info.height - step)) + step - 1) / step) * step;
                fruit_valid = true;
            }
            
            direction = get_next_direction (keyboard_fd, prev_direction);

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
            if (y >= fb_info.height || x >= fb_info.width)
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
                draw_at (framebuffer, &apple_bmp, &fb_info, fruit);
            }

            draw_at (framebuffer, snake_heads [prev_direction], &fb_info, (box_t){.x = body[head].x, .y = body[head].y, .width = body_part_dims.width, .height = body_part_dims.height});

            
            if (next_mod (tail, MAX_BODY_PART) != head)
            {
                int body_position = prev_mod (head, MAX_BODY_PART);
                draw_at (framebuffer, &body_bmp, &fb_info, (box_t){.x = body[body_position].x, .y = body[body_position].y, .width = body_part_dims.width, .height = body_part_dims.height});
            }


            if (fruit_valid && fruit.x == body[head].x && fruit.y == body [head].y)
            {
                fruit_valid = false;
                next_fruit = (rand() % 10) + 1;
            } else {
                // draw_image (vga_buff, garden, garden_dims, garden_dims, body[tail], body[tail], body_part_dims);
                box_t destination = (box_t){
                    .y = body[tail].y,
                    .x = body[tail].x,
                    .height = body_part_dims.height,
                    .width  = body_part_dims.width,
                };
                box_t source = (box_t){
                    .y = body[tail].y / scale_factor,
                    .x = body[tail].x / scale_factor,
                    .height = 10,
                    .width  = 10,
                };
                
                draw_image(framebuffer, &garden_bmp, &fb_info, destination, source);
                tail = (tail + 1) % MAX_BODY_PART;
            }

            if (!fruit_valid)
            {
                next_fruit--;
            }
            tick++;
    }
    
lost:
    draw_at (framebuffer, snake_dead_heads [prev_direction], &fb_info, (box_t){.x = body[head].x, .y = body[head].y, .width = body_part_dims.width, .height = body_part_dims.height});
    busy_wait_ms (systick_fd, 1000);

    for (int i = tail; i != head; i = next_mod (i, MAX_BODY_PART))
    {
        draw_at (framebuffer, &body_boom_bmp, &fb_info, (box_t){.x = body[i].x, .y = body[i].y, .width = body_part_dims.width, .height = body_part_dims.height});
        busy_wait_ms (systick_fd, 250);
    }
    
    for (int i = tail; i != head; i = next_mod (i, MAX_BODY_PART))
    {
        // draw_image (vga_buff, garden, garden_dims, garden_dims, body[i], body[i], body_part_dims);
        box_t destination = (box_t){
            .y = body[i].y,
            .x = body[i].x,
            .height = body_part_dims.height,
            .width  = body_part_dims.width,
        };
        box_t source = (box_t){
            .y = body[i].y / scale_factor,
            .x = body[i].x / scale_factor,
            .height = 10,
            .width  = 10,
        };
        draw_image(framebuffer, &garden_bmp, &fb_info, destination, source);    
        busy_wait_ms (systick_fd, 250);
    }
    #if defined(__i386__)
        display_indexed(&lost_bmp, &fb_info, (char*)framebuffer, framebuffer_box);
    #elif defined(__x86_64__)
        display_rgba(&lost_bmp, &fb_info, framebuffer, framebuffer_box);
    #endif
    busy_wait_ms (systick_fd, 2000);
}
    while (1)
    {
        // asm volatile ("hlt");
    }    

}