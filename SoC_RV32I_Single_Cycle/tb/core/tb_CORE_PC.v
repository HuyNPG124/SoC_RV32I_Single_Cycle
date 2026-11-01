// ====================================
// Testbench CORE_PC
// ====================================

`timescale 1ns/1ps

module tb_CORE_PC;
	reg clk;
	reg reset;
	reg [7:0] SW;
	
	wire [7:0] LEDR;
	wire [31:0] tb_instruction;
	//wire [31:0] tb_pc_out;
	//wire [31:0] tb_pc_next;
	wire [9:0] tb_addr;
	
//	wire [6:0] tb_opcode;
//	wire [2:0] tb_funct3;
//	wire [6:0] tb_funct7;
//	
//	wire [2:0] tb_ImmSel;
	wire [31:0] tb_imm;
	
	wire tb_BrEq;
	wire tb_BrLt;
	wire tb_PCSel;
	
	wire [31:0] tb_rs1_data;
	wire [31:0] tb_rs2_data;
	
	wire [31:0] tb_aluIn1;
	wire [31:0] tb_aluIn2;
	wire [31:0] tb_alu_result;
	
	wire tb_RegWEn;
	wire [4:0] tb_rd;
	wire [31:0] tb_wr_data;
	
	CORE CORE_PC_uut (
		.clk (clk),
		.reset (reset),
		.SW (SW),
		.LEDR (LEDR),
		.tb_instruction (tb_instruction),
		//.tb_pc_out (tb_pc_out),
		//.tb_pc_next (tb_pc_next),
		.tb_addr (tb_addr),
//		.tb_opcode (tb_opcode),
//		.tb_funct3 (tb_funct3),
//		.tb_funct7 (tb_funct7),
//		.tb_ImmSel (tb_ImmSel),
		.tb_imm (tb_imm),
		.tb_BrEq (tb_BrEq),
		.tb_BrLt (tb_BrLt),
		.tb_PCSel (tb_PCSel),
		.tb_rs1_data (tb_rs1_data),
		.tb_rs2_data (tb_rs2_data),
		.tb_aluIn1 (tb_aluIn1),
		.tb_aluIn2 (tb_aluIn2),
		.tb_alu_result (tb_alu_result),
		.tb_RegWEn (tb_RegWEn),
		.tb_rd (tb_rd),
		.tb_wr_data (tb_wr_data)
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
        #500000;

        $stop;
    end

    // =========================
    // Monitor (Debug CPU)
    // =========================
//    initial begin
//        $monitor("T=%0t | PC=%h | INSTR=%h | LED=%h",
//                  $time,
//                  uut.pc_out,
//                  uut.instruction,
//                  LEDR);
    //end
	
endmodule