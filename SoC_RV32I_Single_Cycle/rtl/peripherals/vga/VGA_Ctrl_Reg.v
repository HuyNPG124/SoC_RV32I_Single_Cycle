// =====================================================
// Module VGA_Ctrl_Reg
// + Dùng để chọn kích thước font chữ
// + Kích thước mặc định là 8x16
// =====================================================

module VGA_Ctrl_Reg (

	input clk,
	input reset,
	input we,
	input [31:0] data_in,
	
	output reg [3:0] font_w,
	output reg [4:0] font_h
);

	always @(posedge clk or posedge reset) begin
		
		if (reset) begin
			font_w <= 8;
			font_h <= 16;
		end
		
		else if (we) begin
			font_w <= data_in[3:0];
			font_h <= data_in[8:4];
		end
		
	end

endmodule