// =======================================
// Testbench VGA_TOP
// =======================================

`timescale 1ns/1ps

module tb_VGA_TOP;

    // =====================================
    // SIGNAL
    // =====================================
    reg clk;
    reg reset;

    reg [31:0] cpu_addr;
    reg [31:0] cpu_data;
    reg cpu_we;

    wire [3:0] VGA_R;
    wire [3:0] VGA_G;
    wire [3:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;

    // =====================================
    // DUT
    // =====================================
    VGA_TOP dut (
        .clk(clk),
        .reset(reset),
        .cpu_addr(cpu_addr),
        .cpu_data(cpu_data),
        .cpu_we(cpu_we),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS)
    );

    // =====================================
    // CLOCK 50MHz
    // =====================================
    initial clk = 0;
    always #10 clk = ~clk; // 20ns period = 50MHz

    // =====================================
    // TASK: WRITE CPU
    // =====================================
    task cpu_write;
        input [31:0] addr;
        input [31:0] data;
    begin
        @(posedge clk);
        cpu_addr <= addr;
        cpu_data <= data;
        cpu_we   <= 1;

        @(posedge clk);
        cpu_we   <= 0;
    end
    endtask

    // =====================================
    // DEFINE
    // =====================================
    parameter VGA_BASE  = 32'h2000_0000;
    parameter CTRL_ADDR = 32'h2200_0000;

    // =====================================
    // SIMULATION
    // =====================================
	 integer i;
    initial begin
        // init
        reset = 1;
        cpu_we = 0;
        cpu_addr = 0;
        cpu_data = 0;

        // reset
        #100;
        reset = 0;

        // =====================================
        // TEST 1: set font = 8x8
        // =====================================
        cpu_write(CTRL_ADDR, (8 << 4) | 8);

        // =====================================
        // TEST 2: ghi chữ 'A' tại (0,0)
        // =====================================
        // VGA_CHAR = {FG, BG, ASCII}
        // FG = đỏ (F00), BG = đen (000)
        cpu_write(VGA_BASE + 0*4, {12'hF00, 12'h000, 8'h41});

        // =====================================
        // TEST 3: ghi chữ 'B' tại (1,0)
        // =====================================
        cpu_write(VGA_BASE + 1*4, {12'h0F0, 12'h000, 8'h42});

        // =====================================
        // TEST 4: ghi dòng chữ
        // =====================================
        
        for (i = 0; i < 10; i = i + 1) begin
            cpu_write(
                VGA_BASE + i*4,
                {12'hFF0, 12'h000, (8'h41 + i)} // A, B, C...
            );
        end

        // =====================================
        // chạy thêm để quan sát
        // =====================================
        #200000;

        $stop;
    end

endmodule