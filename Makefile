.POSIX:
.PHONY: clean run run-img

OBJ = obj

qemu_param = -no-reboot -D ./log.txt -d int,guest_errors,in_asm -serial mon:stdio -m 1G

main.iso: main.elf
	cp '$<' iso/boot
	grub-mkrescue /usr/lib/grub/i386-pc -o '$@' iso

# main.elf is the the multiboot file.

makeall:
	gprbuild


CCFLAGS = -m32 -L. -lk
main.elf: makeall entry.o gdt.o stubs.o idt.o util.o
	ld -m elf_i386 -T linker.ld -o '$@' $(OBJ)/*.o -g -Llibc -lc

%.o: %.asm
	nasm -f elf32 '$<' -o "$(OBJ)/$@" -g 

main.o: main.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<' -m32 -L. -lk


%.o: %.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<' -m32 -L. -lk
%.o: arch/%.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<' -m32 -L. -lk


%.o: %.c
	gcc -c -m32 -Os -o obj/'$@' -Wall -Wextra '$<' -m32 -L. -lk

clean:
	rm -f *.ali *.elf *.o iso/boot/*.elf *.img obj/* *.pp *.npp log.txt *.pp arch/*.pp

run: main.elf
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -kernel '$<' $(qemu_param)
debug: main.elf
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -kernel '$<' $(qemu_param) -

run-iso: main.iso
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -cdrom '$<' $(qemu_param)

iso: main.iso
	cp '$<' iso/
	mkisofs -o main.iso -V MyOSName -b main.iso iso


format:
	gnatpp $(wildcard **/*.adb) $(wildcard **/*.ads) -rnb