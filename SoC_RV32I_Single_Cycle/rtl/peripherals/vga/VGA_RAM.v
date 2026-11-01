// ====================================================================
// Module VGA_RAM (Text Buffer - 32bit)
// + Bộ nhớ chưa nội dung sẽ hiển thị trên màn hình
// + Nội dung hiển thị (CPU) --> VGA_RAM --> Display
// 
// -------------------------------------------------------------------
// CPU Port
// + Dùng để ghi dữ liệu firmware muốn hiển thị
// + Điều khiển bởi firmware
// 
// --------------------------------------------------------------------
// VGA Port
// + Dùng để đọc dữ liệu muốn hiển thị ra display
// + Quét theo pixel clock (25MHz)
// + Điều khiển bởi VGA
// ====================================================================

module VGA_RAM (

	// CPU Port
	input clk,					// Clock 50MHz
	input we_cpu,					// Tín hiệu cho phép CPU ghi dữ liệu vào buffer
	input [12:0] addr_cpu,		// Địa chỉ CPU muốn ghi vào buffer
	input [31:0] data_in_cpu,	// Dữ liệu CPU ghi vào Buffer
	
	// VGA Port
	input [12:0] addr_vga,		// Địa chỉ VGA muốn đọc dữ liệu từ Buffer
	output reg [31:0] data_out_vga
);

	// Buffer
	(* ramstyle = "M9K" *) 
	reg [31:0] mem [0:4799];
	
	// CPU WRITE
	
	always @(posedge clk) begin
		
		if (we_cpu) begin
			mem[addr_cpu] <= data_in_cpu;
		end
		
	end
	
	// VGA READ
	
	always @(posedge clk) begin
		
		data_out_vga <= mem[addr_vga];
		
	end

endmodule