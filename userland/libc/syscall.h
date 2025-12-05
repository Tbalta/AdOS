#ifndef __SYSCALL_H
#define __SYSCALL_H

int write (int fd, const void *buf, unsigned int count);

int read (int fd, void *buf, unsigned int count);
int close (int fd);
int open (const char *pathname, int flags);

int lseek (int fd, int offset, int whence);

void* mmap(void *addr, int length, int prot, int flags, int fd, int offset);

#endif