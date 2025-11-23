#ifndef STDIO_H_
#define STDIO_H_
#include <stddef.h>
#include <stdarg.h>
int puts(const char *s);
int printf(const char *format, ...);
int snprintf(char *buf, size_t size, const char *fmt, ...);
#endif