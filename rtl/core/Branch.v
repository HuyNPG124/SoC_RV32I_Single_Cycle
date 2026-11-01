// ==================================================================================
// Module Branch (Rẽ nhánh)
// + Branch là mạch so sánh trong CPU RISC-V
// + Dùng để xác định điều kiện nhảy của các lệnh branch
// + Trong project có các cấu trúc điều kiện (firmware,...) thì cần phải có branch
// ==================================================================================
module Branch (
	input [31:0] 	A,
	input [31:0] 	B,
	input 			BrUn,	// Chọn kiểu so sánh signed hoặc unsigned
	
	output reg		BrLt,	// Branch nếu nhỏ hơn
	output reg		BrEq	// Branch nếu bằng
);

	always @(*) begin
		BrLt = BrUn ? (A < B) : ($signed(A) < $signed(B)); 
		BrEq = BrUn ? (A == B) : ($signed(A) == $signed(B));
		
		/* Chi tiết luồng logic
		if (BrUn) begin
			if (A < B) begin
				BrLT = 1'b1;
				BrEQ = 1'b0;
			end
			else begin
				BrLT = 1'b0;
				if (A == B) begin
					BrEQ = 1'b1;
				end
				else begin
					BrEQ = 1'b0;
				end
			end
		end
		
		else begin
			if ($signed(A) < $signed(B)) begin
				BrLT = 1'b1
				BrEQ = 1'b0;
			end
			else begin
				BrLT = 1'b0;
				if ($signed(A) == $signed(B)) begin
					BrEQ = 1'b1;
				end
				else begin
					BrEQ = 1'b0;
				end
			end
		end
		
		*/
		
	end
	
endmodule