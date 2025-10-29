SRC = $(wildcard *.c)
OBJ = $(SRC:.c=.o)

CC = i386-elf-gcc
CFLAGS = -ffreestanding -O0 -nostdlib -fno-builtin -Wall -Wextra -m32

BIN_DIR = ../bin

all: truc

truc: $(OBJ)
	$(CC) -o $(BIN_DIR)/$@.elf $(OBJ) $(CFLAGS)

clean:
	rm -f $(OBJ)