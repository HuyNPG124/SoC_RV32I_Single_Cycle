// ===============================================
// Module Decode
// + Ä?á»?c opcode
// + Ä?á»?c funct3
// + Ä?á»?c funct7
// + XÃ¡c Ä‘á»‹nh instructipn type
// ===============================================
module Decode(
	input [31:0] instruction,			// Instruction láº¥y tá»« Memory
	
	// Extracted fields
	output [6:0] opcode,
	output [2:0] funct3,
	output [6:0] funct7,
	
	// Instruction type flags (Instruction cho RV32I)
	output reg is_rtype,
	output reg is_itype,
	output reg is_load,		// LW
	output reg is_store,	// SW
	output reg is_branch,	// BEQ, BNE, BLT, BGE
	output reg is_jal,		// JAL
	output reg is_jalr,		// JALR
	output reg is_lui,		// LUI
	output reg is_auipc,		// AUIPC
	output is_mret // thoat ngat
);

	// =============================================
	// Extract instruction
	// =============================================
	assign opcode = instruction [6:0];
	assign funct3 = instruction [14:12];
	assign funct7 = instruction [31:25];
	assign is_mret = (instruction == 32'h30200073);
	// =============================================
	// Decode opcode
	// =============================================
	always @(*) begin
		// Khá»Ÿi táº¡o giÃ¡ trá»‹ ban Ä‘áº§u
		is_rtype	= 0;
		is_itype 	= 0;
		is_load 	= 0;
		is_store	= 0;
		is_branch	= 0;
		is_jal		= 0;
		is_jalr		= 0;
		is_lui		= 0;
		is_auipc	= 0;
		
		case (opcode)
			
			7'b0110011: is_rtype	= 1;	// R-Type (ADD, SUB, AND, OR, XOR,...)
			
			7'b0010011: is_itype	= 1;	// I-Type (ADDI, ANDI,..)
			
			7'b0000011: is_load		= 1;	// LW
			
			7'b0100011: is_store	= 1;	// SW
			
			7'b1100011: is_branch	= 1;	// BEQ, BNE, BLT, BGE
			
			7'b1101111: is_jal		= 1;	// JAL
			
			7'b1100111: is_jalr		= 1;	// JALR
			
			7'b0110111: is_lui		= 1; 	// LUI
			
			7'b0010111: is_auipc	= 1;	// AUIPC
			
			default: ;
			
		endcase
		
	end

endmodule