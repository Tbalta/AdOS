
Some parts of the code are extracted for this sources: <br />
https://github.com/cirosantilli/x86-bare-metal-examples#multiboot <br />
https://github.com/ajxs/cxos/ <br />
https://wiki.osdev.org/Ada_Bare_bones <br />

# Cross compiler
Follow this tutorial: <br />
https://wiki.osdev.org/GNAT_Cross-Compiler <br />

Note that if the compiler is not found you may want to create a symbolic link to `${arch}-elf-gnatgcc` which reference `${arch}-elf-gcc`. <br />
You can also edit the `Library_Builder` inside `linker.xml` in case gprlib is not located at `libexec/gprlib`. but at `lib/gprlib`.

# Secondary Stack
There is a non negligible amount of luck that there is an UB inside `s-secsta.abd` and that it’s will cause a bug that later will be hard to fix. <br />