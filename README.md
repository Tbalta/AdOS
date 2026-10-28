# AdOS
AdOS is a proof of concept for an operating system kernel written in Ada for i386 and x64 architectures. <br />


# Project status
Currently AdOS support:
- Serial Driver
- Paging
- Basic ISO9660 driver
- ELF loading and execution in user space
- Limited syscall support

# Setup
```bash
git clone git@github.com:Tbalta/AdOS.git
cd AdOS/
git submodule update --init
```

## Doomgeneric
You need to provide your own wad file, place it in `./iso/<file>.wad`


# Building
# Prerequisites
- `qemu-system-i386` and `qemu-system-x86_64` should be installed on the host system

## Build with Docker (Recommended)
```bash

# 1. Create the AdOS docker image (choose 1, both command do the same)
make -f Makefile_x64 docker-build
make -f Makefile_i386 docker-build

# 2. Build AdOS using the docker then run it on QEMU
make -f Makefile_x64 docker-make
make -f Makefile_i386 docker-make
```

## Build natively
### Dependencies
- Follow the steps described in [Dockerfile](.docker/Dockerfile)
- gnatformat (installed through alr, see below)

### Cross compiler installation
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
Gnatformat installation should be done through alr.

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

# References
## Intel
### 8259 PIC 
https://wiki.osdev.org/8259_PIC <br />
https://pdos.csail.mit.edu/6.828/2005/readings/hardware/8259A.pdf <br />
https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html <br />

## Ada
https://www.adaic.org/resources/add_content/standards/22rm/rm-bar.pdf <br />
## Osdev
https://github.com/cirosantilli/x86-bare-metal-examples <br />
https://github.com/ajxs/cxos/ <br />
https://wiki.osdev.org/Ada_Bare_bones <br />
## VGA
http://www.mcamafia.de/pdf/ibm_vgaxga_trm2.pdf <br />
http://www.osdever.net/FreeVGA/vga/crtcreg.htm <br />
https://www.worldradiohistory.com/Archive-Byte/80s/Byte-1988-11-IBM-Issue.pdf <br />
https://wiki.osdev.org/Video_Signals_And_Timing <br />
https://glenwing.github.io/docs/VESA-GTF-1.1.pdf <br />