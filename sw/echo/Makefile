.DEFAULT_GOAL := all

PROJ = echo

SSH?=sk5051@davv
LIBMCENOC=../libmcenoc-rv
ULOAD=$(LIBMCENOC)/mcenoc-rv-uartload.py
RLOAD?=./mcenoc-rv-uartload.py -
MCOE=$(LIBMCENOC)/makecoe.py
CC=riscv32-unknown-elf-gcc
OC=riscv32-unknown-elf-objcopy
OCFLAGS=-O binary
CFLAGS=-march=RV32IMXcustom -m32 -Wall -std=c11 -Os -flto
#LFLAGS=-nostdlib -Wl,-T,$(LIBMCENOC)/mcenoc-rv-uartload.lds,-Map,$(PROJ).map,--strip-debug
LFLAGS=-Wl,-Map,$(PROJ).map
INC=-I$(LIBMCENOC)
LIB=-L$(LIBMCENOC) -lmcenoc-rv

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(INC)

$(PROJ): $(PROJ).o libs
	$(CC) $(CFLAGS) $(LFLAGS)  $< $(LIB) -o $@

$(PROJ).bin: $(PROJ)
	$(OC) $(OCFLAGS) $< $@

remote-load: $(PROJ).bin
	cat $(PROJ).bin | ssh $(SSH) "$(RLOAD)"

load: $(PROJ).bin
	$(ULOAD) $(PROJ).bin

$(PROJ).coe: $(PROJ).bin $(MCOE)
	./$(MCOE) $< $@ || rm $@

.PHONY: libs
libs:
	$(MAKE) -C $(LIBMCENOC)

.PHONY: clean-libs
clean-libs:
	$(MAKE) -C $(LIBMCENOC) clean

.PHONY: clean-all
clean-all: clean clean-libs

.PHONY: clean
clean:
	rm -f *.o $(PROJ) $(PROJ).bin $(PROJ).map

.PHONY: all
all: $(PROJ).bin

