SRC = $(wildcard *.c)

ifeq ($(x86_64), TRUE)
	OBJDIR=obj/x64
	BIN_DIR=../bin/x64
else
	OBJDIR=obj/i386
	BIN_DIR=../bin/i386
endif

OBJ = $(addprefix $(OBJDIR)/, $(SRC:.c=.o))

all: test

$(OBJDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $^ -o $@

$(OBJDIR):
	mkdir -p $(OBJDIR)


test: $(OBJDIR) $(OBJ)
	$(CC) -o $(BIN_DIR)/$@.elf $(OBJ) ../libc/$(OBJDIR)/crt0.o $(CFLAGS)

clean:
	rm -f $(OBJ)

.PHONY: $(OBJDIR)