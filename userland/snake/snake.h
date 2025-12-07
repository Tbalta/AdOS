#ifndef __SNAKE_H
#define __SNAKE_H


struct point {
    int x;
    int y;
};
typedef struct point point_t;

struct dimensions
{
    int width;
    int height;
};
typedef struct dimensions dimensions_t;

struct box
{
    int x;
    int y;
    int width;
    int height;
};
typedef struct box box_t;


enum direction {
    DOWN,
    UP,
    LEFT,
    RIGHT
};
typedef enum direction direction_t;

#endif