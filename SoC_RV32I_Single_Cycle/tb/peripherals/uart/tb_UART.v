`timescale 1ns/1ps

module tb_UART;

    // ======================================================
    // PARAMETERS
    // ======================================================
    parameter CLK_SYS     = 50_000_000;
    parameter BAUD_RATE   = 9600;
    parameter DATA_BITS   = 8;
    parameter OVERSAMPLE  = 16;

    // ======================================================
    // CLOCK
    // ======================================================
    reg clk = 0;
    always #10 clk = ~clk;   // 50MHz

    // ======================================================
    // SIGNALS
    // ======================================================
    reg reset;

    wire tx;
    reg  rx;

    // TX
    reg tx_wr_en;
    reg [7:0] tx_data;
    wire tx_full;

    // RX
    reg rx_rd_en;
    wire [7:0] rx_data;
    wire rx_empty;

    // ======================================================
    // DUT
    // ======================================================
    UART uut (
        .clk        (clk),
        .reset      (reset),
        .rx         (rx),
        .tx         (tx),

        .tx_wr_en   (tx_wr_en),
        .tx_data    (tx_data),
        .tx_full    (tx_full),

        .rx_rd_en   (rx_rd_en),
        .rx_data    (rx_data),
        .rx_empty   (rx_empty)
    );

    // ======================================================
    // LOOPBACK (THỰC TẾ HƠN)
    // ======================================================
    always @(posedge clk) begin
        rx <= tx;   // thêm 1 cycle delay
    end

    // ======================================================
    // TASK: SEND BYTE
    // ======================================================
    task send_byte(input [7:0] data);
    begin
        @(posedge clk);

        while (tx_full) @(posedge clk);

        tx_data  <= data;
        tx_wr_en <= 1;

        @(posedge clk);
        tx_wr_en <= 0;

        $display("[%0t] SEND: 0x%h", $time, data);
    end
    endtask

    // ======================================================
    // TASK: WAIT RX VALID
    // ======================================================
    task wait_rx_data;
    begin
        while (rx_empty) @(posedge clk);
    end
    endtask

    // ======================================================
    // TASK: READ BYTE
    // ======================================================
    task read_byte;
    begin
        wait_rx_data();

        @(posedge clk);
        rx_rd_en <= 1;

        @(posedge clk);
        rx_rd_en <= 0;

        @(posedge clk); // chờ data stable

        $display("[%0t] RECEIVE: 0x%h", $time, rx_data);
    end
    endtask

    // ======================================================
    // UART TIME (VERY IMPORTANT)
    // ======================================================
    real bit_time;
    real frame_time;

    initial begin
        bit_time   = 1e9 / BAUD_RATE;        // ns
        frame_time = bit_time * 10;          // 1 start + 8 data + 1 stop
    end

    // ======================================================
    // TEST
    // ======================================================
    initial begin
        // INIT
        reset     = 1;
        tx_wr_en  = 0;
        rx_rd_en  = 0;
        tx_data   = 0;
        rx        = 1;

        #100;
        reset = 0;

        #1000;

        // =============================
        // TEST 1
        // =============================
        $display("===== TEST 1 =====");
        send_byte(8'hA5);

        #(frame_time * 1.5);
        read_byte();

        // =============================
        // TEST 2
        // =============================
        $display("===== TEST 2 =====");

        send_byte(8'h55);
        send_byte(8'hAA);
        send_byte(8'h0F);
        send_byte(8'hF0);

        #(frame_time * 5);

        repeat (4) read_byte();

        // =============================
        // TEST 3: STREAM
        // =============================
        $display("===== TEST 3 =====");

        repeat (10) begin
            send_byte($random);
        end

        #(frame_time * 12);

        repeat (10) read_byte();

        // =============================
        // DONE
        // =============================
        #1000;
        $display("===== DONE =====");
        $stop;
    end

    // ======================================================
    // MONITOR
    // ======================================================
    initial begin
        $monitor("T=%0t | tx=%b rx=%b empty=%b data=%h",
                  $time, tx, rx, rx_empty, rx_data);
    end

endmodule