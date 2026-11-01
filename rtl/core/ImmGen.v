// ====================================================
// Module ImmGen
// + Trích xuất imm từ instruction
// + Imm ghép các bit nằm rải rác
// + Chuyển định dạng 32-bit
// + ouput ra imm đúng 32-bit
// ====================================================

module ImmGen (
	input [31:0] instruction,		// Lệnh gốc từ Memory
	input [2:0] ImmSel,				// Tín hiệu phân loại Type từ Control
	
	output reg [31:0] imm			// Giá trị Imm chuẩn 32-bit
	
);

	always @(*) begin
		case (ImmSel)
			
				// I - Type
				3'b000: imm = {{20{instruction[31]}}, instruction[31:20]};
				
				// S - Type
				3'b001: imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
				
				// B - Type
				3'b010: imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
				
				// J - Type
				3'b011: imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
				
				// U - Type
				3'b100: imm = {instruction[31:12], 12'b0};
				
				default: imm = 32'b0;
			
		endcase
		
	end
	
endmodule