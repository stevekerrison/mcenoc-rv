CC=riscv32-unknown-elf-gcc
OC=riscv32-unknown-elf-objcopy
OCFLAGS=-O binary
MCOE=makecoe.py
CFLAGS=-march=RV32IMCXcustom -m32 -Wall -std=c11 -Os -flto
LFLAGS=-ffreestanding -nostdlib -static -Wl,-T,boot-rom.lds,-Map,boot-rom.map

.DEFAULT_GOAL := all

OBJS = crt0.o uart.o bootloader.o main.o isr.o

boot-rom: $(OBJS) boot-rom.lds
	$(CC) -o $@ $(CFLAGS) $(LFLAGS) $(OBJS)

boot-rom.bin: boot-rom
	$(OC) $(OCFLAGS) $< $@

boot-rom.coe: boot-rom.bin $(MCOE)
	./$(MCOE) $< $@ || rm $@

crt0.o: crt0.S irq-ops.S uart-ops.S boot-rom.lds isr.c
	$(CC) -c -o $@ $< $(CFLAGS)

%.o: %.c crt0.o boot-rom.lds irq-ops.h uart-ops.h uart.h bootloader.h isr.h
	$(CC) -c -o $@ $< $(CFLAGS)

.PHONY: clean
clean:
	rm -f *.o boot-rom boot-rom.bin boot-rom.coe *.map

.PHONY: all
all: boot-rom.coe
