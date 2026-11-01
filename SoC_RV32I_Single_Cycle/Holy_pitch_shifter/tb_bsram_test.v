`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2026 09:02:27 AM
// Design Name: 
// Module Name: tb_bsram_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_bsram_test;
    reg clk;
    reg rst;
    reg [31:0] i2s_status_in;
    reg [31:0] i2s_data_rx_in;
    
    CORE uut(
        .clk(clk),
        .reset(rst),
        .KEY(2'b11),
        .SW(8'b0),
        .uart_rx(1'b1),
        .i2s_status_in(i2s_status_in),
        .i2s_data_rx_in(i2s_data_rx_in),
        .dsp_wr_data(),
        .dsp_pitch_we(),
        .dsp_nlms_we()
    );
    // Vuot cap theo doi cpu
    wire [31:0] core_ALUResult = uut.alu_result;
    wire        core_MemWrite = uut.mem_write;
    wire        core_MemRead = uut.MemRead;
    wire [31:0] core_StoreData = uut.store_data;
    wire [31:0] core_ReadData = uut.data_out;
    initial begin
        clk = 0;
        forever #18.52 clk = ~clk;
    end
    always @(posedge clk) begin
        if(core_MemRead && core_ALUResult == 32'h2000_0014) begin
            i2s_status_in <= 32'd0;
        end
    end
    
    always @(posedge clk) begin
        if(rst == 0) begin
            if(core_MemWrite && core_ALUResult[31:16] == 16'h4000) begin
                $display("[BSRAM GHI] Tai dia chi: %h | Cat du lieu: %h", core_ALUResult, core_StoreData);
            end
            if(core_MemRead && core_ALUResult[31:16] == 16'h4000) begin
                $display("[BSRAM GHI] CPU yeu cau doc tai dia chi %h", core_ALUResult);
            end
            if(core_MemWrite && core_ALUResult[31:16] == 32'h2000_000) begin
                $display("[BSRAM GHI] Tai dia chi: %h | Xuat du lieu: %h", core_ALUResult, core_StoreData);
                $display("--------------------------------------------------");
            end
        end
    end
    
    initial begin
        rst = 1;
        i2s_status_in = 0;
        i2s_data_rx_in = 32'd0;
        #100;
        rst = 0;
        #2000; // ??i CPU boot
        $display("==================================================");
        $display(" BAT DAU TEST: I2S -> BSRAM -> CPU -> DSP         ");
        $display("==================================================");
        // B?m Frame 1: Data = 0xAAAA_BBBB
        @(posedge clk);
        i2s_data_rx_in = 32'hAAAA_BBBB;
        i2s_status_in = 32'd1;
        repeat(200) @(posedge clk);
        // B?m Frame 2: Data = 0xCCCC_DDDD
        // B?m Frame 2: Data = 0xCCCC_DDDD
        @(posedge clk);
        i2s_data_rx_in = 32'hCCCC_DDDD; 
        i2s_status_in  = 32'd1;         
        repeat(200) @(posedge clk);
        #5000;
        $display("==================================================");
        $display(" KET THUC TEST MO PHONG                           ");
        $display("==================================================");
        $stop;
    end
endmodule
