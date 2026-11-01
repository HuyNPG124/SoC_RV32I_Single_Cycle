// =========================================================
// Module TangNano20K_CORE
// + Module Top: Káº¿t ná»‘i CORE vá»›i kit Tang Nano 20K
// + Clock 27 MHz tá»« tháº¡ch anh, Ä‘Æ°a tháº³ng vÃ o core (khÃ´ng dÃ¹ng PLL)
// + UART qua máº¡ch USB-UART cÃ³ sáºµn trÃªn board
// + Ä?á»“ng bá»™ reset vá»? clock cá»§a core
// =========================================================

module TangNano20K_CORE (
    input clk,              // 27 MHz
    input rst,              // Nút S1 (chân 88), nh?n = 1

    // UART (m?ch USB-UART trên board)
    input uart_rx,
    output uart_tx,
    
    // Giao ti?p I2S (t? Testbench ho?c I2S Controller th?t)
    input  [31:0] i2s_status_in,
    input  [31:0] i2s_data_rx_in,
    
    // Giao ti?p DSP
    output [31:0] dsp_wr_data,
    output        dsp_pitch_we,
    output        dsp_nlms_we,
    
    // LED trên board sáng (m?c 0) khi CPU ?ang ch?y
    output led_run          
);

    localparam CLK_FREQ = 27_000_000;       // Ph?i kh?p v?i clock th?t vào CORE

    // =====================================
    // Reset Synchronizer
    // =====================================
    wire reset_req = rst;
    reg [1:0] reset_sync;

    always @(posedge clk or posedge reset_req) begin
        if (reset_req) begin
            reset_sync <= 2'b11;
        end
        else begin
            reset_sync <= {reset_sync[0], 1'b0};
        end
    end
    wire reset = reset_sync[1];

    // =====================================
    // Kh?i t?o CORE (CPU RV32I ??n chu k?)
    // =====================================
    CORE #(
        .CLK_FREQ   (CLK_FREQ)
    ) CORE_uut (
        .clk        (clk),
        .reset      (reset),
        
        // GPIO C? (B? qua)
        .SW         (8'b0),
        .KEY        (2'b11),
        .LEDR       (),
        .uart_rx    (uart_rx),
        .uart_tx    (uart_tx),
        .HEX0       (),
        .HEX1       (),
        .HEX2       (),
        .HEX3       (),
        .HEX4       (),
        .HEX5       (),
        
        // C?ng giao ti?p DSP (Output)
        .dsp_wr_data  (dsp_wr_data),
        .dsp_pitch_we (dsp_pitch_we),
        .dsp_nlms_we  (dsp_nlms_we),
        
        // C?ng giao ti?p I2S (Input)
        .i2s_status_in (i2s_status_in),
        .i2s_data_rx_in(i2s_data_rx_in)
    );
    
    assign led_run = reset;     // reset = 0 --> chân xu?ng 0 --> LED sáng

endmodule
