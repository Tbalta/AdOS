.POSIX:
.PHONY: clean run run-img

OBJ = obj

qemu_param = -no-reboot -D ./log.txt -d int,guest_errors -serial mon:stdio -m 1G
makeall:
	mkdir -p runtime/build/adalib
	cd runtime && gprbuild
	gprbuild

main.iso: main.elf
	cp '$<' iso/boot
	grub-mkrescue /usr/lib/grub/i386-pc -o '$@' iso

# main.elf is the the multiboot file.



CCFLAGS = -m32 -L. -lk
main.elf: makeall entry.o gdt.o idt.o stubs.o
	ld -m elf_i386 -T linker.ld -o '$@' $(OBJ)/*.o -g -Lruntime/build/adalib -lgnat -L. -lk

%.o: adOS/src/%.asm
	nasm -f elf32 '$<' -o "$(OBJ)/$@" -g 

main.o: main.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<' -m32 -L. -lk


%.o: %.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'  -L. -lk
%.o: arch/%.adb
	gcc -c -m32 -Os -o '$@' -Wall -Wextra '$<'  -L. -lk


# %.o: %.c
# 	# gcc -c -m32 -Os -o obj/'$@' -Wall -Wextra '$<' -m32 -L. -lk -nostdlib

clean:
	$(RM) -r obj/
	$(RM) -r runtime/obj
	$(RM) -r runtime/build/adalib

run: main.iso
	"/mnt/c/program files/qemu/qemu-system-i386.exe" -cdrom '$<' $(qemu_param)

format:
	gnatpp $(wildcard adOS/**/*.adb) $(wildcard adOS/**/*.ads) -rnb