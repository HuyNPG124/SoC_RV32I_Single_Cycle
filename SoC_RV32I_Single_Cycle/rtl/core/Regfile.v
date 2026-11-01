// ====================================================
// Module Regfile
// + Các thanh ghi dữ liệu của CPU
//
// Version 5: 04/04/26
// + Thêm addr và data để đọc dữ liệu regfile
// + Dữ liệu đọc được --> Hiển thị trên VGA
// ====================================================

module Regfile(
	input clk,
	input reset_n,
	input write_en,			// Tín hiệu cho phép ghi
	input [4:0] rs1_Add,	// Địa chỉ của thanh ghi nguồn 1
	input [4:0] rs2_Add,	// Địa chỉ của thanh ghi nguồn 2
	input [4:0] rd_Add,		// Địa chỉ của thanh ghi đích
	input [31:0] wr_data,	// Kết quả tính toán được tại ALU
	
	output [31:0] rs_data1,	// Giá trị của thanh ghi nguồn 1
	output [31:0] rs_data2	// Giá trị của thanh ghi nguồn 2
	
);

	reg [31:0] regfile [0:31];		// 32 thanh ghi của bộ nhớ
	integer i;
	
	assign rs_data1 = (rs1_Add == 0) ? 32'd0 : regfile [rs1_Add];
	assign rs_data2 = (rs2_Add == 0) ? 32'd0 : regfile [rs2_Add];
	
	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			for (i = 0; i < 32; i = i + 1) begin
				regfile[i] <= 0;
			end
		end
		
		else if (write_en && rd_Add != 0) begin
			regfile[rd_Add] <= wr_data;
		end
	end

endmodule