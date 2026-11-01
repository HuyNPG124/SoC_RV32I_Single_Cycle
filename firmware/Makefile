ifeq ($(OS),Windows_NT)
RISCV_TOOLCHAIN_DIR ?=
else
RISCV_TOOLCHAIN_DIR ?= /opt/riscv32im/bin
endif
RISCV_PREFIX ?= riscv32-unknown-elf

ifeq ($(OS),Windows_NT)
EXE = .exe
PYTHON ?= python
else
EXE =
PYTHON ?= python3
endif

TOOLCHAIN_BIN = $(if $(RISCV_TOOLCHAIN_DIR),$(RISCV_TOOLCHAIN_DIR)/,)
GCC = $(TOOLCHAIN_BIN)$(RISCV_PREFIX)-gcc$(EXE)
OBJ_DUMP = $(TOOLCHAIN_BIN)$(RISCV_PREFIX)-objdump$(EXE)
OBJ_COPY = $(TOOLCHAIN_BIN)$(RISCV_PREFIX)-objcopy$(EXE)
C_SRC_DIR =	.
ASM_SRC_DIR = .
LDS_SRC_DIR = . 
RESULT_DIR = .
MEM_SIZE = 1024

# Quartus (quartus/) nạp trực tiếp firmware/firmware.hex vào ROM lệnh và RAM
.PHONY: all clean

all: $(RESULT_DIR)/firmware.hex $(RESULT_DIR)/dumpfile

$(RESULT_DIR)/firmware.hex: $(RESULT_DIR)/firmware.bin makehex.py
	$(PYTHON) makehex.py $< $(MEM_SIZE) > $@

$(RESULT_DIR)/firmware.bin: $(C_SRC_DIR)/firmware.elf
	$(OBJ_COPY) -O binary $< $@

$(RESULT_DIR)/dumpfile: $(C_SRC_DIR)/firmware.elf
	$(OBJ_DUMP) -d $^ > $@

$(C_SRC_DIR)/firmware.elf: $(C_SRC_DIR)/main.o $(ASM_SRC_DIR)/start.o sections.lds
	$(GCC) -Og -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -o $@ -Wl,--build-id=none,-Bstatic,-T,sections.lds,-Map,$(RESULT_DIR)/firmware.map,--strip-debug $(ASM_SRC_DIR)/start.o $(C_SRC_DIR)/main.o -lgcc

$(C_SRC_DIR)/main.o: $(ASM_SRC_DIR)/main.c
	$(GCC) -c -mabi=ilp32 -march=rv32i -Og --std=c99 -ffreestanding -nostdlib -o $@ $<

$(ASM_SRC_DIR)/start.o: $(ASM_SRC_DIR)/start.S
	$(GCC) -c -mabi=ilp32 -march=rv32i -o $@ $<

clean:
	$(PYTHON) -c "from pathlib import Path; [p.unlink() for pattern in ('*.o', 'dumpfile', '*.elf', '*.hex', '*.bin', '*.map') for p in Path('.').glob(pattern) if p.is_file()]"
