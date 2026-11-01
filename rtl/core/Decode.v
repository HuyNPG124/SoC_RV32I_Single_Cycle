// ===============================================
// Module Decode
// + Đọc opcode
// + Đọc funct3
// + Đọc funct7
// + Xác định instructipn type
// ===============================================
module Decode(
	input [31:0] instruction,			// Instruction lấy từ Memory
	
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
	output reg is_auipc		// AUIPC
	
);

	// =============================================
	// Extract instruction
	// =============================================
	assign opcode = instruction [6:0];
	assign funct3 = instruction [14:12];
	assign funct7 = instruction [31:25];
	
	// =============================================
	// Decode opcode
	// =============================================
	always @(*) begin
		// Khởi tạo giá trị ban đầu
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
			
			7'b0110011: begin	// R-Type (ADD, SUB, AND, OR, XOR,...)
				case (funct3)
					3'b000: is_rtype = (funct7 == 7'b0000000) ||
									 (funct7 == 7'b0100000);
					3'b001, 3'b010, 3'b011, 3'b100,
					3'b110, 3'b111: is_rtype = (funct7 == 7'b0000000);
					3'b101: is_rtype = (funct7 == 7'b0000000) ||
									 (funct7 == 7'b0100000);
					default: is_rtype = 0;
				endcase
			end
			
			7'b0010011: begin	// I-Type (ADDI, ANDI,..)
				case (funct3)
					3'b000, 3'b010, 3'b011, 3'b100,
					3'b110, 3'b111: is_itype = 1;
					3'b001: is_itype = (funct7 == 7'b0000000);
					3'b101: is_itype = (funct7 == 7'b0000000) ||
									 (funct7 == 7'b0100000);
					default: is_itype = 0;
				endcase
			end
			
			7'b0000011: begin	// LB, LH, LW, LBU, LHU
				is_load = (funct3 == 3'b000) ||
						  (funct3 == 3'b001) ||
						  (funct3 == 3'b010) ||
						  (funct3 == 3'b100) ||
						  (funct3 == 3'b101);
			end
			
			7'b0100011: begin	// SB, SH, SW
				is_store = (funct3 == 3'b000) ||
						   (funct3 == 3'b001) ||
						   (funct3 == 3'b010);
			end
			
			7'b1100011: begin	// BEQ, BNE, BLT, BGE, BLTU, BGEU
				is_branch = (funct3 == 3'b000) ||
							(funct3 == 3'b001) ||
							(funct3 == 3'b100) ||
							(funct3 == 3'b101) ||
							(funct3 == 3'b110) ||
							(funct3 == 3'b111);
			end
			
			7'b1101111: is_jal		= 1;	// JAL
			
			7'b1100111: is_jalr		= (funct3 == 3'b000);	// JALR
			
			7'b0110111: is_lui		= 1; 	// LUI
			
			7'b0010111: is_auipc	= 1;	// AUIPC
			
			default: ;
			
		endcase
		
	end

endmodule