.POSIX:
.PHONY: clean run run-img main.elf

OBJ = obj

qemu_param = -no-reboot -boot d -D ./log.txt -d int,guest_errors,in_asm -serial mon:stdio -m 1G

.PHONY: userland


all: main.iso

main.iso: main.elf userland
	cp main.elf iso/boot
	grub-mkrescue /usr/lib/grub/i386-pc -o '$@' iso

make_dir:
	mkdir -p iso/bin

userland: make_dir
	$(MAKE) -C userland
	cp userland/bin/* iso/bin/


main.elf:
	cd runtime && gprbuild
	gprbuild

clean:
	cd runtime && gprclean
	$(MAKE) -C userland clean
	$(RM) -r iso/bin
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

gdb:
	gdb -ex "target remote localhost:1234" main.elf