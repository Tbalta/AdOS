#include "stdio.h"
#include <stdarg.h>

char* itoa (char *buf, size_t size, int val)
{
    char *buf_end = buf + size - 1;
    *buf_end=0;

    if (val == 0)
    {
        *(--buf_end) = '0';
    }

    if (val < 0)
    {
        val = -val;
        *(--buf_end) = '-';
    }

    while (val != 0)
    {
        *(--buf_end) = (val % 10) + '0';
        val /= 10;
    }

    return buf_end;
}


int snprintf(char *buf, size_t size, const char *fmt, ...)
{
    va_list args;
    int i;

    va_start(args, fmt);
    for (i = 0; i < size - 1 && *fmt != '\0'; i++) {
        
        if (*fmt != '%') {
            buf[i] = *fmt++;
            continue;
        }

        fmt++;

        switch (*fmt++)
        {
        case 's':
            {
                const char *str = va_arg (args, const char*);
                for (; *str != '\0' && i < size; i++)
                {
                    buf[i] = *str++;
                }
            }
            break;
        
        case 'd':
        {
            char int_buffer [10];
            int val = va_arg (args, int);
            const char* str = itoa (int_buffer, sizeof (int_buffer), val);
            for (; *str != '\0' && i < size; i++)
            {
                buf[i] = *str++;
            }

        }
        break;

        default:
            break;
    }
    }

    buf[i] = '\0'; // Ensure null-termination
    va_end(args);
    return i;
}