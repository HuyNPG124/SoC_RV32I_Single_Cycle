// ==========================================
// Testbench ImmGen
// ==========================================

`timescale 1ns/1ps

module tb_ImmGen;

	reg [31:0] instruction;
	reg [2:0]  ImmSel;
	
	wire [31:0] imm;
	
	ImmGen ImmGen_uut (
		.instruction (instruction),
		.ImmSel (ImmSel),
		.imm (imm)
	);
	
	initial begin
	
		// =========================
		// I-TYPE (ADDI)
		// addi x1, x2, 10
		// imm = 10
		// =========================
		instruction = 32'b000000001010_00010_000_00001_0010011;
		ImmSel = 3'b000;
		
		// =========================
		// I-TYPE negative
		// addi x1, x2, -1
		// =========================
		#10
		instruction = 32'b111111111111_00010_000_00001_0010011;
		ImmSel = 3'b000;
		
		// =========================
		// S-TYPE (SW)
		// sw x1, 8(x2)
		// =========================
		#10
		instruction = 32'b0000000_00001_00010_010_01000_0100011;
		ImmSel = 3'b001;
		
		// =========================
		// B-TYPE (BEQ)
		// offset = 16
		// =========================
		#10
		instruction = 32'b0000000_00010_00001_000_10000_1100011;
		ImmSel = 3'b010;
		
		// =========================
		// J-TYPE (JAL)
		// offset = 32
		// =========================
		#10
		instruction = 32'b00000000001000000000_00001_1101111;
		ImmSel = 3'b011;
		
		// =========================
		// U-TYPE (LUI)
		// =========================
		#10
		instruction = 32'h12345037; // lui x0, 0x12345
		ImmSel = 3'b100;
		
		#10 $finish;
		
	end
	
endmodule