# Disclaimer
Some parts of the code are extracted for these sources: <br />
https://github.com/cirosantilli/x86-bare-metal-examples <br />
https://github.com/ajxs/cxos/ <br />
https://wiki.osdev.org/Ada_Bare_bones <br />
This kernel is a proof of concept in ada as well an opportunity for me to learn Ada. <br />
# Project status
For now the compilation of AdOS doesn’t use the GNAT binder which may lead to a lot of undefined behavior within the kernel.
The current goal is to compile the kernel with the Binder. However the command:
`gnatbind -n -o init.adb --RTS=runtime/build obj/*.ali` generate an invalid `init.adb` file.
Debugging this problem might be hard so I will reimplement AdOS from scratch with a correct compilation process.

# Cross compiler
Follow this tutorial: <br />
https://wiki.osdev.org/GNAT_Cross-Compiler <br />

Note that if the compiler is not found you may want to create a symbolic link to `${arch}-elf-gnatgcc` which reference `${arch}-elf-gcc`. <br />
You can also edit the `Library_Builder` inside `linker.xml` in case gprlib is not located at `libexec/gprlib`. but at `lib/gprlib`.

# Secondary Stack
There is a non negligible amount of luck that there is an UB inside `s-secsta.abd` and that it’s will cause a bug that later will be hard to fix. <br />

# __gnat_rcheck_CE_Invalid_Data
Because I have no idea of where `__gnat_rcheck_CE_Invalid_Data` come from, i created it as a dummy symbol inside `stubs.asm`.

# dependencies
qemu-system-i386, nasm, grub-pc-bin, grub-common

# gnatformat
Gnatformat installation should be don through alr. \\
Since it seems that alr 1.2.0 distributed on Ubuntu 24.04 is unusable, a newer version of alr should be installed.

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