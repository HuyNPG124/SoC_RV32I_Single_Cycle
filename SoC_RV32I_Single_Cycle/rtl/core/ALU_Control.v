// ==================================================
// Module ALU_Control
// + Xác định phép toán mà ALU cần thực hiện
// 
// *Luồng dữ liệu:
// Instruction --> Decode --> ALU_Control --> ALU
// ==================================================
module ALU_Control(
	input [6:0] opcode,		// opcode được decode từ Instruction
	input [2:0] funct3,
	input [6:0] funct7,
	
	output reg [3:0] alu_op
);

	always @(*) begin
		// Trạng thái ban đầu
		alu_op = 4'b0000;
		
		case (opcode)
			
			// ===========================
			// R-Type
			// ===========================
			
			7'b0110011: 
			begin
				
				// Xác định chi tiết loại phép toán thực hiện trong ALU
				case (funct3)
				
					3'b000: 
						alu_op = (funct7[5]) ? 4'b0011 : 4'b0010;		// SUB / ADD
					
					3'b001: alu_op = 4'b0111;		// SLL		
					3'b010: alu_op = 4'b1010;		// SLT
					3'b011: alu_op = 4'b1011;		// SLTU
					3'b100: alu_op = 4'b0110;		// XOR
					
					3'b101:
						alu_op = (funct7[5]) ? 4'b1001 : 4'b1000; 	// SRA / SRL
					
					3'b110: alu_op = 4'b0101;		// OR
					3'b111: alu_op = 4'b0100;		// AND
					
				endcase
				
			end
			
			// ============================
			// I-Type ALU
			// ============================
			
			7'b0010011:
			begin
			
				case (funct3)
				
					3'b000: alu_op = 4'b0010;		// ADDI
					3'b001: alu_op = 4'b0111;		// SLLI
					3'b010: alu_op = 4'b1010;		// SLTI
					3'b011: alu_op = 4'b1011;		// SLTIU
					3'b100: alu_op = 4'b0110;		// XORI
					3'b110: alu_op = 4'b0101;		// ORI
					3'b111: alu_op = 4'b0100;		// ANDI
				
					3'b101:
						alu_op = (funct7[5]) ? 4'b1001 : 4'b1000; // SRAI / SRLI
					
				endcase
			end
			
			// =====================================================
			// LOAD / STORE AUIPC
			// LOAD/ STORE/ AUIPC đều sử dụng phép cộng --> ADD
			// =====================================================
			
			7'b0000011,		// LOAD
			7'b0100011,		// STORE
			7'b0010111:		// AUIPC
				alu_op = 4'b0010;		// ADD
				
			// ======================================================
			// LUI (Load Upper Immediate)
			// + Nạp một hằng số 20-bit vào 20 bit cao của register
			// ======================================================
			
			7'b0110111:
				alu_op = 4'b0001;		// Pass B
			
			// ======================================================
			// Branch
			// + Sử dụng phép trừ (SUB) để so sánh
			// ======================================================
			
			7'b1100011:
				alu_op = 4'b0011;		// SUB
				
			// ======================================================
			// JAL / JALR
			// 
			// *JAL:
			// - Chức nắng:
			// + Gọi hàm
			// + Nhảy vòng lặp
			// + Nhảy không điều kiện
			//
			// - Cách hoạt động: jal x1, 16 (PC = 0x1000)
			// + x1 = PC + 4
			// + PC = PC + offset (16)
			// ======================================================
			
			7'b1101111,
			7'b1100111:
				alu_op = 4'b0010;		// ADD
			
		endcase
	end
	
endmodule