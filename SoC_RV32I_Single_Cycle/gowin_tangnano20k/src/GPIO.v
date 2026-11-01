// ==================================================
// Module GPIO
// + Nhận tín hiệu từ CPU --> xuất ra LED
// + Nhận tín hiệu từ SWITCH --> Trả về CPU
// ==================================================

module GPIO (
	
	input clk,
	input reset,
	
	input [31:0] addr,
	input [31:0] wr_data,
	input 		 write_en,
	input			 read_en,
	input [7:0]  gpio_in,
	
	output reg [31:0] rd_data,
	output reg [7:0]	gpio_out
		
);

	parameter GPIO_OUT_ADDR = 32'h1000_0000;
	parameter GPIO_IN_ADDR	= 32'h1000_0004;
	
	always @(posedge clk) begin
		if (reset) begin
			gpio_out <= 8'b0;
		end
		
		else if (write_en && addr == GPIO_OUT_ADDR) begin
			gpio_out <= wr_data[7:0];
		end
	end
	
	always @(*) begin
		if (read_en && addr == GPIO_IN_ADDR) begin
			rd_data = {24'b0, gpio_in};
		end
		
		else if (read_en && addr == GPIO_OUT_ADDR) begin
			rd_data = {24'b0, gpio_out};
		end
		
		else begin
			rd_data = 32'b0;
		end
	end
	
endmodule