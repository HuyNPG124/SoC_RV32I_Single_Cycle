// ==========================================================
// Module ALU
// ISA: RV32I
// ==========================================================
module ALU (
	input [31:0]	aluIn1,
	input [31:0]	aluIn2,
	input [3:0]		alu_op,
	
	output reg [31:0] result,
	output zero
);

	always @(*) begin
		case (alu_op)
			4'b0000: result = aluIn1;			// Pass A
			4'b0001: result = aluIn2;			// PAss B
			
			4'b0010: result = aluIn1 + aluIn2;	// ADD
			4'b0011: result = aluIn1 - aluIn2;	// SUB
			
			4'b0100: result = aluIn1 & aluIn2;	// AND
			4'b0101: result = aluIn1 | aluIn2;	// OR
			4'b0110: result = aluIn1 ^ aluIn2;	// XOR
			
			4'b0111: result = aluIn1 << aluIn2[4:0];	// SLL
			4'b1000: result = aluIn1 >> aluIn2[4:0];	// SRL
			4'b1001: result = $signed(aluIn1) >>> aluIn2[4:0];	// SRA (Dịch phải số học --> Giữ nguyên bit dấu)
			
			4'b1010: result = ($signed(aluIn1) < $signed(aluIn2)) ? 32'd1 : 32'd0;	// SLT
			4'b1011: result = (aluIn1 < aluIn2) ? 32'd1 : 32'd0;							// SLTU
			
			default: result = 32'd0;
			
		endcase
		
	end	
	
	assign zero = (result == 32'b0) ? 1 : 0;
	
endmodule