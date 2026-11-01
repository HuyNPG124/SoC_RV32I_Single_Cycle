// =======================================
// 
// =======================================

module mux2to1 (
	
	input [31:0] din_0,
	input [31:0] din_1,
	input sel,
	
	output [31:0] mux_out
);

	assign mux_out = (sel) ? din_1 : din_0;
	
endmodule