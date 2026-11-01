// ======================================
// Testbench ALU_Control
// ======================================

`timescale 1ns/1ps

module tb_ALU_Control;
	reg [6:0] opcode;
	reg [2:0] funct3;
	reg [6:0] funct7;
	
	wire [3:0] alu_op;
	
	ALU_Control ALU_Control_uut (
		.opcode (opcode),
		.funct3 (funct3),
		.funct7 (funct7),
		.alu_op (alu_op)
	);
	
	initial begin
		opcode = 7'b000_0000;
		funct3 = 3'b000;
		funct7 = 7'b000_0000;
		
		// Test case 1 
		#10
		opcode = 7'b011_0011;
		funct3 = 3'b000;
		funct7 = 7'b000_0000;
		
		// Test case 2
		#10
		opcode = 7'b011_0011;
		funct3 = 3'b000;
		funct7 = 7'b010_0000;
		
		// Test case 3
		#10 
		opcode = 7'b011_0011;
		funct3 = 3'b111;
		funct7 = 7'b000_0000;
		
		// Test case 4
		#10
		opcode = 7'b011_0011;
		funct3 = 3'b110;
		funct7 = 7'b000_0000;
		
	end
	
endmodule