#include "stdio.h"

#include <stdarg.h>
#include "string.h"
#include "syscall.h"
#include "stdlib.h"

int fputs(const char *s, FILE *stream)
{
    return fwrite (s, strlen(s), 1, stream);
}

int putchar(int c)
{
    return fwrite (&c, 1, 1, stdout);
}

int puts(const char *s)
{
    int result = fputs (s, stdout);
    result += putchar('\n');
    return result;

}

char* itoa (char *buf, size_t size, int val)
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

FILE *fopen(const char *pathname, const char *mode)
{
    static FILE files[256];
    int fd = open(pathname, 0);
    if (fd == -1)
    {
        return NULL;
    }
    files[fd] = fd;
    return &files[fd];
}

int fclose(FILE *stream)
{
    return close(*stream);
}

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream)
{
    size_t written = 0;
    for (size_t i = 0; i < nmemb; i++)
    {
        written += write(*stream, ptr, size);
        ptr += nmemb;
    }

    return written;
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream)
{
    return read(*stream, ptr, size*nmemb);
}

int fseek(FILE *stream, long offset, int whence)
{
    return lseek (*stream, offset, whence);
}

long ftell(FILE *stream)
{
    return lseek (*stream, 0, SEEK_CUR);
}

void rewind(FILE *stream)
{
    lseek (*stream, 0, SEEK_SET);
}

int fflush(FILE *stream)
{
    return 0;
}


int snprintf(char *buf, size_t size, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    int result = vsnprintf (buf, size, fmt, args);
    va_end(args);
    return result;
}

int vsnprintf(char *buf, size_t size, const char *fmt, va_list args)
{
    int i;
    char int_buffer [32];

    for (i = 0; i < (int)size - 1 && *fmt != '\0';) {
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
                for (; *str != '\0' && i < (int)(size - 1); i++)
                {
                    buf[i] = *str++;
                }
            }
            break;
        
        case 'd':
        case 'i':
        {
            unsigned int val = va_arg (args, unsigned int);
            char* str = itoa (int_buffer, sizeof (int_buffer), val);
            for (; *str != '\0' && i < (int)(size - 1); i++)
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
    return (int)i;
}

int printf(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    int result = vfprintf (stdout, format, args);
    va_end(args);

    return result;
}

int fprintf(FILE *stream, const char *format, ...)
{
    va_list args;
    va_start(args, format);
    int result = vfprintf (stream, format, args);
    va_end(args);
    return result;
}

int vfprintf(FILE *stream, const char *format, va_list args)
{
    int i;
    char int_buffer [32];
    static char printf_buffer[512];

    for (i = 0; *format != '\0';) {
        
        if (*format != '%') {
            printf_buffer[i++] = *format++;
            if (i == sizeof(printf_buffer) - 2)
            {
                printf_buffer[i + 1] = '\0';
                fputs( printf_buffer, stream);
                i = 0;
            }
            continue;
        }

        format++;

        switch (*format++)
        {
        case 's':
            {
                const char *str = va_arg (args, const char*);
                for (; *str != '\0'; i++)
                {
                    printf_buffer[i] = *str++;
                    if (i == sizeof(printf_buffer) - 2)
                    {
                        printf_buffer[i + 1] = '\0';
                        fputs( printf_buffer, stream);
                        i = 0;
                    }
                }
            }
            break;
        
        case 'i':
        case 'd':
        {
            unsigned int val = va_arg (args, unsigned int);
            char* str = itoa (int_buffer, sizeof (int_buffer), val);
            for (; *str != '\0'; i++)
            {
                printf_buffer[i] = *(str++);
                if (i == sizeof(printf_buffer) - 2)
                {
                    printf_buffer[i + 1] = '\0';
                    fputs( printf_buffer, stream);
                    i = 0;
                }
            }

        }
        break;

        // case 'f':
        // {
        //     unsigned int val = va_arg (args, unsigned int);
        //     char* str = atof (int_buffer, sizeof (int_buffer), val);
        //     for (; *str != '\0'; i++)
        //     {
        //         printf_buffer[i] = *(str++);
        //         if (i == sizeof(printf_buffer) - 2)
        //         {
        //             printf_buffer[i + 1] = '\0';
        //             fputs( printf_buffer, stream);
        //             i = 0;
        //         }
        //     }
        // }
        break;

        default:
            break;
    }
    }
    printf_buffer[i] = '\0'; // Ensure null-termination
    fputs( printf_buffer, stream);
    return (int)i;
}

int sscanf(const char *str, const char *format, ...)
{
    return 0;
}

int rename(const char *oldpath, const char *newpath)
{
    return -1;
}

int remove(const char *pathname)
{
    return -1;
}

int system(const char *command)
{
    return -1;
}
