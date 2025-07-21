.POSIX:
.PHONY: clean run run-img main.elf

OBJ = obj

qemu_param = -no-reboot -boot d -D ./log.txt -d int,guest_errors,in_asm -serial mon:stdio -m 1G

all: main.iso

main.iso: main.elf
	cp '$<' iso/boot
	grub-mkrescue /usr/lib/grub/i386-pc -o '$@' iso

main.elf:
	cd runtime && gprbuild
	gprbuild

clean:
	cd runtime && gprclean
	gprclean

run:
	qemu-system-i386.exe -cdrom main.iso $(qemu_param)

debug:
	qemu-system-i386.exe -cdrom '$<' $(qemu_param) -s -S

format:
	gnatformat  -P default.gpr -w 100 $(shell find adOS/ -name '*.adb' -or -name '*.ads')

docker-make:
	docker-compose -f .docker/docker-compose.yml run --rm --remove-orphans ados make
	qemu-system-i386.exe -cdrom main.iso $(qemu_param)

docker-build:
	docker-compose -f .docker/docker-compose.yml build ados

docker-run:
	docker-compose -f .docker/docker-compose.yml run --rm --remove-orphans ados

docker-debug:
	docker-compose -f .docker/docker-compose.yml run --rm --remove-orphans ados make
	qemu-system-i386.exe -cdrom main.iso $(qemu_param) -s -S
	