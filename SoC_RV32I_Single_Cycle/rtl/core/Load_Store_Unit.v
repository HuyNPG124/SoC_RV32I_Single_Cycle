// ==========================================================
// Module Load_Store_Unit
// + Store: căn dữ liệu rs2 vào đúng làn byte, tạo byte_en
//   (SB / SH / SW)
// + Load: tách byte / half-word từ word đọc được,
//   mở rộng dấu hoặc mở rộng 0 (LB / LH / LW / LBU / LHU)
// ==========================================================

module Load_Store_Unit (
	input [2:0] funct3,				// Kiểu truy cập (lấy từ instruction)
	input [1:0] addr_low,			// 2 bit thấp của địa chỉ

	// Store
	input [31:0] store_in,			// rs2_data
	output reg [31:0] store_data,	// Dữ liệu đã căn làn byte
	output reg [3:0] byte_en,		// Byte được ghi

	// Load
	input [31:0] load_word,		// Word đọc từ RAM / ngoại vi
	output reg [31:0] load_data	// Kết quả ghi vào thanh ghi rd
);

	// =============================
	// STORE
	// =============================
	always @(*) begin
		case (funct3[1:0])

			2'b00: begin		// SB
				store_data	= {4{store_in[7:0]}};
				byte_en		= 4'b0001 << addr_low;
			end

			2'b01: begin		// SH
				store_data	= {2{store_in[15:0]}};
				byte_en		= addr_low[1] ? 4'b1100 : 4'b0011;
			end

			default: begin		// SW
				store_data	= store_in;
				byte_en		= 4'b1111;
			end

		endcase
	end

	// =============================
	// LOAD
	// =============================
	wire [7:0] load_byte =
			(addr_low == 2'd0) ? load_word[7:0]   :
			(addr_low == 2'd1) ? load_word[15:8]  :
			(addr_low == 2'd2) ? load_word[23:16] :
								 load_word[31:24];

	wire [15:0] load_half = addr_low[1] ? load_word[31:16] : load_word[15:0];

	always @(*) begin
		case (funct3)
			3'b000:  load_data = {{24{load_byte[7]}}, load_byte};		// LB
			3'b001:  load_data = {{16{load_half[15]}}, load_half};	// LH
			3'b100:  load_data = {24'b0, load_byte};					// LBU
			3'b101:  load_data = {16'b0, load_half};					// LHU
			default: load_data = load_word;								// LW
		endcase
	end

endmodule
