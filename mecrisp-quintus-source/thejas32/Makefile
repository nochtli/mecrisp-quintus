
ARMGNU?=riscv64-linux-gnu

AOPS = --warn --fatal-warnings

all : mecrisp-quintus-thejas32.bin

mecrisp-quintus-thejas32.o : mecrisp-quintus-thejas32.s
	$(ARMGNU)-as mecrisp-quintus-thejas32.s -o mecrisp-quintus-thejas32.o -march=rv32im_zicsr

mecrisp-quintus-thejas32.bin : memmap mecrisp-quintus-thejas32.o
	$(ARMGNU)-ld -o mecrisp-quintus-thejas32.elf -T memmap mecrisp-quintus-thejas32.o -m elf32lriscv
	$(ARMGNU)-objdump -Mnumeric -D mecrisp-quintus-thejas32.elf > mecrisp-quintus-thejas32.list
	$(ARMGNU)-objcopy mecrisp-quintus-thejas32.elf mecrisp-quintus-thejas32.bin -O binary

clean:
	rm -f *.bin
	rm -f *.o
	rm -f *.elf
	rm -f *.list
