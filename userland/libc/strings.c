#include "ctype.h"

#include "stddef.h"

int strcasecmp(const char *s1, const char *s2)
{
    if (s1 == NULL || s2 == NULL)
    {
        return s1 == s2;
    }

    while (toupper(*s1) == toupper(*s2) && *s1 != '\0' && *s2 != '\0')
    {
        s1++;
        s2++;
    }

    return toupper(*s1) - toupper(*s2);
}

int strncasecmp(const char *s1, const char *s2, size_t n)
{
    if (s1 == NULL || s2 == NULL)
    {
        return s1 == s2;
    }
    
    while (toupper(*s1) == toupper(*s2) && *s1 != '\0' && *s2 != '\0' && n > 0)
    {
        s1++;
        s2++;
        n--;
    }
    
    return n ? toupper (*s1) - toupper (*s2) : 0;
}