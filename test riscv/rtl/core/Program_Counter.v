// ==========================================
// 
// ==========================================

module Program_Counter (
	input clk,
	input pc_reset,
	input stall,			// stall: điều khiển PC (stall = 0: pc cập nhật, stall = 1: pc đứng yên)
	input [31:0] pc_in,
	
	output reg [31:0] pc_out
	
);

	always @(posedge clk) begin
		if (pc_reset) begin
			pc_out <= 32'h0000_0000;
		end
		
		else if (!stall) begin
			pc_out <= pc_in;
		end
	end
	
endmodule