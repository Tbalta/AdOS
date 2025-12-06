#ifndef __SNAKE_H
#define __SNAKE_H


struct point {
    int x;
    int y;
};
typedef struct point point_t;

enum direction {
    DOWN,
    UP,
    LEFT,
    RIGHT
};
typedef enum direction direction_t;

#endif