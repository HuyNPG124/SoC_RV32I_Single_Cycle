// ======================================
// Module Rx_TOP
// + Tích hợp Baud_Gen + Rx + FIFO
// ======================================

module Rx_TOP #(
    parameter CLK_SYS     = 50_000_000,
    parameter BAUD_RATE   = 9600,
    parameter DATA_BITS   = 8,
    parameter OVERSAMPLE  = 16,
    parameter FIFO_WIDTH  = 8,
    parameter FIFO_DEPTH  = 32
)(
    input clk,
    input reset,

    input rx_serial_in,		// Tín hiệu đầu vào của Rx

    // CPU interface
    input fifo_rd_en,		// Tín hiệu yêu cầu đọc FIFO 
    output [DATA_BITS-1:0] fifo_data_out,		// Dữ liệu đầu ra
    output fifo_empty,
    output fifo_full,

    // optional
    output rx_irq
);

    // =========================
    // Baud Generator
    // =========================
    wire baud_tick;

    Baud_Gen #(
        .CLK_SYS    (CLK_SYS),
        .BAUD_RATE  (BAUD_RATE),
        .OVERSAMPLE (OVERSAMPLE)
    ) baud_gen (
        .clk       (clk),
        .reset     (reset),
        .baud_tick (baud_tick)
    );

    // =========================
    // UART RX
    // =========================
    wire [DATA_BITS-1:0] rx_data;
    wire rx_valid;

    UART_Rx #(
        .DATA_BITS  (DATA_BITS),
        .OVERSAMPLE (OVERSAMPLE)
    ) uart_rx (
        .clk        (clk),
        .reset      (reset),
        .baud_tick  (baud_tick),
        .rx         (rx_serial_in),
        .data_out   (rx_data),
        .rx_valid   (rx_valid)
    );

    // =========================
    // FIFO RX
    // =========================
    wire write_en;

    assign write_en = rx_valid && !fifo_full;

    FIFO #(
        .W (FIFO_WIDTH),
        .L (FIFO_DEPTH)
    ) rx_fifo (
        .clk       (clk),
        .reset     (reset),
        .write_en  (write_en),
        .read_en   (fifo_rd_en),
        .data_in   (rx_data),
        .data_out  (fifo_data_out),
        .empty     (fifo_empty),
        .full      (fifo_full)
    );

    // =========================
    // Interrupt (optional)
    // =========================
    assign rx_irq = !fifo_empty;		// Cờ báo trong FIFO vẫn còn dữ liệu chưa đọc 

endmodule