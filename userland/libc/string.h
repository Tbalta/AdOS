#ifndef __STRING_H
#define __STRING_H

#include <stddef.h>

void *memset(void *s, int c, size_t n);
size_t strlen( const char * str );
void *memcpy(void *dest, const void *src, size_t n);

char *strchr(const char *s, int c);
char *strrchr(const char *s, int c);

char *strdup(const char *s);
char *strndup(const char *s, size_t n);
char *strdupa(const char *s);
char *strndupa(const char *s, size_t n);

void *memmove(void *dest, const void *src, size_t n);
int strcmp(const char *s1, const char *s2);
int strncmp(const char *s1, const char *s2, size_t n);

char *strcpy(char *dest, const char *src);
char *strncpy(char *dest, const char *src, size_t n);

char *strstr(const char *haystack, const char *needle);

#endif