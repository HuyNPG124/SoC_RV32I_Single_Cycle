module UART_DE10_TOP (

    input CLOCK_50,

    // GPIO
    input  GPIO_1,   // RX
    output GPIO_0,   // TX

    // INPUT
    input [9:0] SW,
    input [1:0] KEY,

    // OUTPUT
    output [9:0] LEDR
);

    // =====================================================
    // RESET (KEY0)
    // =====================================================
    wire reset;
    assign reset = ~KEY[0];   // KEY0 nhấn = reset

    // =====================================================
    // UART SIGNALS
    // =====================================================
    wire tx_full;
    wire rx_empty;
    wire [7:0] rx_data;

    reg tx_wr_en;
    reg [7:0] tx_data;

    reg rx_rd_en;

    // =====================================================
    // UART INSTANCE
    // =====================================================
    UART uart_inst (
        .clk        (CLOCK_50),
        .reset      (reset),

        .rx         (GPIO_1),
        .tx         (GPIO_0),

        .tx_wr_en   (tx_wr_en),
        .tx_data    (tx_data),
        .tx_full    (tx_full),

        .rx_rd_en   (rx_rd_en),
        .rx_data    (rx_data),
        .rx_empty   (rx_empty),

        .rx_irq     ()
    );

    // =====================================================
    // EDGE DETECT KEY1 (SEND BUTTON)
    // =====================================================
    reg key1_d, key1_prev;

    always @(posedge CLOCK_50) begin
        key1_d    <= ~KEY[1];   // active low
        key1_prev <= key1_d;
    end

    wire key1_pulse = key1_d & ~key1_prev;

    // =====================================================
    // TX CONTROL
    // =====================================================
    always @(posedge CLOCK_50) begin
        if (reset) begin
            tx_wr_en <= 0;
            tx_data  <= 0;
        end else begin
            tx_wr_en <= 0;

            if (key1_pulse && !tx_full) begin
                tx_wr_en <= 1;
                tx_data  <= SW[7:0];   // lấy 8 bit
            end
        end
    end

    // =====================================================
    // RX CONTROL
    // =====================================================
    always @(posedge CLOCK_50) begin
        if (reset) begin
            rx_rd_en <= 0;
        end else begin
            rx_rd_en <= 0;

            if (!rx_empty) begin
                rx_rd_en <= 1;   // đọc ngay khi có data
            end
        end
    end

    // =====================================================
    // LED OUTPUT
    // =====================================================
    reg [9:0] led_reg;

    always @(posedge CLOCK_50) begin
        if (reset) begin
            led_reg <= 0;
        end else begin
            if (rx_rd_en) begin
                led_reg[7:0] <= rx_data;
            end
        end
    end

    assign LEDR = led_reg;

endmodule