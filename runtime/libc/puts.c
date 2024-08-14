#include <string.h>


extern void send_cchar(const char c);
int write(const char *s, size_t nb)
{
	for (size_t i = 0; i < nb; i++)
	{
		send_cchar(s[i]);
	}
	return nb;
}

int puts(const char *s)
{
	return write(s, strlen(s));
}
