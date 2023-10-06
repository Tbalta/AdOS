.POSIX:
.PHONY: clean run run-img main.elf

OBJ = obj

qemu_param = -vga std -D ./log.txt -d int,guest_errors -boot d -M q35 -serial mon:stdio -m 1G

all: main.elf

main.img: main.elf
	cp '$<' iso/boot
	grub-mkrescue -o '$@' iso

main.elf:
	cd runtime && gprbuild
	gprbuild

clean:
	cd runtime && gprclean
	gprclean

run: main.elf
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -kernel '$<' $(qemu_param)

debug: main.elf
	qemu-system-i386 -kernel '$<' $(qemu_param) -s -S


run-img: main.img
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -hda '$<'