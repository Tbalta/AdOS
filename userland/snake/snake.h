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


enum direction {
    DOWN,
    UP,
    LEFT,
    RIGHT,
    NONE,
};
typedef enum direction direction_t;

#endif