#include "stdio.h"
#include <stdarg.h>

char* itoa (char *buf, size_t size, unsigned int val)
{
    char *buf_end = buf + size - 1;
    *buf_end='\0';

    char minus = val < 0;

    if (val == 0)
    {
        *(--buf_end) = '0';
    }

    if (val < 0)
    {
        val = -val;
    }

    while (val != 0)
    {
        *(--buf_end) = (val % 10) + '0';
        val /= 10;
    }

    if (minus)
    {
        *(--buf_end) = '-';
    }

    return buf_end;
}

char* to_hex (char * buf, size_t size, unsigned int val)
{
    const char hex[] = {
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    };

    char *buf_end = buf + size - 2;
    *(--buf_end)='\0';

    if (val == 0)
    {
        *(--buf_end) = '0';
    }

    while (val != 0)
    {
        *(--buf_end) = hex[val % 16];
        val /= 16;
    }

    return buf_end;
}

int snprintf(char *buf, size_t size, const char *fmt, ...)
{
    va_list args;
    int i;
    char int_buffer [32];

    va_start(args, fmt);
    for (i = 0; i < size - 1 && *fmt != '\0';) {
        
        if (*fmt != '%') {
            buf[i++] = *fmt++;
            continue;
        }

        fmt++;

        switch (*fmt++)
        {
        case 's':
            {
                const char *str = va_arg (args, const char*);
                for (; *str != '\0' && i < size - 1; i++)
                {
                    buf[i] = *str++;
                }
            }
            break;
        
        case 'd':
        {
            unsigned int val = va_arg (args, unsigned int);
            char* str = to_hex (int_buffer, sizeof (int_buffer), val);
            for (; *str != '\0' && i < size - 1; i++)
            {
                buf[i] = *(str++);
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