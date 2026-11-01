// ======================================================================
// Module Control
// + ALU làm phép toàn gì
// + Đọc/ Ghi Memory
// + Ghi register hay không
// + Branch /Jump
// + Immediate Type
// + Writeback source
// 
// *Luồng hoạt động chính
// + Instruction --> Control (--> ALU/ Register File/ Memory) --> PC
// ======================================================================

module Control(

	input [31:0] instruction,		// Instruction lấy từ Memory để decode (Đây là lệnh CPU đang thực thi)
	
	// ***************************************************************************************************
	// Output từ Module Branch (Điều khiển PCSel để quyết định có thực hiện nhảy, rẽ nhánh hay không)
	// + BrEq = 1 (Bằng nhau)
	// → PCSel = 1
	// → PC = PC + imm
	// --> Nhảy
	//
	// BrEq = 0 (Không bằng nhau)
	// → PCSel = 0
	// → PC = PC + 4
	// --> Không nhảy
	// ****************************************************************************************************
	input BrEq,	
	input BrLt,					// Hoạt động tương tự BrEq
	
	// Từ Decode
	// Giải mã instruction để ra opcode, phân loại instruction
	input is_rtype,
	input is_itype,
	input is_load,
	input is_store,
	input is_branch,
	input is_jal,
	input is_jalr,
	input is_lui,
	input is_auipc,
	
	// Outputs
	
	// Nhóm ALU
	output reg Asel,			// Chọn đầu vào aluIn1 của Module ALU
	output reg Bsel,			// Chọn đầu vào aluIn2 của Module ALU	
	
	// Nhóm Regfile
	output reg RegWEn,			// Tín hiệu cho phép ghi vào Regfile
	
	// Nhóm Memory
	output reg MemRead,			// Tín hiệu cho phép đọc dữ liệu từ RAM (Memory) LW
	output reg MemWrite,		// Tín hiệu cho phép ghi dữ liệu vào RAM (Memory) SW
	
	// Nhóm Write Back
	output reg [1:0] WBsel,		// Chọn loại dữ liệu để WB
	
	// Nhóm PC
	output reg PCSel,			// Tín hiệu quyết định PC có nhảy hay không
	
	// Nhóm Branch
	output reg BrUn,			// Chọn kiểu so sánh signed hay unsigned
	
	// Nhóm Immediate
	output reg [2:0] ImmSel		// Chọn cách decode Imm
	
); 

	always @(*) begin
		
		// =============================
		// Khai báo tín hiệu mặc định
		// =============================
		Asel		= 0;
		Bsel		= 0;
		RegWEn		= 0;
		MemRead		= 0;
		MemWrite	= 0;
		WBsel		= 2'b00;
		PCSel		= 0;
		BrUn		= 0;
		ImmSel		= 3'b000;
		
		
		// ==============================
		// R - Type
		// ==============================
		if (is_rtype) begin
			Asel		= 0;
			Bsel		= 0;
			RegWEn		= 1;
			WBsel		= 2'b00;		// ALU
		end
		
		// ==============================
		// I - Type
		// ==============================
		else if (is_itype) begin
			Asel		= 0;
			Bsel		= 1;
			RegWEn		= 1;
			WBsel		= 2'b00;
			ImmSel		= 3'b000;
		end
		
		// ==============================
		// LOAD
		// ==============================
		else if (is_load) begin
			Asel		= 0;
			Bsel		= 1;
			RegWEn		= 1;
			MemRead		= 1;
			WBsel		= 1;			// MEM
			ImmSel		= 3'b000;
		end
		
		// ==============================
		// STORE
		// ==============================
		else if (is_store) begin
			Asel		= 0;
			Bsel		= 1;
			MemWrite	= 1;
			ImmSel		= 3'b001;
		end
		
		// ==============================
		// BRANCH
		// ==============================
		else if (is_branch) begin
			Asel		= 0;
			Bsel		= 1;
			ImmSel		= 3'b010;
			
			case (instruction[14:12])
			
				3'b000: 
				begin
					//BrUn	= 0;
					PCSel	= (BrEq);		// BEQ
				end
				
				3'b001:
				begin
					//BrUn	= 0;
					PCSel	= (~BrEq);		// BNE
				end
				
				3'b100:
				begin
					BrUn	= 0;
					PCSel	= BrLt;		// BLT
				end
				
				3'b101:
				begin
					BrUn	= 0;
					PCSel	= ~BrLt;		// BGE
				end
				
				3'b110:
				begin
					BrUn	= 1;
					PCSel	= BrLt;		// BLTU
				end
				
				3'b111:
				begin
					BrUn	= 1;
					PCSel	= ~BrLt;		// BGEU
				end
				
				default: PCSel = 0;
				
			endcase
			
		end
		
		// ===================================================================
		// JAL
		// Jump And Link
		// + Nhảy đến một địa chỉ cố định (dùng offset)
		// + Không cần register
		// + Dùng để nhảy trong chương trình, gọi hàm biết trước địa chỉ
		// ====================================================================
		else if (is_jal) begin
			Asel		= 1;		// PC
			Bsel		= 1;
			RegWEn		= 1;
			WBsel		= 2'b10;	// PC + 4
			PCSel		= 1;
			ImmSel		= 3'b011;
		end
		
		// ======================================================================
		// JALR
		// Jump And Link Register
		// + Nhảy đến địa chỉ tính toán từ thanh ghi (Nhảy đến một địa chỉ mới)
		// + Đồng thời lưu địa chỉ quay lại
		// + JALR có đường xủ lý riêng, không dùng PC để xử lý
		// ======================================================================
		else if (is_jalr) begin
			Asel		= 0;
			Bsel		= 1;
			RegWEn		= 1;
			WBsel		= 2'b10;
			PCSel		= 0;			// Dùng is_jalr riêng
			ImmSel		= 3'b000;
		end
		
		// ======================================================================
		// LUI
		// Load Upper Immediate
		// + Dùng để nạp giá trị hằng vào phần cao (upper bits) của thanh ghi
		// + lui, rd, imm --> rd = imm << 12
		// + Lấy imm (20-bit), dịch trái 12 bit, lưu vào thanh ghi rd
		// + Dùng để tạo địa chỉ (cho GPIO)
		// + Tạo địa chỉ tuyệt đối
		// ======================================================================
		else if (is_lui) begin
			Asel		= 0;
			Bsel		= 1;
			RegWEn		= 1;
			WBsel		= 2'b00;
			ImmSel		= 3'b100;
		end
		
		// ======================================================================
		// AUIPC
		// Add Upper Immediate to PC
		// + auipc, rd, imm
		// + rd = PC + (imm << 12) (PC hiện tại)
		// + Tạo địa tương đối cho PC
		// ======================================================================
		else if (is_auipc) begin
			Asel		= 1;		// PC
			Bsel		= 1;
			RegWEn		= 1;
			WBsel		= 2'b00;
			ImmSel		= 3'b100;
		end
	
	end
	
endmodule