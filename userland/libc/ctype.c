#include "ctype.h"


int toupper(int c)
{
    if (c >= 'a' && c <= 'z')
    {
        return c - ('a' - 'A');
    }

    return c;
}

int tolower(int c)
{
    
    if (c >= 'A' && c <= 'Z')
    {
        return c + ('a' - 'A');
    }

    return c;
}

int isspace(int c)
{
    return c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r' || c == ' ';
}