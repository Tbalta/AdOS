SRC = $(wildcard *.c)
OBJ = $(SRC:.c=.o)

CC = i386-elf-gcc
CFLAGS = -ffreestanding -O0 -nostdlib -fno-builtin -Wall -Wextra -m32  -ffunction-sections -fdata-sections -fno-stack-protector -fno-zero-initialized-in-bss


LIB = libc.a

all: $(LIB)

$(LIB) : $(OBJ)
	$(AR) rcs $@ $(OBJ)

clean:
	rm -f $(OBJ) $(LIB)