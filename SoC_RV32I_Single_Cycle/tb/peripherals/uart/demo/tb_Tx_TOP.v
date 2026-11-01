//`timescale 1ns/1ps
//
//module tb_Tx_TOP;
//
//    parameter DATA_BITS = 8;
//
//    reg clk;
//    reg reset;
//    reg [DATA_BITS-1:0] fifo_data_in;
//    reg fifo_wr_en;
//
//    wire tx_serial_out;
//
//    // ================= DUT =================
//    Tx_TOP #(
//        .CLK_SYS   (50_000_000),   // đúng 50MHz
//        .BAUD_RATE (9600)
//    ) dut (
//        .clk            (clk),
//        .reset          (reset),
//        .fifo_data_in   (fifo_data_in),
//        .fifo_wr_en     (fifo_wr_en),
//        .tx_serial_out  (tx_serial_out)
//    );
//
//    // ================= CLOCK =================
//    initial begin
//        clk = 0;
//        forever #10 clk = ~clk;   // 50MHz
//    end
//
//    // ================= TASK =================
//    task write_fifo;
//        input [7:0] data;
//    begin
//        @(posedge clk);
//        fifo_wr_en   = 1;
//        fifo_data_in = data;
//
//        @(posedge clk);
//        fifo_wr_en = 0;
//    end
//    endtask
//
//    // ================= MONITOR =================
//    initial begin
//        $display("Time\tTX");
//        $monitor("%0t\t%b", $time, tx_serial_out);
//    end
//
//    // ================= TEST =================
//    initial begin
//        reset = 1;
//        fifo_wr_en = 0;
//        fifo_data_in = 0;
//
//        #100;
//        reset = 0;
//
//        // ================= WRITE DATA =================
//        $display("=== WRITE DATA TO FIFO ===");
//
//        write_fifo(8'hAA);
//        write_fifo(8'hBB);
//        write_fifo(8'hDD);
//
//        // ================= WAIT TX =================
//        $display("=== WAIT FOR UART TX ===");
//
//        #5_000_000;   // Tăng thời gian vì baud 9600 khá chậm
//
//        $finish;
//    end
//
//endmodule

//`timescale 1ns/1ps
//
//module tb_Tx_TOP;
//
//    parameter DATA_BITS = 8;
//    parameter FIFO_DEPTH = 32;
//
//    reg clk;
//    reg reset;
//    reg [DATA_BITS-1:0] fifo_data_in;
//    reg fifo_wr_en;
//
//    wire tx_serial_out;
//
//    integer i;
//
//    // ================= DUT =================
//    Tx_TOP #(
//        .CLK_SYS   (50_000_000),
//        .BAUD_RATE (9600)
//    ) dut (
//        .clk            (clk),
//        .reset          (reset),
//        .fifo_data_in   (fifo_data_in),
//        .fifo_wr_en     (fifo_wr_en),
//        .tx_serial_out  (tx_serial_out)
//    );
//
//    // ================= CLOCK =================
//    initial begin
//        clk = 0;
//        forever #10 clk = ~clk;   // 50MHz
//    end
//
//    // ================= TASK =================
//    task write_fifo;
//        input [7:0] data;
//    begin
//        @(posedge clk);
//        fifo_wr_en   = 1;
//        fifo_data_in = data;
//
//        @(posedge clk);
//        fifo_wr_en = 0;
//    end
//    endtask
//
//    // ================= MONITOR =================
//    initial begin
//        $display("Time\tTX");
//        $monitor("%0t\t%b", $time, tx_serial_out);
//    end
//
//    // ================= TEST =================
//    initial begin
//        reset = 1;
//        fifo_wr_en = 0;
//        fifo_data_in = 0;
//
//        #100;
//        reset = 0;
//
//        // ================= TEST 1: WRITE NORMAL =================
//        $display("=== WRITE 3 BYTES ===");
//
//        write_fifo(8'hAA);
//        write_fifo(8'hBB);
//        write_fifo(8'hDD);
//
//        // ================= TEST 2: FILL FIFO =================
//        $display("=== FILL FIFO ===");
//
//        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
//            write_fifo(i);
//        end
//
//        // ================= TEST 3: WRITE WHEN FULL =================
//        $display("=== WRITE WHEN FIFO FULL (SHOULD IGNORE) ===");
//
//        write_fifo(8'hFF);
//
//        // ================= WAIT TX =================
//        $display("=== WAIT FOR UART TX ===");
//
//        #20_000_000;   // đủ dài để thấy FIFO xả hết
//
//        $finish;
//    end
//
//endmodule

`timescale 1ns/1ps

module tb_Tx_TOP;

    parameter DATA_BITS = 8;

    reg clk;
    reg reset;
    reg [DATA_BITS-1:0] fifo_data_in;
    reg fifo_wr_en;

    wire tx_serial_out;

    // ================= DUT =================
    Tx_TOP #(
        .CLK_SYS   (50_000_000),
        .BAUD_RATE (9600)
    ) dut (
        .clk            (clk),
        .reset          (reset),
        .fifo_data_in   (fifo_data_in),
        .fifo_wr_en     (fifo_wr_en),
        .tx_serial_out  (tx_serial_out)
    );

    // ================= CLOCK =================
    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // 50MHz
    end

    // ================= TASK =================
    task write_fifo;
        input [7:0] data;
    begin
        @(posedge clk);
        fifo_wr_en   = 1;
        fifo_data_in = data;

        @(posedge clk);
        fifo_wr_en = 0;
    end
    endtask

    // ================= MONITOR =================
    initial begin
        $display("Time\tTX");
        $monitor("%0t\t%b", $time, tx_serial_out);
    end

    // ================= TEST =================
    initial begin
        reset = 1;
        fifo_wr_en = 0;
        fifo_data_in = 0;

        #100;
        reset = 0;

        // ================= WRITE 1 BYTE =================
        $display("=== SEND 1 BYTE ===");

        write_fifo(8'hA5);   // bạn có thể đổi giá trị

        // ================= WAIT TX =================
        $display("=== WAIT FOR UART TX ===");

        #2_000_000;   // đủ để gửi 1 byte (~1ms)

        $finish;
    end

endmodule