.POSIX:
.PHONY: clean run run-img

qemu_param = -vga std -D ./log.txt -d int,guest_errors -boot d -M q35 -serial mon:stdio -m 1G

main.img: main.elf
	cp '$<' iso/boot
	grub-mkrescue -o '$@' iso

# main.elf is the the multiboot file.
main.elf: entry.o x86-port_io.o serial.o main.o
	ld -m elf_i386 -T linker.ld -o '$@' $^

entry.o: entry.asm
	nasm -f elf32 '$<' -o '$@'

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
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -kernel '$<' $(qemu_param)

run-img: main.img
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -hda '$<'
