// =========================================
// Module Data_RAM
// + Bộ nhớ của CPU
// + Lưu dữ liệu của chương trình
// + Nằm trong M9K (đ�?c đồng bộ: rd_data có sau 1 cạnh clock)
// + Chia 4 bank 8-bit (mỗi bank 1 byte của word)
//   --> ghi theo byte_en để hỗ trợ SB / SH / SW
// + Nạp sẵn firmware.hex để đ�?c được .rodata / .data
// =========================================

module Data_RAM (
	input clk,
	input [31:0] addr,			// �?ịa chỉ cần truy cập vào RAM
	input [31:0] wr_data,		// Dữ liệu cần ghi (đã căn đúng làn byte)
	input [3:0] byte_en,		// Byte nào trong word được ghi
	input read_en,				// Tín hiệu cho phép đ�?c dữ liệu trong RAM
	input write_en,				// Tín hiệu cho phép ghi dữ liệu vào RAM

	output reg [31:0] rd_data	// Dữ liệu đ�?c ra từ RAM

);

	(* ramstyle = "M9K" *) reg [7:0] bank0 [0:1023];		// Byte 0 (bit 7:0)
	(* ramstyle = "M9K" *) reg [7:0] bank1 [0:1023];		// Byte 1 (bit 15:8)
	(* ramstyle = "M9K" *) reg [7:0] bank2 [0:1023];		// Byte 2 (bit 23:16)
	(* ramstyle = "M9K" *) reg [7:0] bank3 [0:1023];		// Byte 3 (bit 31:24)

	wire [9:0] word_addr = addr[11:2];

	// =========================================
	// Khởi tạo: cùng nội dung với Instr_Memory
	// (hằng số và biến khởi tạo .rodata / .data nằm trong ảnh firmware)
	// =========================================

	reg [31:0] init_mem [0:1023];
	integer i;

	initial begin
		$readmemh("D:/SoC_RV32I_Single_Cycle/SoC_RV32I_Single_Cycle/firmware/firmware.hex", init_mem);

		for (i = 0; i < 1024; i = i + 1) begin
			bank0[i] = init_mem[i][7:0];
			bank1[i] = init_mem[i][15:8];
			bank2[i] = init_mem[i][23:16];
			bank3[i] = init_mem[i][31:24];
		end
	end

	always @(posedge clk) begin
		// Ghi dữ liệu vào RAM
		if (write_en) begin
			if (byte_en[0]) bank0[word_addr] <= wr_data[7:0];
			if (byte_en[1]) bank1[word_addr] <= wr_data[15:8];
			if (byte_en[2]) bank2[word_addr] <= wr_data[23:16];
			if (byte_en[3]) bank3[word_addr] <= wr_data[31:24];
		end

		if (read_en) begin
			rd_data <= {bank3[word_addr], bank2[word_addr], bank1[word_addr], bank0[word_addr]};
		end
	end

endmodule
