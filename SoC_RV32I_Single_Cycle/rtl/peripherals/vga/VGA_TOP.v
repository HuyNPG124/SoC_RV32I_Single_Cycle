// =====================================================
// Module VGA_TOP
// + Ghép thành bộ VGA hoàn chỉnh
// =====================================================

module VGA_TOP (

	input clk,
	input reset,
	input [31:0] cpu_addr,		// Địa chỉ CPU truy cập vào trong Memory của hệ thống, quyết định dữ liệu của VGA đi vào module nào
	input [31:0] cpu_data,		// Dữ liệu mà CPU muốn ghi vào VGA
	input cpu_we,					// Tín hiệu cho phép CPU ghi
	
	output [3:0] VGA_R,
	output [3:0] VGA_G,
	output [3:0] VGA_B,
	output VGA_HS,
	output VGA_VS
);

	// ============================================
	// Địa chỉ từng vùng của VGA trong Memory map
	// ============================================
	
	parameter VGA_BASE	= 32'h2000_0000;	// Vùng chứa Text buffer (VGA_RAM)
	parameter FONT_BASE	= 32'h2100_0000;	// Vùng chứa font data (Font_ROM)
	parameter CTRL_ADDR	= 32'h2200_0000;	// Thanh ghi điều khiển (font size)
	
	
	// ====================================================
	// Select signal
	// + Dùng để so sánh địa chỉ
	// + Phân vùng địa chỉ cho các khối VGA
	//
	// ----------------------------------------------------
	// is_vga: Thuộc vùng buffer
	// + Có 80x60 (Kích thước lớn nhất cho font 8x8)
	// + Mỗi data là 32bit --> 4 byte
	// 
	// ----------------------------------------------------
	// is_font: Vùng chứa font data
	// + 4096: Có 4096 ký tự của font
	// ====================================================
	
	wire is_vga 	= ((cpu_addr >= VGA_BASE) && (cpu_addr < VGA_BASE + (4800 * 4)));
	wire is_font	= ((cpu_addr >= FONT_BASE) && (cpu_addr < FONT_BASE + 4096));
	wire is_ctrl	= (cpu_addr == CTRL_ADDR);
	
	
	// =====================================
	// VGA Timing
	// =====================================
	
	wire video_on;
	
	wire pixel_tick;
	
	wire hsync;
	wire vsync;
	
	wire [9:0] x;
	wire [9:0] y;
	
	VGA_Control vga_control (
		.clk			(clk),
		.reset		(reset),
		.video_on	(video_on),
		.hsync		(hsync),
		.vsync		(vsync),
		.pixel_tick	(pixel_tick),
		.x				(x),
		.y				(y)
	);
	
	
	// ====================================
	// Chọn Font chữ
	// ====================================
	
	wire [3:0] font_w;
	wire [4:0] font_h;
	
	wire we_control_font = cpu_we && is_ctrl;
	
	VGA_Ctrl_Reg control_font (
		.clk			(clk),
		.reset		(reset),
		.we			(we_control_font),
		.data_in		(cpu_data),
		.font_w		(font_w),
		.font_h		(font_h)
	);
	
	
	// ===================================
	// Text Buffer
	// ===================================
	
	wire [12:0] addr_text_buffer = (cpu_addr - VGA_BASE) >> 2;		// Chhuyển địa chỉ từ bit --> word (chia 4)
	wire we_text_buffer = cpu_we && is_vga;
	
	wire [12:0] text_addr;
	
	wire [31:0] text_data;
	
	VGA_RAM text_buffer (
		.clk				(clk),
		.we_cpu			(we_text_buffer),
		.addr_cpu		(addr_text_buffer),
		.data_in_cpu	(cpu_data),
		
		.addr_vga		(text_addr),
		.data_out_vga	(text_data)
	);
	
	
	// ==================================
	// FONT ROM
	// + Font chữ hiển thị của VGA
	// ==================================
	
	wire [7:0] font_data;
	wire [12:0] font_addr;
	
	wire we_font = cpu_we && is_font;
	
	wire [12:0] addr_font = (cpu_addr - FONT_BASE);
	
	Font_ROM font_rom (
		.clk				(clk),
		.we_cpu			(we_font),
		.addr_cpu		(addr_font),
		.data_in_cpu	(cpu_data[7:0]),
		
		.addr_vga		(font_addr),
		.data_out_vga	(font_data)
	);
	
	
	// ==================================
	// VGA Text
	// ==================================
	
	wire [3:0] r;
	wire [3:0] g;
	wire [3:0] b;
	
	VGA_Text vga_text (
		.clk				(clk),
		.pixel_tick		(pixel_tick),
		.video_on		(video_on),
		.x					(x),
		.y					(y),
		
		.font_w			(font_w),
		.font_h			(font_h),
		
		.text_data		(text_data),
		.text_addr		(text_addr),
		
		.font_data		(font_data),
		.font_addr		(font_addr),
		
		.R					(r),
		.G					(g),
		.B					(b)
	);
	
	
	// =================================
	// Delay Timing
	// =================================
	
	wire video_on_d;
	
	wire hsync_d;
	wire vsync_d;
	
	VGA_Signal_Delay #(.DEPTH(6)) delay_unit (
		.clk				(clk),
		.reset			(reset),
		.pixel_tick		(pixel_tick),
		
		.video_on_in	(video_on),
		.hsync_in		(hsync),
		.vsync_in		(vsync),
		
		.video_on_out	(video_on_d),
		.hsync_out		(hsync_d),
		.vsync_out		(vsync_d)
	);
	
	
	// =================================
	// FINAL OUTPUT
	// =================================
	
	assign VGA_R = video_on_d ? r : 4'h0;
	assign VGA_G = video_on_d ? g : 4'h0;
	assign VGA_B = video_on_d ? b : 4'h0;
	
	assign VGA_HS = hsync_d;
	assign VGA_VS = vsync_d;
	
endmodule