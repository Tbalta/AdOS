#ifndef STDIO_H_
#define STDIO_H_
#include <stddef.h>
#include <stdarg.h>
int puts(const char *s);
int printf(const char *format, ...);
int snprintf(char *buf, size_t size, const char *fmt, ...);
char* itoa (char *buf, size_t size, unsigned int val);

#define SEEK_SET	0	/* Seek from beginning of file.  */
#define SEEK_CUR	1	/* Seek from current position.  */
#define SEEK_END	2	/* Seek from end of file.  */
#endif