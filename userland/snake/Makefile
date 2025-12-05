SRC = $(wildcard *.c)
OBJ = $(SRC:.c=.o)

CC = i386-elf-gcc
CFLAGS = -ffreestanding -O0 -nostdlib -fno-builtin -Wall -Wextra -m32  -ffunction-sections -fdata-sections -fno-stack-protector -fno-zero-initialized-in-bss -I../libc -L ../libc/ -l:libc.a

BIN_DIR = ../bin

all: snake

snake: $(OBJ)
	$(CC) -o $(BIN_DIR)/$@.elf $(OBJ) $(CFLAGS)

clean:
	rm -f $(OBJ)