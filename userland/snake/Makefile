SRC = $(wildcard *.c)
OBJ = $(SRC:.c=.o)

BIN_DIR = ../bin

all: snake

snake: $(OBJ)
	$(CC) -o $(BIN_DIR)/$@.elf $(OBJ) ../libc/crt0.o $(CFLAGS)

clean:
	rm -f $(OBJ)