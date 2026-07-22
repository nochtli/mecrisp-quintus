# RVGNU?=riscv64-linux-gnu
RVGNU?=riscv64-elf

AOPS = --warn --fatal-warnings

all : mecrisp-quintus-ch32x035.bin

mecrisp-quintus-ch32x035.o : mecrisp-quintus-ch32x035.s terminal.s interrupts.s flash.s
	$(RVGNU)-as -g mecrisp-quintus-ch32x035.s -o mecrisp-quintus-ch32x035.o -march=rv32im

mecrisp-quintus-ch32x035.bin : memmap mecrisp-quintus-ch32x035.o
	$(RVGNU)-ld -o mecrisp-quintus-ch32x035.elf -T memmap mecrisp-quintus-ch32x035.o -m elf32lriscv && \
	$(RVGNU)-objdump -Mnumeric -D mecrisp-quintus-ch32x035.elf -j .text > mecrisp-quintus-ch32x035.list && \
	$(RVGNU)-objcopy mecrisp-quintus-ch32x035.elf mecrisp-quintus-ch32x035.bin -O binary && \
	$(RVGNU)-objcopy mecrisp-quintus-ch32x035.elf mecrisp-quintus-ch32x035.hex -O ihex

clean:
	rm -f *.bin
	rm -f *.hex
	rm -f *.o
	rm -f *.elf
	rm -f *.list
	rm -f *~
