// ================================================
// Testbench Decode 
// ================================================
`timescale 1ns/1ps

module tb_Decode;
	reg [31:0] instruction;
	
	wire [6:0] opcode;
	wire [2:0] funct3;
	wire [6:0] funct7;
	
	wire is_rtype;
	wire is_itype;
	wire is_load;
	wire is_store;
	wire is_branch;
	wire is_jal;
	wire is_jalr;
	wire is_lui;
	wire is_auipc;
	
	Decode decode_uut (
		.instruction (instruction),
		.opcode (opcode),
		.funct3 (funct3),
		.funct7 (funct7),
		.is_rtype	(is_rtype),
		.is_itype	(is_itype),
		.is_load		(is_load),
		.is_store	(is_store),
		.is_branch	(is_branch),
		.is_jal		(is_jal),
		.is_jalr		(is_jalr),
		.is_lui		(is_lui),
		.is_auipc	(is_auipc)
	);
	
	initial begin
		instruction = 32'h0000_00000;
		
		#10 instruction = 32'h003100B3;
		
		#10 instruction = 32'h00A10093;
		
		#10 instruction = 32'h00032283;
		
		#10 instruction = 32'h00532223;
		
		#10 instruction = 32'h00208663;
		
		#10 instruction = 32'h010000EF;
		
		#10 instruction = 32'h000100E7;
		
		#10 instruction = 32'h123452B7;
		
		#10 instruction = 32'h10000297;
		
		#10 $finish;
	end
	
endmodule