# ARMGNU?=riscv64-linux-gnu
ARMGNU?=riscv64-elf

AOPS = --warn --fatal-warnings

all : mecrisp-quintus-ch32v307vct6.bin

mecrisp-quintus-ch32v307vct6.o : mecrisp-quintus-ch32v307vct6.s
	$(ARMGNU)-as -g mecrisp-quintus-ch32v307vct6.s -o mecrisp-quintus-ch32v307vct6.o -march=rv32im

mecrisp-quintus-ch32v307vct6.bin : memmap mecrisp-quintus-ch32v307vct6.o
	$(ARMGNU)-ld -o mecrisp-quintus-ch32v307vct6.elf -T memmap mecrisp-quintus-ch32v307vct6.o -m elf32lriscv && \
	$(ARMGNU)-objdump -Mnumeric -D mecrisp-quintus-ch32v307vct6.elf -j .text > mecrisp-quintus-ch32v307vct6.list && \
	$(ARMGNU)-objcopy mecrisp-quintus-ch32v307vct6.elf mecrisp-quintus-ch32v307vct6.bin -O binary && \
	$(ARMGNU)-objcopy mecrisp-quintus-ch32v307vct6.elf mecrisp-quintus-ch32v307vct6.hex -O ihex

clean:
	rm -f *~
	rm -f *.bin
	rm -f *.hex
	rm -f *.o
	rm -f *.elf
	rm -f *.list
