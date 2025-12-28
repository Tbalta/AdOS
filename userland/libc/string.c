#include "string.h"
#include "stdlib.h"
size_t strlen( const char * str )
{
    size_t i = 0;
    if (str == NULL)
        return 0;
    
    while (str[i] != '\0')
    {
        i++;
    }
    
    return i;
}

void *memset(void *s, int c, size_t n)
{
	char *p = s;

	for (size_t i = 0; i < n; ++i)
		p[i] = c;

	return s;
}

void *memcpy(void *dest, const void *src, size_t n)
{
	const char *s = src;
	char *d = dest;

	for (size_t i = 0; i < n; i++)
		*d++ = *s++;

	return dest;
}

char *strchr(const char *s, int c)
{
    if (s == NULL)
    {
        return NULL;
    }

    const char *result = NULL;
    while (*s != '\0' && *s != (char)c)
    {
        s++;
    }
    
    if (*s == (char)c)
    {
        result = s;
    }

    return (char *)result;
}

char *strrchr(const char *s, int c)
{
    if (s == NULL)
    {
        return NULL;
    }

    const char *result = NULL;
    while (*s != '\0')
    {
        if (*s == (char)c)
        {
            result = s;
        }
        s++;
    }


    return (char *)result;
}

char *strdup(const char *s)
{
    if (s == NULL)
    {
        return NULL;
    }
    size_t len = strlen(s);
    char *new_string = calloc (1, len);
    if (new_string == NULL)
    {
        return NULL;
    }

    memcpy(new_string, s, len);
    return new_string;
}

// char *strndup(const char *s, size_t n);
// char *strdupa(const char *s);
// char *strndupa(const char *s, size_t n);

void *memmove(void *dest, const void *src, size_t n)
{
	char *d = dest;
	const char *s = src;

	if (s < d && s + n > d) {
		while (n-- > 0)
			d[n] = s[n];
		return dest;
	}

	return memcpy(dest, src, n);
}

int strcmp(const char *s1, const char *s2)
{
    if (s1 == NULL || s2 == NULL)
    {
        return s1 == s2;
    }

    while (*s1 == *s2 && *s1 != '\0' && *s2 != '\0')
    {
        s1++;
        s2++;
    }

    return *s1 - *s2;
}

int strncmp(const char *s1, const char *s2, size_t n)
{
    if (s1 == NULL || s2 == NULL)
    {
        return s1 == s2;
    }
    
    while (*s1 == *s2 && *s1 != '\0' && *s2 != '\0' && n > 0)
    {
        s1++;
        s2++;
        n--;
    }
    
    return *s1 - *s2;
}

char *strcpy(char *dest, const char *src)
{
    if (dest == NULL || src == NULL)
    {
        return dest;
    }
    for (size_t i = 0; src[i] != '\0'; i++)
    {
        dest[i] = src[i];
    }
    return dest;
}

char *strncpy(char *dest, const char *src, size_t n)
{
    if (dest == NULL || src == NULL)
    {
        return dest;
    }
    size_t i = 0;
    for (; src[i] != '\0' && i < n; i++)
    {
        dest[i] = src[i];
    }
    for (; i < n; i++)
    {
        dest[i] = '\0';
    }
    return dest;

}

char *strstr(const char *haystack, const char *needle)
{
    size_t needle_len = strlen(needle);
    for (; *haystack != '\0'; haystack++)
    {
        if (strncmp (haystack, needle, needle_len) == 0)
            return (char*)haystack;
    }

    return NULL;
}