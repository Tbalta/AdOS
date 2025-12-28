#include "syscall.h"

static int _stdout;
static int _stderr;

int *stdout;
int *stderr;
int main(int argc, char ** argv);
void stdlib_init(void);

int _start()
{
    stdout = &_stdout;
    stderr = &_stderr;
    char *argv[3] = {
        "test",
        "-mb",
        "5"
    };
    int argc = 3;
    _stdout = open("tty0", 0);
    _stderr = _stdout;
    stdlib_init();
    main(argc, argv);

    while (1)
    {
        /* code */
    }
    
}