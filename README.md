# AdOS
AdOS is a proof of concept for an operating system kernel written in Ada. <br />


# Project status
Currently AdOS support:
- Booting through GRUB2
- Serial output
- Basic memory management with paging
- Basic file system support for ISO9660
- ELF loading and execution in user space
- Read, Write, Open syscalls



# Building
# Prerequisites
- qemu-system-i386 should be installed on the host system

## Build with Docker
```bash
# 1. Create the AdOS docker image
make docker-build

# 2. Build AdOS using the docker image then run it in QEMU
make docker-make
```

## Build natively
### Dependencies
- nasm
- grub-pc-bin
- grub-common
- gcc-i366-elf
- gnat-i386-elf
- gnatformat (installed through alr, see below)

### gcc-i386-elf and gnat-i386-elf cross compiler installation
Follow this tutorial: <br />
https://wiki.osdev.org/GNAT_Cross-Compiler <br />

Note that if the compiler is not found you may want to create a symbolic link to `${arch}-elf-gnatgcc` which reference `${arch}-elf-gcc`. <br />
You can also edit the `Library_Builder` inside `linker.xml` in case gprlib is not located at `libexec/gprlib`. but at `lib/gprlib`.

Example for `linker.xml` and `compilers.xml` can be found in `.docker/`
### Building AdOS
```bash
make
make run
```

# Remarks
## gnatformat
Gnatformat installation should be don through alr.

Since it seems there is an issue with alr 1.2.0 distributed on Ubuntu 24.04, a newer version of alr should be installed.

1. Fetch the latest alr release from https://github.com/alire-project/alire/releases/tag/v2.1.0
1. Using unzip extract the alr binary from the archive
1. Copy the alr binary to `/usr/local/bin`
1. Update the alr database:
   ```bash
   alr index --update-all
   ```
1. Fetch gnatformat using alr: 
   ```bash
   alr get gnatformat
   ```
1. Build gnatformat using alr:
   ```bash
   alr build gnatformat && alr install gnatformat
    ```
1. Copy the gnatformat binary to `/usr/local/bin`
```bash
wget https://github.com/alire-project/alire/releases/download/v2.1.0/alr-2.1.0-bin-x86_64-linux.zip
unzip alr-2.1.0-bin-x86_64-linux.zip
sudo cp bin/alr /usr/local/bin
alr get libadalang_tools
cd libadalang_tools
alr update
alr build
sudo cp bin/gnatformat /usr/local/bin
```

# Additional resources used for development
https://github.com/cirosantilli/x86-bare-metal-examples <br />
https://github.com/ajxs/cxos/ <br />
https://wiki.osdev.org/Ada_Bare_bones <br />
