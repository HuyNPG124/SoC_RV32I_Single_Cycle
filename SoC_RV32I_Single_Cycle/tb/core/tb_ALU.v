// =============================================
//	Testbench ALU
// =============================================
`timescale 1ns/1ps

module tb_ALU;
	reg [31:0]		aluIn1;
	reg [31:0]		aluIn2;
	reg [3:0]		alu_op;
	
	wire [31:0] 	result;
	wire 				zero;
	
	ALU ALU_uut (
		.aluIn1 (aluIn1),
		.aluIn2 (aluIn2),
		.alu_op (alu_op),
		.result (result),
		.zero   (zero)
	);
	
	initial begin
		aluIn1 = 32'h0000_3456;
		aluIn2 = 32'h0000_1234;
		
		alu_op = 4'b0000;					// Pass A
		
		#10 alu_op = 4'b0001;			// Pass B
		#10 alu_op = 4'b0010;			// ADD
		#10 alu_op = 4'b0011;			// SUB
		#10 alu_op = 4'b0100;			// AND
		#10 alu_op = 4'b0101;			// OR
		#10 alu_op = 4'b0110;			// XOR
		#10 alu_op = 4'b0111;			// SLL
		#10 alu_op = 4'b1000;			// SRL
		#10 alu_op = 4'b1001;			// SRA
		#10 alu_op = 4'b1010;			// SLT
		#10 alu_op = 4'b1011;			// SLTU
	
		#10 $finish;
		
	end
	
endmodule