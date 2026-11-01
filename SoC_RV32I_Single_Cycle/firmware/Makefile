.PHONY: all clean

# Auto-detect the RISC-V GNU toolchain, supporting both Linux and Windows/MSYS2.
ifeq ($(OS),Windows_NT)
  GCC := $(firstword $(shell where.exe riscv32-unknown-elf-gcc 2>NUL))
  ifeq ($(strip $(GCC)),)
    GCC := C:/msys64/mingw64/bin/riscv32-unknown-elf-gcc.exe
  endif
else
  GCC := $(shell command -v riscv32-unknown-elf-gcc 2>/dev/null)
  ifeq ($(strip $(GCC)),)
    GCC := /opt/riscv32im/bin/riscv32-unknown-elf-gcc
  endif
endif

ifeq ($(strip $(GCC)),)
$(error RISC-V GNU toolchain not found. Install riscv32-unknown-elf-gcc or add it to PATH.)
endif

GCC := $(subst \,/, $(GCC))
GCC_DIR := $(subst \,/, $(patsubst %/,%,$(dir $(GCC))))
OBJ_DUMP := $(GCC_DIR)/riscv32-unknown-elf-objdump
OBJ_COPY := $(GCC_DIR)/riscv32-unknown-elf-objcopy
C_SRC_DIR = .
ASM_SRC_DIR = .
LDS_SRC_DIR = .
RESULT_DIR = .
MEM_SIZE = 1024

# Quartus (quartus/) nạp trực tiếp firmware/firmware.hex vào ROM lệnh và RAM
all: $(RESULT_DIR)/firmware.hex $(RESULT_DIR)/dumpfile

$(RESULT_DIR)/firmware.hex: $(RESULT_DIR)/firmware.bin makehex.py
	python3 makehex.py $< $(MEM_SIZE) > $@

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
	rm -f *.o dumpfile *.elf *.hex *.bin *.map
