
ARMGNU?=riscv64-linux-gnu

AOPS = --warn --fatal-warnings

all : aries-tinyblinky.bin

aries-tinyblinky.o : aries-tinyblinky.s
	$(ARMGNU)-as aries-tinyblinky.s -o aries-tinyblinky.o -march=rv32im_zicsr

aries-tinyblinky.bin : memmap aries-tinyblinky.o
	$(ARMGNU)-ld -o aries-tinyblinky.elf -T memmap aries-tinyblinky.o -m elf32lriscv
	$(ARMGNU)-objdump -Mnumeric -D aries-tinyblinky.elf > aries-tinyblinky.list
	$(ARMGNU)-objcopy aries-tinyblinky.elf aries-tinyblinky.bin -O binary

clean:
	rm -f *.bin
	rm -f *.o
	rm -f *.elf
	rm -f *.list
