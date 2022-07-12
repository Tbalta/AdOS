.POSIX:
.PHONY: clean run run-img

OBJ = obj

qemu_param = -vga std -D ./log.txt -d int,guest_errors -boot d -M q35 -serial mon:stdio -m 1G

main.img: main.elf
	cp '$<' iso/boot
	grub-mkrescue -o '$@' iso

# main.elf is the the multiboot file.

makeall:
	gprbuild


main.elf: makeall entry.o gdt.o
	ld -m elf_i386 -T linker.ld -o '$@' $(OBJ)/*.o -g

%.o: %.asm
	nasm -f elf32 '$<' -o "$(OBJ)/$@" -g

main.o: main.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'


%.o: %.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'
%.o: arch/%.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'


clean:
	rm -f *.ali *.elf *.o iso/boot/*.elf *.img obj/* *.pp *.npp log.txt

run: main.elf
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -kernel '$<' $(qemu_param)

run-img: main.img
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -hda '$<'
