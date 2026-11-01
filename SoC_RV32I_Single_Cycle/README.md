# soc_rv32i_single_cycle: RV32I single-cycle SoC trên DE10-Lite

CPU RISC-V RV32I chạy tuần tự (đơn chu kỳ, không pipeline), viết bằng Verilog, chạy trên kit **Terasic DE10-Lite** (MAX 10 `10M50DAF484C7G`). Core có UART 115200 baud để giao tiếp với máy tính qua mạch USB–UART CP2102, cùng LED, công tắc, nút nhấn và 6 LED 7 đoạn.

| Thông số | Giá trị |
|---|---|
| Tập lệnh | RV32I (không có M, không có CSR / ngắt) |
| Clock core | 25 MHz (PLL từ clock 50 MHz của kit) |
| Số chu kỳ / lệnh | 1 chu kỳ, riêng lệnh LOAD (`lw`, `lb`, `lh`, …) mất 2 chu kỳ |
| Bộ nhớ lệnh | 4 KB ROM (M9K), nạp từ `firmware/firmware.hex` |
| Bộ nhớ dữ liệu | 4 KB RAM (M9K), cũng nạp từ `firmware/firmware.hex` |
| Ngoại vi | 8 LED, 8 SW, KEY1, 6 LED 7 đoạn, UART 115200 8N1 (FIFO 32 byte) |
| Tài nguyên | ~3.400 LE (7%), 1 PLL, 10 khối M9K |

## Mục lục

1. [Tổng quan project](#1-tổng-quan-project)
2. [Chuẩn bị phần cứng](#2-chuẩn-bị-phần-cứng)
3. [Cách nối mạch](#3-cách-nối-mạch)
4. [Cài đặt công cụ](#4-cài-đặt-công-cụ)
5. [Build firmware](#5-build-firmware)
6. [Viết firmware](#6-viết-firmware)
7. [Chạy project trên kit](#7-chạy-project-trên-kit)
8. [Mô phỏng (`tb/`)](#8-mô-phỏng-tb)
9. [Công cụ hỗ trợ (`tools/`)](#9-công-cụ-hỗ-trợ-tools)
10. [Xử lý sự cố](#10-xử-lý-sự-cố)
11. [Ghi chú thêm](#11-ghi-chú-thêm)

---

## 1. Tổng quan project

### Sơ đồ khối

```
              CLOCK_50 (50 MHz)
                    │
               ┌────▼─────┐
               │ Clock_PLL│ 25 MHz
               └────┬─────┘
 ┌──────────────────▼───────────────────────────────────────────────┐
 │ CORE                                                             │
 │  PC ─► Instr_Memory ─► Decode/Control ─► Regfile ─► ALU          │
 │  ▲      (ROM 4 KB)                                   │           │
 │  └──── PC_Logic ◄── Branch                           ▼ địa chỉ   │
 │                                   ┌──────────────────┴────────┐  │
 │                                   │ Load_Store_Unit           │  │
 │                                   ├─► Data_RAM (4 KB)         │  │
 │                                   ├─► GPIO ──────────────────────┼─► LEDR, SW
 │                                   ├─► Hex7_Seg ──────────────────┼─► HEX0..HEX5
 │                                   └─► UART (FIFO + TX/RX) ───────┼─► GPIO0 / GPIO1
 └──────────────────────────────────────────────────────────────────┘
```

### Cấu trúc thư mục

```
.
├── README.md
├── rtl/                          Mã nguồn phần cứng (Verilog)
│   ├── top/                      DE10_CORE.v (top-level, nối chân kit), Clock_PLL.v
│   ├── core/                     CORE.v (CPU + bản đồ địa chỉ), Program_Counter, PC_Logic,
│   │                             Decode, Control, ImmGen, Regfile, ALU, ALU_Control,
│   │                             Branch, Load_Store_Unit, mux2to1
│   ├── memory/                   Instr_Memory.v, Data_RAM.v
│   ├── peripherals/
│   │   ├── gpio/                 GPIO.v
│   │   ├── seg7/                 Hex7_Seg.v, Seg7_Decoder.v
│   │   ├── uart/                 UART.v, Baud_Gen.v, UART_Tx.v, UART_Rx.v, FIFO.v
│   │   │   └── demo/             Các top-level thử UART riêng (bản cũ)
│   │   ├── vga/                  Bộ điều khiển VGA (chưa nối vào CORE)
│   │   └── debounce/             Chống dội phím (chưa nối vào CORE)
│   └── ip/vga_ram/               IP RAM 2 cổng sinh bằng Quartus (cho VGA)
├── tb/                           Testbench, chia thư mục giống rtl/
│   ├── core/
│   ├── memory/
│   └── peripherals/{uart, uart/demo, vga}/
├── firmware/                     Firmware: start.S, main.c, sections.lds, Makefile, makehex.py
│   └── firmware.hex              Kết quả build, được nạp vào ROM lệnh và RAM
├── quartus/                      Project Quartus
│   ├── soc_rv32i_single_cycle.qpf
│   ├── soc_rv32i_single_cycle.qsf    (top-level: DE10_CORE, gán chân, danh sách file)
│   ├── soc_rv32i_single_cycle.sdc    (ràng buộc timing)
│   └── output_files/             .sof / .pof (sinh ra khi compile)
└── tools/
    ├── hex2mif/                  hex2mif.py: đổi .hex sang .mif
    ├── debug/                    decode.py: dịch file .hex ra lệnh assembly
    └── font/                     convert.py: tạo font cho VGA
```

Trong `rtl/memory/Instr_Memory.v` và `rtl/memory/Data_RAM.v`, firmware được nạp bằng `$readmemh("../firmware/firmware.hex", …)`. Đường dẫn này tính từ thư mục `quartus/`, nên Quartus đọc thẳng file do `make` tạo ra.

### Vai trò các module trong `rtl/`

Cột "SoC" cho biết module có nằm trong thiết kế nạp lên kit (dưới top-level `DE10_CORE`) hay không. Các module "chưa dùng" vẫn được liệt kê trong project Quartus, nhưng không được tổng hợp vì không nằm dưới top-level.

| Thư mục | File | Vai trò | SoC |
|---|---|---|---|
| `top/` | `DE10_CORE.v` | Top-level: nối chân kit, đồng bộ reset/SW/KEY | ✔ |
| | `Clock_PLL.v` | PLL 50 MHz → 25 MHz (`altpll`) | ✔ |
| `core/` | `CORE.v` | Ghép CPU với bộ nhớ và ngoại vi; giải mã địa chỉ; stall 1 chu kỳ cho lệnh load | ✔ |
| | `Program_Counter.v` | Thanh ghi PC (có tín hiệu stall) | ✔ |
| | `PC_Logic.v` | Chọn PC kế tiếp: PC+4, nhánh/JAL, JALR | ✔ |
| | `Decode.v` | Tách `opcode`/`funct3`/`funct7`, phân loại lệnh | ✔ |
| | `Control.v` | Sinh tín hiệu điều khiển (`Asel`, `Bsel`, `RegWEn`, `MemRead/Write`, `WBsel`, `PCSel`, `BrUn`, `ImmSel`) | ✔ |
| | `ImmGen.v` | Tạo immediate kiểu I/S/B/J/U | ✔ |
| | `Regfile.v` | 32 thanh ghi `x0`–`x31` | ✔ |
| | `ALU_Control.v`, `ALU.v` | Chọn và thực hiện phép toán | ✔ |
| | `Branch.v` | So sánh cho lệnh nhánh (`BrEq`, `BrLt`) | ✔ |
| | `Load_Store_Unit.v` | Căn byte cho `sb/sh/sw`, mở rộng dấu cho `lb/lh/lbu/lhu` | ✔ |
| | `mux2to1.v` | Mux 2:1 32-bit | chưa dùng |
| `memory/` | `Instr_Memory.v` | ROM lệnh 4 KB (M9K, đọc đồng bộ) | ✔ |
| | `Data_RAM.v` | RAM dữ liệu 4 KB, 4 bank 8-bit (M9K) | ✔ |
| `peripherals/gpio/` | `GPIO.v` | Ghi LEDR, đọc SW | ✔ |
| `peripherals/seg7/` | `Hex7_Seg.v`, `Seg7_Decoder.v` | Thanh ghi và giải mã 6 LED 7 đoạn | ✔ |
| `peripherals/uart/` | `UART.v`, `Baud_Gen.v`, `UART_Tx.v`, `UART_Rx.v`, `FIFO.v` | UART 115200 8N1, FIFO 32 byte mỗi chiều | ✔ |
| `peripherals/uart/demo/` | `DE10_UART_TX_TOP.v`, `DE10_UART_RX_FIFO_DEMO.v`, `UART_DE10_TOP.v`, `Tx_TOP.v`, `Rx_TOP.v`, `FPGA_Test.v` | Các top-level thử UART riêng (bản cũ) | chưa dùng |
| `peripherals/vga/` | `VGA_TOP.v`, `VGA_Control.v`, `VGA_Text.v`, `Font_ROM.v`, … | Bộ điều khiển VGA chế độ text | chưa dùng |
| `peripherals/debounce/` | `Debounce_Top.v`, … | Chống dội phím | chưa dùng |
| `ip/vga_ram/` | `vga_ram.qip`, `vga_ram.v` | IP RAM 2 cổng sinh bằng Quartus (không có trong project) | chưa dùng |

---

## 2. Chuẩn bị phần cứng

- Kit **DE10-Lite** và cáp USB đi kèm (cáp này vừa cấp nguồn vừa nạp FPGA qua USB-Blaster).
- Mạch **USB–UART CP2102** (mức logic 3.3 V) và cáp USB của nó.
- 3 dây cái–cái (dupont).
- Máy tính Windows 10/11.

---

## 3. Cách nối mạch

UART của core dùng 2 chân đầu tiên của header GPIO (JP1, 2×20 chân) trên DE10-Lite:

| Tín hiệu trong project | Chân FPGA | Header JP1 | Vai trò |
|---|---|---|---|
| `GPIO0` | `PIN_V10` | chân 1 (GPIO_0) | **RX** của core (kit nhận) |
| `GPIO1` | `PIN_W10` | chân 2 (GPIO_1) | **TX** của core (kit gửi) |
| GND | – | chân 12 hoặc 30 | Mass chung |

Nối với CP2102 theo kiểu **bắt chéo TX ↔ RX**:

```
   CP2102                         DE10-Lite (header JP1)
 ┌────────┐                     ┌──────────────────────────┐
 │  TXD   │────────────────────►│ chân 1  GPIO_0 (V10) RX  │
 │  RXD   │◄────────────────────│ chân 2  GPIO_1 (W10) TX  │
 │  GND   │─────────────────────│ chân 12 GND              │
 │  3V3   │  (không nối)        │                          │
 │  5V    │  (không nối)        │                          │
 └────────┘                     └──────────────────────────┘
```

Lưu ý:

- **Không** nối chân 3V3/5V của CP2102 vào kit. Kit lấy nguồn từ cáp USB của nó.
- Chỉ dùng mạch USB–UART **mức 3.3 V**. Chân I/O của MAX 10 không chịu được mức 5 V.
- Đối chiếu số chân với hình header JP1 trong *DE10-Lite User Manual* (chân 1 nằm ở góc có đánh dấu trên PCB).

Các nút và công tắc trên kit được dùng như sau:

| Phần tử | Chức năng |
|---|---|
| `KEY0` | Reset CPU (nhấn = reset) |
| `KEY1` | Đọc được từ firmware (demo dùng để xoá bộ đếm) |
| `SW[7:0]` | Đọc được từ firmware |
| `LEDR[7:0]` | Firmware ghi |
| `HEX0`–`HEX5` | Firmware ghi 6 chữ số hex |

---

## 4. Cài đặt công cụ

Phần cứng được build bằng **Quartus trên Windows**. Firmware được build bằng **toolchain RISC-V trong WSL (Ubuntu)**.

### 4.1 Quartus Prime Lite 20.1 (Windows)

1. Tải **Quartus Prime Lite Edition 20.1** từ trang Intel FPGA. Chọn gói gồm *Quartus Prime* và *MAX 10 FPGA device support*. ModelSim là tuỳ chọn.
2. Cài vào thư mục mặc định `C:\intelFPGA_lite\20.1`.
3. Cài driver USB-Blaster:
   - Cắm kit vào máy tính qua cáp USB.
   - Mở *Device Manager*. Thiết bị **USB-Blaster** sẽ hiện ở mục *Other devices* (có dấu chấm than).
   - Chuột phải chọn *Update driver* → *Browse my computer* → trỏ tới `C:\intelFPGA_lite\20.1\quartus\drivers` → *Next*.

### 4.2 WSL và toolchain RISC-V

**Bước 1: cài WSL (Ubuntu).** Mở PowerShell bằng quyền Administrator:

```powershell
wsl --install -d Ubuntu
```

Khởi động lại máy, mở *Ubuntu* và tạo user. Ổ đĩa Windows nằm trong WSL dưới dạng `/mnt/c`, `/mnt/d`, …

**Bước 2: cài các gói cần thiết** (trong Ubuntu):

```bash
sudo apt update
sudo apt install -y git make python3 autoconf automake autotools-dev curl \
    libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo \
    gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build cmake \
    libglib2.0-dev libslirp-dev
```

**Bước 3: build toolchain `riscv32-unknown-elf`.** Bước này mất khoảng 30–90 phút và cần vài GB dung lượng.

```bash
git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv32i --with-arch=rv32i --with-abi=ilp32
sudo make -j$(nproc)
```

> **Vì sao chọn `--with-arch=rv32i`:** core không có lệnh nhân/chia phần cứng. Khi build toolchain với `rv32i`, thư viện `libgcc` đi kèm cũng chỉ dùng lệnh RV32I. Nếu build với `rv32im`, các hàm float/double và phép nhân/chia 64-bit trong `libgcc` sẽ chứa lệnh `mul`/`div` mà core không chạy được (xem [mục 6.5](#65-giới-hạn-cần-nhớ)).

**Bước 4: kiểm tra.**

```bash
/opt/riscv32i/bin/riscv32-unknown-elf-gcc --version
```

**Bước 5: trỏ Makefile tới toolchain.** Dòng đầu của `firmware/Makefile` chỉ đường dẫn toolchain:

```make
RISCV_TOOLCHAIN_DIR = /opt/riscv32im/bin
```

Sửa dòng này thành thư mục `bin` của toolchain bạn vừa cài (ví dụ `/opt/riscv32i/bin`). Cách khác là truyền đường dẫn khi gọi make: `make RISCV_TOOLCHAIN_DIR=/opt/riscv32i/bin`.

---

## 5. Build firmware

Trong WSL:

```bash
cd "/mnt/d/1 - FPGA/5 - RISCV/3 - UART/firmware"    # đổi theo vị trí project của bạn
make
```

Lệnh `make` thực hiện các bước sau:

1. Biên dịch `start.S` và `main.c` (`-march=rv32i -mabi=ilp32 -Og`).
2. Link theo `sections.lds` thành `firmware.elf`, bắt đầu tại địa chỉ `0x0`.
3. Chuyển thành `firmware.bin`, rồi `makehex.py` tạo `firmware.hex` (1024 dòng, mỗi dòng 1 word 32-bit).
4. Tạo `dumpfile` (mã assembly để kiểm tra).

Quartus đọc trực tiếp `firmware/firmware.hex`, không cần copy đi đâu.

Kiểm tra kết quả:

```bash
/opt/riscv32i/bin/riscv32-unknown-elf-size firmware.elf    # kích thước text/data/bss
grep -E '\s(mul|mulh|mulhu|mulhsu|div|divu|rem|remu)\s' dumpfile   # phải KHÔNG in ra gì
```

Xoá file build: `make clean`.

> Firmware được đóng gói **bên trong file `.sof`**. Mỗi lần sửa firmware phải chạy lại `make`, **compile lại Quartus** và nạp lại kit ([mục 7](#7-chạy-project-trên-kit)).

---

## 6. Viết firmware

### 6.1 Quá trình khởi động

1. Sau reset (bật nguồn, nạp `.sof` hoặc nhấn `KEY0`), PC = `0x0000_0000`.
2. `start.S` (section `.text.start`, luôn nằm ở địa chỉ 0) đặt `sp = _stack_top = 0x1000` rồi gọi `main()`.
3. `main()` không nên return. Nếu có, CPU đứng yên trong vòng lặp ở `start.S`.

### 6.2 Bản đồ bộ nhớ

| Địa chỉ | Vùng | Ghi chú |
|---|---|---|
| `0x0000_0000` – `0x0000_0FFF` | Bộ nhớ chương trình 4 KB | Code, `.rodata`, `.data`, `.bss` và stack (stack mọc xuống từ `0x1000`) |
| `0x1000_0000` – `0x1000_0020` | Thanh ghi ngoại vi | Xem [6.3](#63-thanh-ghi-ngoại-vi) |

Bộ nhớ lệnh (ROM) và RAM dữ liệu là 2 khối riêng nhưng **cùng nội dung ban đầu** (`firmware.hex`). Nhờ vậy chuỗi hằng và biến toàn cục có giá trị khởi tạo đọc được bình thường. Lệnh ghi chỉ thay đổi RAM, không thay đổi code.

### 6.3 Thanh ghi ngoại vi

Mọi thanh ghi rộng 32 bit. Truy cập bằng con trỏ `volatile uint32_t` đúng địa chỉ trong bảng.

| Địa chỉ | Tên | R/W | Mô tả |
|---|---|---|---|
| `0x1000_0000` | `LEDS` | R/W | Bit `[7:0]` → `LEDR[7:0]`. Đọc lại được giá trị đã ghi |
| `0x1000_0004` | `GPIO_IN` | R | Bit `[7:0]` = `SW[7:0]` |
| `0x1000_0008` | `HEX` | W | Bit `[23:0]` = 6 chữ số hex: `[3:0]`→`HEX0`, `[7:4]`→`HEX1`, …, `[23:20]`→`HEX5` |
| `0x1000_000C` | `SWITCHES` | R | Bit `[7:0]` = `SW[7:0]` (giống `GPIO_IN`) |
| `0x1000_0010` | `UART_TX` | W | Ghi 1 byte để gửi. **Byte bị bỏ** nếu FIFO TX đầy |
| `0x1000_0014` | `UART_RX` | R | Đọc 1 byte đã nhận, đồng thời **lấy byte đó ra khỏi FIFO** |
| `0x1000_0018` | `UART_STATUS` | R | Bit 0 = `rx_empty` (1: chưa có byte), bit 1 = `tx_full` (1: FIFO TX đầy) |
| `0x1000_0020` | `KEYS` | R | Bit `[1:0]` = `KEY[1:0]`, **nhấn = 0**. `KEY0` là nút reset nên firmware thực tế chỉ dùng được `KEY1` |

UART chạy ở 115200 baud, 8 bit dữ liệu, không parity, 1 stop bit. Mỗi chiều TX/RX có FIFO 32 byte. Khi FIFO RX đầy, byte nhận thêm bị bỏ.

### 6.4 Code mẫu

Định nghĩa thanh ghi (copy vào đầu file `.c`):

```c
#include <stdint.h>

#define REG32(addr)     (*(volatile uint32_t *)(addr))

#define LEDS            REG32(0x10000000)
#define HEX             REG32(0x10000008)
#define SWITCHES        REG32(0x1000000C)
#define UART_TX         REG32(0x10000010)
#define UART_RX         REG32(0x10000014)
#define UART_STATUS     REG32(0x10000018)
#define KEYS            REG32(0x10000020)

#define UART_RX_EMPTY   0x1
#define UART_TX_FULL    0x2
```

Gửi và nhận UART:

```c
static void uart_putc(char c)
{
    while (UART_STATUS & UART_TX_FULL);     // chờ FIFO TX còn chỗ
    UART_TX = (uint8_t)c;
}

static void uart_puts(const char *str)
{
    while (*str)
        uart_putc(*str++);
}

// Trả về -1 nếu chưa nhận được byte nào
static int uart_getc(void)
{
    if (UART_STATUS & UART_RX_EMPTY)
        return -1;
    return UART_RX & 0xFF;                  // đọc = lấy byte ra khỏi FIFO
}
```

Hàm delay. Vòng lặp trong mất 9 chu kỳ = 360 ns ở 25 MHz, nên 1 ms ≈ 2778 vòng. Con số này đo theo mã do GCC sinh ra với `-Og`; đổi mức tối ưu hoặc cách viết vòng lặp thì phải tính lại (xem `dumpfile`).

```c
#define LOOPS_PER_MS    2778

static void delay_ms(uint32_t ms)
{
    while (ms--)
        for (volatile uint32_t i = 0; i < LOOPS_PER_MS; i++);
}
```

Không nên viết `i < ms * LOOPS_PER_MS`: GCC sẽ tính lại phép nhân ở mỗi vòng, làm thời gian sai lệch.

Chương trình ví dụ: LED chạy theo công tắc, HEX hiện bộ đếm, `KEY1` xoá bộ đếm:

```c
int main(void)
{
    uint32_t count = 0;

    uart_puts("Hello from RV32I!\r\n");

    while (1) {
        LEDS = SWITCHES;

        if (!(KEYS & 0x2))          // KEY1 đang được nhấn
            count = 0;

        HEX = count & 0xFFFFFF;     // hiển thị dạng hex
        count++;
        delay_ms(100);
    }
}
```

`firmware/main.c` là ví dụ đầy đủ hơn: in lời chào, tự kiểm tra các lệnh load/store byte/half, echo ký tự nhận được, hiển thị ký tự cuối và bộ đếm trên HEX.

### 6.5 Giới hạn cần nhớ

1. **Chỉ có RV32I.**
   - Phép `*`, `/`, `%` trên số 32-bit vẫn dùng được: GCC gọi hàm phần mềm trong `libgcc` (chậm hơn nhưng đúng).
   - Nếu toolchain được build với `rv32im` (như `/opt/riscv32im`), **tránh `float`/`double`, phép nhân/chia `long long` và `__builtin_popcount`**. Các hàm này trong `libgcc` chứa lệnh `mul`/`div`, và core sẽ chạy sai **mà không báo lỗi**.
   - Luôn kiểm tra `dumpfile` bằng lệnh `grep` ở [mục 5](#5-build-firmware).
2. **Không có thư viện C chuẩn** (`-nostdlib`): không có `printf`, `malloc`, `strlen`, …
   - GCC đôi khi tự gọi `memset`/`memcpy` (ví dụ khi khởi tạo mảng lớn hoặc copy struct). Khi đó lúc link sẽ báo `undefined reference to memset`. Cách sửa là tự viết hàm:
     ```c
     void *memset(void *dst, int c, unsigned n)
     { unsigned char *p = dst; while (n--) *p++ = (unsigned char)c; return dst; }

     void *memcpy(void *dst, const void *src, unsigned n)
     { unsigned char *d = dst; const unsigned char *s = src; while (n--) *d++ = *s++; return dst; }
     ```
3. **Tổng dung lượng 4 KB** gồm code + `.rodata` + `.data` + `.bss` + **stack**.
   - Kiểm tra bằng `riscv32-unknown-elf-size firmware.elf`, nên để `text + data + bss` dưới khoảng 3 KB để còn chỗ cho stack.
   - Không có cơ chế báo tràn stack.
   - `makehex.py` báo `AssertionError` nếu file `.bin` ≥ 4 KB.
4. **Dùng `volatile`** cho mọi truy cập ngoại vi, nếu không compiler có thể tối ưu mất lệnh đọc/ghi.
5. **Truy cập phải căn lề**: `lw`/`sw` tại địa chỉ chia hết cho 4, `lh`/`sh` tại địa chỉ chẵn. Truy cập lệch không gây lỗi nhưng cho kết quả sai. Cẩn thận khi ép kiểu con trỏ `uint8_t*` sang `uint32_t*` hoặc dùng `struct` packed.
6. **Không có ngắt, CSR, `ecall`/`ebreak`**. Các lệnh này bị bỏ qua như NOP. Muốn chờ sự kiện thì dùng polling (vòng lặp đọc thanh ghi trạng thái).
7. **Nhấn `KEY0` chỉ reset CPU, không nạp lại RAM.** Biến toàn cục giữ giá trị cũ sau reset. Hãy gán giá trị đầu cho biến trạng thái ngay trong `main()`.
8. **Thời gian lệnh:** 1 lệnh = 40 ns, riêng lệnh load = 80 ns.

### 6.6 Thêm file `.c` mới

Ví dụ muốn tách code UART ra `uart.c`, sửa `firmware/Makefile` như sau:

```make
# Thêm uart.o vào danh sách phụ thuộc và lệnh link của firmware.elf
$(C_SRC_DIR)/firmware.elf: $(C_SRC_DIR)/main.o $(C_SRC_DIR)/uart.o $(ASM_SRC_DIR)/start.o sections.lds
	$(GCC) -Og -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -o $@ -Wl,--build-id=none,-Bstatic,-T,sections.lds,-Map,$(RESULT_DIR)/firmware.map,--strip-debug $(ASM_SRC_DIR)/start.o $(C_SRC_DIR)/main.o $(C_SRC_DIR)/uart.o -lgcc

# Thêm rule biên dịch uart.c
$(C_SRC_DIR)/uart.o: $(C_SRC_DIR)/uart.c
	$(GCC) -c -mabi=ilp32 -march=rv32i -Og --std=c99 -ffreestanding -nostdlib -o $@ $<
```

Dòng lệnh dưới mỗi rule phải bắt đầu bằng **phím Tab**, không dùng dấu cách.

---

## 7. Chạy project trên kit

### Bước 1: Nối mạch

Nối CP2102 với kit theo [mục 3](#3-cách-nối-mạch). Cắm cáp USB của kit và của CP2102 vào máy tính.

### Bước 2: Build firmware

```bash
cd "/mnt/d/1 - FPGA/5 - RISCV/3 - UART/firmware"
make
```

Kiểm tra `firmware/firmware.hex` vừa được cập nhật (xem thời gian sửa file).

### Bước 3: Compile project trong Quartus

1. Mở Quartus → *File → Open Project* → chọn `quartus/soc_rv32i_single_cycle.qpf`.
2. Kiểm tra *Assignments → Settings → General*: top-level entity là `DE10_CORE`.
3. Chọn *Processing → Start Compilation* (`Ctrl+L`). Thời gian khoảng 2–3 phút.
4. Khi xong, cửa sổ *Messages* báo `Full Compilation was successful`.
5. Trong *Compilation Report → Timing Analyzer*, không có mục nào màu đỏ (slack dương ở clock `PLL_uut|…|clk[0]`).
6. File kết quả: `quartus/output_files/soc_rv32i_single_cycle.sof` (nạp tạm) và `quartus/output_files/soc_rv32i_single_cycle.pof` (nạp vào flash).

> Nếu sửa file `.qsf` bằng trình soạn thảo bên ngoài, hãy **đóng project trong Quartus trước** rồi mở lại. Nếu không, Quartus có thể ghi đè thay đổi.

### Bước 4: Nạp vào kit

1. Chọn *Tools → Programmer*.
2. *Hardware Setup…* → chọn **USB-Blaster [USB-0]** → *Close*.
3. *Mode*: **JTAG**.
4. Nếu danh sách chưa có file: *Add File…* → `quartus/output_files/soc_rv32i_single_cycle.sof`. Tick cột **Program/Configure**.
5. Bấm **Start**. Thanh *Progress* hiện `100% (Successful)`.

Thiết kế nạp bằng `.sof` **mất khi tắt nguồn**. Muốn kit tự chạy mỗi lần cấp điện:

- Trong Programmer, *Add File…* chọn `quartus/output_files/soc_rv32i_single_cycle.pof`.
- Tick **Program/Configure** ở dòng file `.pof`, rồi bấm **Start**.
- Nạp lâu hơn `.sof`. Sau đó rút/cắm lại nguồn, kit chạy ngay.

### Bước 5: Mở terminal UART

1. Mở *Device Manager → Ports (COM & LPT)* để xem số cổng của CP2102, ví dụ *Silicon Labs CP210x … (COM5)*. Nếu chưa có, cài driver *CP210x USB to UART Bridge VCP* của Silicon Labs.
2. Mở terminal (PuTTY, Tera Term, Arduino Serial Monitor, …) và đặt:

   | Thông số | Giá trị |
   |---|---|
   | Cổng | COM của CP2102 |
   | Baud rate | **115200** |
   | Data bits | 8 |
   | Parity | None |
   | Stop bits | 1 |
   | Flow control | **None** |

   Với PuTTY: *Session → Connection type: Serial*, nhập COM và Speed `115200`. Vào *Connection → Serial* đặt *Flow control: None* → *Open*.

### Bước 6: Kiểm tra hoạt động (firmware demo)

Nhấn `KEY0` để reset. Terminal hiện:

```
RV32I single-cycle core - DE10-Lite
Self-test: OK
Type anything, it will be echoed back.
```

| Thao tác | Kết quả mong đợi |
|---|---|
| Gõ ký tự trên terminal | Ký tự được gửi lại (echo). Enter xuống dòng |
| Gạt `SW[7:0]` | `LEDR[7:0]` sáng theo công tắc |
| Nhìn `HEX5`–`HEX4` | Mã ASCII (hex) của ký tự gõ gần nhất, ví dụ gõ `A` → `41` |
| Nhìn `HEX3`–`HEX0` | Bộ đếm tăng liên tục (hex) |
| Nhấn `KEY1` | Bộ đếm về `0000` |
| Nhấn `KEY0` | Reset, lời chào in lại |

Nếu terminal báo `Self-test: FAIL 0x000000XX`, mỗi bit tương ứng một phép kiểm tra bị sai:

| Bit | Kiểm tra |
|---|---|
| `0x01` | `lbu` |
| `0x02` | `lhu` |
| `0x04` | `sb` |
| `0x08` | `lb` |
| `0x10` | `sh` |
| `0x20` | `lh` |
| `0x40` | Biến `.data` (RAM chưa được nạp firmware) |

### Quy trình khi sửa firmware

```
sửa firmware/*.c  →  make (WSL)  →  Ctrl+L (Quartus)  →  Programmer → Start
```

---

## 8. Mô phỏng (`tb/`)

Thư mục `tb/` chứa testbench, chia thư mục con giống `rtl/`. Cách đơn giản nhất là mô phỏng bằng **Icarus Verilog** trong WSL.

### Cài đặt

```bash
sudo apt install -y iverilog gtkwave
```

### Chạy một testbench

Luôn chạy **từ thư mục `tb/`**. Khi đó đường dẫn `../firmware/firmware.hex` trong bộ nhớ lệnh/RAM trỏ đúng tới firmware.

```bash
cd tb
RTL=$(find ../rtl -name '*.v' -not -path '../rtl/top/*' -not -path '../rtl/ip/*')

iverilog -g2005 -o sim.vvp -s tb_UART_Tx peripherals/uart/tb_UART_Tx.v $RTL
vvp sim.vvp
```

- `-s tb_UART_Tx` là tên module testbench (trùng tên file).
- Lệnh `find` bỏ qua `rtl/top/` (PLL dùng `altpll`, chỉ có trong thư viện Quartus) và `rtl/ip/` (dùng `altsyncram`).
- Testbench dùng tới bộ nhớ (`tb_fetch`, `tb_Instr_Memory`) cần build firmware trước ([mục 5](#5-build-firmware)).

### Xem dạng sóng

Các testbench hiện chưa ghi file dạng sóng. Muốn xem bằng GTKWave, thêm vào trong module testbench:

```verilog
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_UART_Tx);       // tên module testbench
end
```

Chạy lại `vvp sim.vvp`, rồi mở bằng `gtkwave wave.vcd`.

### Trạng thái các testbench

"Chạy được" nghĩa là đã biên dịch và chạy hết bằng Icarus Verilog 12. Phần lớn testbench chỉ in giá trị ra màn hình chứ không tự báo PASS/FAIL, nên cần đọc kết quả để đánh giá.

| Testbench | Module được test | Trạng thái |
|---|---|---|
| `core/tb_ALU.v` | `ALU` | Chạy được |
| `core/tb_ALU_Control.v` | `ALU_Control` | Chạy được |
| `core/tb_Branch.v` | `Branch` | **Lỗi biên dịch**: dùng tên cổng cũ `BrLT`/`BrEQ` (module là `BrLt`/`BrEq`) |
| `core/tb_CORE_PC.v` | `CORE` | **Lỗi biên dịch**: dùng các cổng debug cũ (`tb_instruction`, `tb_addr`, …) |
| `core/tb_Decode.v` | `Decode` | Chạy được |
| `core/tb_ImmGen.v` | `ImmGen` | Chạy được |
| `core/tb_Regfile.v` | `Regfile` | Chạy được |
| `core/tb_fetch.v` | `CORE` (chạy firmware) | Chạy được |
| `memory/tb_Data_RAM.v` | `Data_RAM` | Chạy được |
| `memory/tb_Instr_Memory.v` | `Instr_Memory` | Chạy được |
| `peripherals/uart/tb_Baud_Gen.v` | `Baud_Gen` | Chạy được |
| `peripherals/uart/tb_FIFO.v` | `FIFO` | Chạy được |
| `peripherals/uart/tb_UART.v` | `UART` | Chạy được |
| `peripherals/uart/tb_UART_Rx.v` | `UART_Rx` | Chạy được |
| `peripherals/uart/tb_UART_Tx.v` | `UART_Tx` | Chạy được |
| `peripherals/uart/demo/tb_Rx_TOP.v` | `Rx_TOP` | Chạy được |
| `peripherals/uart/demo/tb_Tx_TOP.v` | `Tx_TOP` | Chạy được |
| `peripherals/vga/tb_VGA_Control.v` | `VGA_Control` | Chạy được |
| `peripherals/vga/tb_VGA_TOP.v` | `VGA_TOP` | Biên dịch được. Phải chạy `vvp` từ `rtl/peripherals/vga/` để đọc được `font8x16.hex`. Mô phỏng chạy lâu |

### Mô phỏng bằng ModelSim (qua Quartus)

Danh sách testbench đã được khai báo sẵn trong project (*Assignments → Settings → EDA Tool Settings → Simulation → Test Benches*). Chạy bằng *Tools → Run Simulation Tool → RTL Simulation*.

Khi chạy theo cách này, ModelSim làm việc trong `quartus/simulation/modelsim/`, nên **không tìm thấy** `../firmware/firmware.hex`. Với các testbench cần firmware (`tb_fetch`, `tb_Instr_Memory`), hãy dùng Icarus Verilog như trên.

---

## 9. Công cụ hỗ trợ (`tools/`)

| Thư mục | Script | Công dụng |
|---|---|---|
| `tools/debug/` | `decode.py` | Dịch file `.hex` thành bảng: địa chỉ, mã hex, mã nhị phân, lệnh assembly, chú thích và các trường lệnh. Hữu ích để kiểm tra firmware |
| `tools/hex2mif/` | `hex2mif.py` | Đổi file `.hex` (mỗi dòng 1 word) sang `.mif` của Quartus. Project hiện nạp bằng `$readmemh` nên không cần bước này; chỉ dùng khi muốn khởi tạo IP RAM/ROM bằng file `.mif` |
| `tools/font/` | `convert.py` | Đổi font 8×8 trong `font8x8_basic.h` thành `font.hex` (1024 byte) cho bộ VGA |

Cách dùng (trong WSL, đứng ở thư mục gốc project):

```bash
# Dịch firmware ra bảng lệnh
python3 tools/debug/decode.py firmware/firmware.hex tools/debug/output.txt

# Tạo file .mif 1024 word từ firmware
python3 tools/hex2mif/hex2mif.py firmware/firmware.hex tools/hex2mif/firmware.mif 1024

# Tạo font.hex (script đọc/ghi file trong thư mục hiện hành)
cd tools/font && python3 convert.py
```

---

## 10. Xử lý sự cố

| Triệu chứng | Nguyên nhân / cách xử lý |
|---|---|
| Terminal không hiện gì | Kiểm tra dây TX/RX đã bắt chéo chưa (CP2102 TXD → chân 1, RXD → chân 2), GND đã nối chung chưa. Kiểm tra đúng cổng COM, đúng 115200 8N1, flow control None. Nhấn `KEY0` để in lại lời chào |
| Terminal hiện ký tự rác | Sai baud rate, hoặc dùng mạch USB–UART mức 5 V |
| Có lời chào nhưng gõ không echo | Dây CP2102 TXD → chân 1 (GPIO_0) lỏng hoặc cắm sai |
| LED/HEX không phản hồi | Chưa nạp `.sof`, hoặc `KEY0` đang bị giữ (CPU ở trạng thái reset) |
| Sửa firmware nhưng kit vẫn chạy code cũ | Quên `make`, hoặc quên compile lại Quartus. Kiểm tra `firmware/firmware.hex` đã cập nhật |
| Tắt nguồn bật lại thì mất chương trình | Mới nạp `.sof`. Nạp `.pof` để lưu vào flash |
| `make: …riscv32-unknown-elf-gcc: No such file or directory` | Sai `RISCV_TOOLCHAIN_DIR` trong `firmware/Makefile` |
| `makehex.py` báo `AssertionError` | Firmware ≥ 4 KB, cần rút gọn chương trình |
| `undefined reference to memset` / `memcpy` | Tự viết các hàm này ([mục 6.5](#65-giới-hạn-cần-nhớ)) |
| Tính toán sai khi dùng `float`, `double`, `long long` | `libgcc` có lệnh `mul`/`div`. Kiểm tra `dumpfile` bằng `grep` ([mục 5](#5-build-firmware)), build toolchain với `rv32i` |
| Quartus báo `Error (14703): Invalid internal configuration mode` | `quartus/soc_rv32i_single_cycle.qsf` thiếu dòng `set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "SINGLE IMAGE WITH ERAM"` |
| Programmer không thấy USB-Blaster | Chưa cài driver ([mục 4.1](#41-quartus-prime-lite-201-windows)), hoặc cáp USB chỉ có dây nguồn |
| Thay đổi trong file `.qsf` bị mất | Quartus đang mở project lúc sửa file. Đóng project rồi sửa lại |

---

## 11. Ghi chú thêm

- **Đổi tần số core:**
  - Sửa `clk0_multiply_by` / `clk0_divide_by` trong `rtl/top/Clock_PLL.v`.
  - Sửa `CLK_FREQ` trong `rtl/top/DE10_CORE.v` cho khớp (UART dùng giá trị này để tính baud).
  - Ở 25 MHz timing còn dư khoảng 7 ns (Fmax ~30 MHz), nên không nên tăng quá 30 MHz.
- **Đổi baud rate:** thêm `.BAUD_RATE (…)` vào khối `UART #(…)` trong `rtl/core/CORE.v` (mặc định 115200), rồi sửa terminal cho khớp.
- **Chuẩn I/O:** các chân hiện dùng chuẩn mặc định của Quartus (2.5 V). Kit cấp 3.3 V cho header GPIO và core vẫn chạy bình thường. Nếu muốn đặt đúng chuẩn, mở *Assignments → Pin Planner* và đặt cột *I/O Standard* = `3.3-V LVTTL` cho các chân.
- **Lệnh load mất 2 chu kỳ** vì RAM M9K trả dữ liệu sau 1 cạnh clock. Core dùng tín hiệu `load_stall` để giữ PC thêm 1 chu kỳ (xem `rtl/core/CORE.v`).
- **Đường dẫn firmware khi mô phỏng:** `../firmware/firmware.hex` được tính từ thư mục hiện hành của trình mô phỏng, nên phải chạy từ `tb/` ([mục 8](#8-mô-phỏng-tb)).
