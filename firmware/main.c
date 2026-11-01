#include <stdint.h>

// =========================
// PERIPHERAL MAP (khớp với CORE.v)
// =========================
#define REG32(addr)     (*(volatile uint32_t *)(addr))

#define LEDS            REG32(0x10000000)   // Ghi: LEDR[7:0]
#define HEX             REG32(0x10000008)   // Ghi: 6 chữ số hex trên HEX5..HEX0
#define SWITCHES        REG32(0x1000000C)   // Đọc: SW[7:0]
#define UART_TX         REG32(0x10000010)   // Ghi: gửi 1 byte
#define UART_RX         REG32(0x10000014)   // Đọc: nhận 1 byte
#define UART_STATUS     REG32(0x10000018)   // bit 0: rx_empty, bit 1: tx_full
#define KEYS            REG32(0x10000020)   // Đọc: KEY[1:0] (nhấn = 0)

#define UART_RX_EMPTY   0x1
#define UART_TX_FULL    0x2

#define TICKS_PER_STEP  100000              // Số vòng lặp giữa 2 lần tăng bộ đếm

// Biến trong .data: chỉ đọc đúng nếu Data_RAM được nạp firmware
volatile uint32_t init_value = 0x12345678;

// =========================
// UART
// =========================
static void uart_putc(char c)
{
    while (UART_STATUS & UART_TX_FULL);
    UART_TX = (uint8_t)c;
}

static void uart_puts(const char *str)
{
    while (*str)
        uart_putc(*str++);
}

static void uart_puthex(uint32_t value)
{
    static const char digits[] = "0123456789ABCDEF";

    for (int shift = 28; shift >= 0; shift -= 4)
        uart_putc(digits[(value >> shift) & 0xF]);
}

// Trả về -1 nếu chưa có byte nào
static int uart_getc(void)
{
    if (UART_STATUS & UART_RX_EMPTY)
        return -1;

    return UART_RX & 0xFF;
}

// =========================
// SELF TEST
// + Kiểm tra LB/LH/LBU/LHU/SB/SH và .data
// + Trả về 0 nếu đúng hết, mỗi bit = 1 lỗi
// =========================
static uint32_t self_test(void)
{
    volatile uint32_t word = 0x11223344;
    volatile uint8_t  *u8  = (volatile uint8_t *)&word;
    volatile int8_t   *s8  = (volatile int8_t *)&word;
    volatile uint16_t *u16 = (volatile uint16_t *)&word;
    volatile int16_t  *s16 = (volatile int16_t *)&word;
    uint32_t errors = 0;

    if (u8[0] != 0x44 || u8[3] != 0x11)     errors |= 0x01;   // LBU
    if (u16[1] != 0x1122)                    errors |= 0x02;   // LHU

    u8[1] = 0xAB;                                              // SB
    if (word != 0x1122AB44)                  errors |= 0x04;
    if (s8[1] != (int8_t)0xAB)               errors |= 0x08;   // LB

    u16[1] = 0x8001;                                           // SH
    if (word != 0x8001AB44)                  errors |= 0x10;
    if (s16[1] != (int16_t)0x8001)           errors |= 0x20;   // LH

    if (init_value != 0x12345678)            errors |= 0x40;   // .data

    return errors;
}

// =========================
// MAIN
// + UART 115200 8N1: in lời chào, echo lại ký tự nhận được
// + LEDR = SW
// + HEX5..HEX4: mã ASCII ký tự nhận cuối cùng
// + HEX3..HEX0: bộ đếm, nhấn KEY1 để xóa
// =========================
int main(void)
{
    uint32_t count = 0;
    uint32_t tick = 0;
    uint32_t last_char = 0;
    uint32_t errors;

    uart_puts("\r\nRV32I single-cycle core - DE10-Lite\r\n");

    errors = self_test();
    if (errors == 0) {
        uart_puts("Self-test: OK\r\n");
    } else {
        uart_puts("Self-test: FAIL 0x");
        uart_puthex(errors);
        uart_puts("\r\n");
    }

    uart_puts("Type anything, it will be echoed back.\r\n");

    while (1)
    {
        int c = uart_getc();

        if (c >= 0) {
            last_char = (uint32_t)c;
            uart_putc((char)c);

            if (c == '\r')
                uart_putc('\n');
        }

        LEDS = SWITCHES;

        if (!(KEYS & 0x2))
            count = 0;

        if (++tick >= TICKS_PER_STEP) {
            tick = 0;
            count++;
        }

        HEX = (last_char << 16) | (count & 0xFFFF);
    }

    return 0;
}
