SRC = $(wildcard *.c) $(wildcard sys/*.c)
OBJ = $(filter-out crt0.o, $(SRC:.c=.o))

LIB = libc.a

all: $(LIB) crt0.o

$(LIB) : $(OBJ)
	$(AR) rcs $@ $(OBJ)

clean:
	rm -f $(OBJ) $(LIB) crt0.o