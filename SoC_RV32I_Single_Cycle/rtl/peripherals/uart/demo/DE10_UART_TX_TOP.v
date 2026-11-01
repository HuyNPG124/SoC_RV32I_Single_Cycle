//module DE10_UART_TX_TOP (
//
//    input CLOCK_50,        // Clock 50MHz
//    input [9:0] SW,        // SW[7:0]: data
//    input [1:0] KEY,       // KEY[1]: trigger gửi
//
//    output GPIO0,          // UART TX → CP2102 RX
//    output [1:0] LEDR
//);
//
//    // =========================
//    // RESET (có thể nối KEY[0] nếu muốn)
//    // =========================
//    wire reset;
//    assign reset = 1;
//
//    // =========================
//    // DEBOUNCE KEY[1]
//    // =========================
//    wire key_level;
//    wire key_pulse;
//
//    Debounce_Top btn1 (
//        .clk       (CLOCK_50),
//        .reset     (reset),
//        .key_n     (KEY[1]),   // KEY active LOW
//        .debounced (key_level),
//        .pulse     (key_pulse)
//    );
//
//    // =========================
//    // FIFO WRITE ENABLE
//    // =========================
//    //wire fifo_wr_en;
//    //assign fifo_wr_en = key_pulse;
//	 
//	 reg key_d;
//
//always @(posedge CLOCK_50) begin
//    key_d <= KEY[1];
//end
//
//wire fifo_wr_en;
//assign fifo_wr_en = (~KEY[1]) & key_d;
//
//
//    // =========================
//    // DATA INPUT
//    // =========================
//    wire [7:0] fifo_data_in;
//    assign fifo_data_in = SW[7:0];
//
//    // =========================
//    // UART TX CORE (FIFO + UART)
//    // =========================
//    wire tx_serial;
//
//    Tx_TOP #(
//        .CLK_SYS   (50_000_000),
//        .BAUD_RATE (9600),
//        .DATA_BITS (8)
//    ) tx_core (
//        .clk            (CLOCK_50),
//        .reset          (reset),
//        .fifo_data_in   (fifo_data_in),
//        .fifo_wr_en     (fifo_wr_en),
//        .tx_serial_out  (tx_serial)
//    );
//
//    // =========================
//    // OUTPUT GPIO
//    // =========================
//    assign GPIO0 = tx_serial;
//
//    // =========================
//    // DEBUG LED
//    // =========================
//    assign LEDR[0] = tx_serial;   // UART waveform
//    //assign LEDR[1] = fifo_wr_en;  // pulse khi nhấn nút
//	 assign LEDR[1] = ~KEY[1];
//
//endmodule

module DE10_UART_TX_TOP (

    input CLOCK_50,        // Clock 50MHz
    input [9:0] SW,        // SW[7:0]: data
    input [1:0] KEY,       // KEY[1]: trigger gửi

    output GPIO0           // UART TX → CP2102 RX
);

    // =========================
    // RESET (có thể nối KEY[0] nếu muốn)
    // =========================
    wire reset;
    assign reset = 0;

    // =========================
    // EDGE DETECT KEY[1]
    // (KEY active low)
    // =========================
    reg key1_d;

    always @(posedge CLOCK_50) begin
        key1_d <= KEY[1];
    end

    // tạo xung 1 clock khi nhấn nút
    wire fifo_wr_en;
    assign fifo_wr_en = (~KEY[1]) & key1_d;

    // =========================
    // DATA INPUT
    // =========================
    wire [7:0] fifo_data_in;
    assign fifo_data_in = SW[7:0];

    // =========================
    // UART TX CORE (FIFO + UART)
    // =========================
    wire tx_serial;

    Tx_TOP #(
        .CLK_SYS   (50_000_000),
        .BAUD_RATE (9600),
        .DATA_BITS (8)
    ) tx_core (
        .clk            (CLOCK_50),
        .reset          (reset),
        .fifo_data_in   (fifo_data_in),
        .fifo_wr_en     (fifo_wr_en),
        .tx_serial_out  (tx_serial)
    );

    // =========================
    // OUTPUT GPIO
    // =========================
    assign GPIO0 = tx_serial;

endmodule