SRC = $(wildcard *.c) $(wildcard sys/*.c)

ifeq ($(x86_64), TRUE)
	OBJDIR= obj/x64
	BIN_DIR=../../bin/x64
else
	OBJDIR= obj/i386
	BIN_DIR=../../bin/i386
endif

OBJ = $(addprefix $(OBJDIR)/,$(filter-out crt0.o, $(SRC:.c=.o)))

LIB = libc.a

all: $(OBJDIR) $(LIB) $(OBJDIR)/crt0.o

$(OBJDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $^ -o $@

$(OBJDIR):
	mkdir -p $@
	mkdir -p $@/sys


$(LIB) : $(OBJ)
	$(AR) rcs $(OBJDIR)/$@ $(OBJ)

clean:
	rm -f $(OBJ) $(LIB) $(OBJDIR)/crt0.o
	$(RM) -r $(OBJDIR)

.PHONY: $(OBJDIR)