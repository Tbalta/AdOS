#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5

#include <stdio.h>
#include <stdbool.h>
#include <syscall.h>
#include <vga.h>


int _start() {
    int tty = open("tty0", 0);
    int vga = set_vga_mode (320, 200, 256);
    if (vga == -1)
    {
        write (tty, "Unable to open vga", 19);
        while (true)
        {
            /* code */
        }
    }
    
    unsigned char vga_line[320] = {0};
    char bmp_header[14];
    char read_buffer[100];
    
    
    int ados = open("ados.bmp", 0);
    read (ados, bmp_header, sizeof (bmp_header));
    
    int start = *(int*)(bmp_header + 10);
    int n = snprintf (read_buffer, sizeof(read_buffer), "bmp_start: %d\n", start);
    write(tty, read_buffer, n);
    lseek (ados, start, SEEK_SET);
    
    char *vga_buff = mmap(NULL, 320*200, 0, 0, vga, 0);
    for (int i = 0; i < 200; i++)
    {
        int count = read(ados, vga_buff + (i * 320), sizeof(vga_line));
    }

    while (1)
    {
        // asm volatile ("hlt");
    }    
}