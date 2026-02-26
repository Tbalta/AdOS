ifeq ($(x86_64), TRUE)
export CC = x86_64-elf-gcc
export CFLAGS = -ffreestanding -O0 -nostdlib -fno-builtin -Wall -Wextra  -ffunction-sections -fdata-sections -fno-stack-protector -fno-zero-initialized-in-bss -I../libc -L ../libc/ -l:libc.a -D__x86_64__
else
export CC = i386-elf-gcc
export CFLAGS = -ffreestanding -O0 -nostdlib -fno-builtin -Wall -Wextra  -ffunction-sections -fdata-sections -fno-stack-protector -fno-zero-initialized-in-bss -I../libc -L ../libc/ -l:libc.a -D__i386__
endif

BIN_DIR = bin

PROJECTS = libc test snake # doomgeneric/doomgeneric

PROJECTS_CLEAN = $(PROJECTS:%=%.clean)

.PHONY: make_dir $(PROJECTS) $(PROJECTS_CLEAN) clean

all: make_dir $(PROJECTS)

make_dir:
	mkdir -p $(BIN_DIR)

$(PROJECTS):
	$(MAKE) -C $@


$(PROJECTS_CLEAN):
	$(MAKE) -C $(@:.clean=) clean

clean: $(PROJECTS_CLEAN)
	echo $(PROJECTS_CLEAN)
	$(RM) -r $(BIN_DIR)