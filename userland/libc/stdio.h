#ifndef STDIO_H_
#define STDIO_H_
#include <stddef.h>
#include <stdarg.h>

typedef int FILE;

int puts(const char *s);
int printf(const char *format, ...);
int fprintf(FILE *stream, const char *format, ...);
int vfprintf(FILE *stream, const char *format, va_list args);
int fflush(FILE *stream);

int sprintf(char *str, const char *format, ...);
int snprintf(char *buf, size_t size, const char *fmt, ...);
int vsnprintf(char *buf, size_t size, const char *fmt, va_list args);

char* itoa (char *buf, size_t size, int val);

#define SEEK_SET	0	/* Seek from beginning of file.  */
#define SEEK_CUR	1	/* Seek from current position.  */
#define SEEK_END	2	/* Seek from end of file.  */

extern FILE *stdin;
extern FILE *stdout;
extern FILE *stderr;

int fputc(int c, FILE *stream);
int fputs(const char *s, FILE *stream);
FILE *fopen(const char *pathname, const char *mode);
FILE *fdopen(int fd, const char *mode);
FILE *freopen(const char *pathname, const char *mode, FILE *stream);
int putc(int c, FILE *stream);
int putchar(int c);
int puts(const char *s);

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
int fseek(FILE *stream, long offset, int whence);
long ftell(FILE *stream);
void rewind(FILE *stream);
int fclose(FILE *stream);

int sscanf(const char *str, const char *format, ...);
int vfscanf(FILE *stream, const char *format, va_list ap);


int remove(const char *pathname);
int rename(const char *oldpath, const char *newpath);

int system(const char *command);

#endif