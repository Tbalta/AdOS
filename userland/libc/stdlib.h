#ifndef __STDLIB_H
#define __STDLIB_H

#include <stddef.h>

void *malloc(size_t size);
void free(void *ptr);
void *calloc(size_t nmemb, size_t size);
void *realloc(void *ptr, size_t size);
void *reallocarray(void *ptr, size_t nmemb, size_t size);

int atoi(const char *nptr);
long atol(const char *nptr);
long long atoll(const char *nptr);
double atof(const char *nptr);

void exit(int status);

int abs(int j);
long labs(long j);
long long llabs(long long j);

#endif