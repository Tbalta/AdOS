.POSIX:
.PHONY: clean run run-img

main.img: main.elf
	cp '$<' iso/boot
	grub-mkrescue -o '$@' iso

# main.elf is the the multiboot file.
main.elf: entry.o main.o x86-port_io.o serial.o
	# ld -m elf_i386 -nostdlib -T linker.ld -o '$@' $^
	ld -m elf_i386 -T linker.ld -o '$@' $^

entry.o: entry.asm
	nasm -f elf32 '$<' -o '$@'

# main.o: main.c
# 	gcc -c -m32 -std=c99 -ffreestanding -fno-builtin -Os -o '$@' -Wall -Wextra '$<'

main.o: main.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'


%.o: %.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'
%.o: arch/%.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'


clean:
	# rm -f *.elf *.o iso/boot/*.elf *.img
	rm -f *.ali *.elf *.o iso/boot/*.elf *.img

run: main.elf
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -kernel '$<'

run-img: main.img
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -hda '$<'
