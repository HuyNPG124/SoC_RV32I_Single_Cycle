module DE10_UART_RX_FIFO_DEMO (

    input CLOCK_50,        // 50MHz clock
    input [1:0] KEY,       // KEY[0]: reset (active low)

    input GPIO0,           // 🔥 UART RX từ CP2102

    output reg [9:0] LEDR  // hiển thị dữ liệu
);

    // =========================
    // RESET
    // =========================
    wire reset;
    assign reset = ~KEY[0];

    // =========================
    // Rx + FIFO
    // =========================
    wire [7:0] fifo_data_out;
    wire fifo_empty;
    wire fifo_full;
    wire rx_irq;

    reg fifo_rd_en;

    Rx_TOP #(
        .CLK_SYS   (50_000_000),
        .BAUD_RATE (115200),
        .DATA_BITS (8)
    ) rx_top (
        .clk            (CLOCK_50),
        .reset          (reset),
        .rx_serial_in   (GPIO0),   // 🔥 dùng GPIO0

        .fifo_rd_en     (fifo_rd_en),
        .fifo_data_out  (fifo_data_out),
        .fifo_empty     (fifo_empty),
        .fifo_full      (fifo_full),
        .rx_irq         (rx_irq)
    );

    // =========================
    // READ FIFO (fix latency)
    // =========================
    reg [7:0] data_reg;
    reg fifo_rd_en_d;

    always @(posedge CLOCK_50) begin
        if (reset) begin
            fifo_rd_en   <= 0;
            fifo_rd_en_d <= 0;
            data_reg     <= 0;
        end
        else begin
            fifo_rd_en   <= 0;
            fifo_rd_en_d <= fifo_rd_en;

            if (!fifo_empty) begin
                fifo_rd_en <= 1;
            end

            if (fifo_rd_en_d) begin
                data_reg <= fifo_data_out;
            end
        end
    end

    // =========================
    // LED OUTPUT
    // =========================
    always @(posedge CLOCK_50) begin
        if (reset) begin
            LEDR <= 10'b0;
        end
        else begin
            LEDR[7:0] <= data_reg;
            LEDR[8]   <= rx_irq;
            LEDR[9]   <= fifo_empty;
        end
    end

endmodule