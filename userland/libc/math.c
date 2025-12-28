#include "math.h"

int abs(int j)
{
    if (j < 0)
        return -j;
    return j;
}

double fabs(double x)
{
    if (x < 0)
        return -x;
    return x;
}
