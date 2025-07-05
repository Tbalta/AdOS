.POSIX:
.PHONY: clean run run-img main.elf

OBJ = obj

qemu_param = -no-reboot -boot d -D ./log.txt -d int,guest_errors -serial mon:stdio -m 1G

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

run: main.iso
	qemu-system-i386 -cdrom '$<' $(qemu_param)

debug: main.iso
	qemu-system-i386 -cdrom '$<' $(qemu_param) -s -S

format:
	gnatpp $(wildcard adOS/**/*.adb) $(wildcard adOS/**/*.ads) -rnb

docker-make:
	docker-compose -f .docker/docker-compose.yml run --rm --remove-orphans ados make

docker-build:
	docker-compose -f .docker/docker-compose.yml build ados

docker-run:
	docker-compose -f .docker/docker-compose.yml run --rm --remove-orphans ados