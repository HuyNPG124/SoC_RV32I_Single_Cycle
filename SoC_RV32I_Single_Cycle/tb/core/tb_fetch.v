`timescale 1ns/1ps

module tb_fetch;

    // =========================
    // Input
    // =========================
    reg clk;
    reg reset;
    reg [7:0] SW;

    // =========================
    // Output
    // =========================
    wire [7:0] LEDR;

    // =========================
    // Instantiate CORE
    // =========================
    CORE uut (
        .clk   (clk),
        .reset (reset),
        .SW    (SW),
        .LEDR  (LEDR)
    );

    // =========================
    // Clock (10ns)
    // =========================
    always #10 clk = ~clk;

    // =========================
    // Initial
    // =========================
    initial begin
        clk = 0;
        reset = 1;
        SW = 8'b0;   // không dùng nhưng vẫn phải gán

        // Reset CPU
        #20;
        reset = 0;

        // Chạy firmware
        #300000;

        $stop;
    end

    // =========================
    // Monitor (Debug CPU)
    // =========================
    initial begin
        $monitor("T=%0t | PC=%h | INSTR=%h | LED=%h",
                  $time,
                  uut.pc_out,
                  uut.instruction,
                  LEDR);
    end

endmodule