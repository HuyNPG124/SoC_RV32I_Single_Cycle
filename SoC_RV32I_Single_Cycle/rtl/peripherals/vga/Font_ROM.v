// ========================================================================
// Module Font_ROM
// + Bộ Font ASCII cho VGA
// + Kích thước ký tự: 8x8 pixel
// + Màn hình 640x480: Hiển thị 60 dòng, 80 cột
// 
// ------------------------------------------------------------------------
// Font ROM có thể nâng cấp: Sử dụng nhiều font
// + Upload font qua Bootloader
// + Tùy chỉnh font trong firmware
// + Chỉ có font chữ, không có màu
//
// -------------------------------------------------------------------------
// Các tín hiệu CPU;
// + Dùng cho bộ Bootloader
// + Font chữ sẽ được ghi vào RAM thông qua việc ghi từ CPU vào RAM
// + Khi có tín hiệu enable thì tín hiệu mới được ghi qua CPU
// 
// -------------------------------------------------------------------------
// Các tín hiệu VGA:
// + Ghi trực tiếp file font chữ, không thể thay đổi tùy chỉnh font chữ
// + Khi ở trạng thái VGA, tín hiệu enable sẽ tắt
// + Chỉ dùng font chữ cố định
// =========================================================================

module Font_ROM (
	
	// CPU PORT
	input clk,					// Clock 50MHz
	input we_cpu,					// tín hiệu enable cho phép CPU ghi dữ liệu font vào RAM
	input [12:0] addr_cpu,		// Địa chỉ ký tự ASCII cần đọc
	input [7:0] data_in_cpu,	// Dữ liệu font ghi vào RAM thông qua CPU
	
	// VGA PORT
	input [12:0] addr_vga,
	output reg [7:0] data_out_vga
);
	(* ramstyle = "M9K" *) 
	reg [7:0] mem [0:4095];	// Có 4096 ký tự ASCII trong bộ Font
	
	// ===========================================
	// Load dữ liệu font cố định
	// + Bỏ phần này khi sử dụng Bootloader
	// ===========================================
	
	initial begin
		$readmemh ("font8x16.hex", mem);
	end
	
	// ===========================================
	// Ghi dữ liệu Font qua CPU vào RAM
	// + Khi ghi qua CPU, enable bật
	// ===========================================
	
	always @(posedge clk) begin
	
		if (we_cpu) begin
			mem[addr_cpu] <= data_in_cpu;
		end
		
	end
	
	// ===========================================
	// Ghi dữ liệu font chữ cố định
	// ===========================================
	
	always @(posedge clk) begin
	
		data_out_vga <= mem[addr_vga];
		
	end

endmodule