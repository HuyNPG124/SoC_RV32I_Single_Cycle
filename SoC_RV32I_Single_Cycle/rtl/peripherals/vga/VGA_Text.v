// =======================================================
// Module VGA_Text
// + Cấu hình Text theo Font chữ
// + text buffer + font + pixel position --> RGB pixel
// =======================================================

module VGA_Text (

	input clk,
	input pixel_tick,
	input video_on,
	input [9:0] x,
	input [9:0] y,
	
	input [3:0] font_w,
	input [4:0] font_h,
	
	// Text Buffer
	input [31:0] text_data,
	output reg [12:0] text_addr,
	
	// Font
	input [7:0] font_data,
	output reg [12:0] font_addr,
	
	// RGB
	output reg [3:0] R,
	output reg [3:0] G,
	output reg [3:0] B
);
	// =====================================================
	// Vị trí của ký tự tính theo grid (80x30)
	// + Tính toán pixel đang ở ô grid nào trên màn hình
	// =====================================================
	
	reg [3:0] shift_x;	// Sử dụng shift thay cho phép /
	reg [3:0] shift_y;
	//reg [9:0] cols;		// Số cột (grid) 
	
	always @(*) begin
	
		// Độ rộng 1 ký tự
		case (font_w)
			
			8: shift_x	= 3;
			
			16: shift_x	= 4;
			
			default: shift_x	= 3;
		endcase
		
		// Độ cao 1 ký tự
		case (font_h)
		
			8:
			begin
				shift_y	= 3;
			end
			
			16:
			begin
				shift_y 	= 4;
			end
			
			default:
			begin
				shift_y	= 4;
			end
		
		endcase
		
	end
	
	
	// =========================================================
	// Vị trí của 1 pixel ở trong 1 ô ký tự (grid)
	// + Dùng để xác định pixel trong ô grid đó có bật hay không
	// + Hiển thị chữ, chọn màu
	//
	// ---------------------------------------------------------
	// Dùng shift thay cho phép %
	// =========================================================
	
	reg [9:0] char_x_reg;
	reg [9:0] char_y_reg;
	
	reg [4:0] row_reg;
	reg [4:0] col_reg;
	
	always @(posedge clk) begin
	
		if (pixel_tick) begin
			// Xác định pixel thuộc grid nào trên màn hình
			char_x_reg <= x >> shift_x;
			char_y_reg <= y >> shift_y;
			
			// Vị trí của 1 pixel ở trong 1 ô ký tự (grid)
			row_reg <= y & ((1 << shift_y) - 1);
			col_reg <= x & ((1 << shift_x) - 1);
		end
		
	end
	
	
	// =========================================================
	// Địa chỉ của ký tự trong buffer
	// + mem trong buffer được lưu lần lượt theo từng hàng
	// + addr: tính vị trí theo hàng nào, cột bao nhiêu (grid)
	// =========================================================
	
	always @(posedge clk) begin
		
		if (pixel_tick) begin
			case (font_w)
				// cols = 80 = 64 + 16
				8: text_addr <= (char_y_reg << 6) + (char_y_reg << 4) + char_x_reg;
				
				// cols = 40 = 32 + 8
				16: text_addr <= (char_y_reg << 5) + (char_y_reg << 3) + char_x_reg;
				
				default:
					text_addr <= (char_y_reg << 6) + (char_y_reg << 4) + char_x_reg;
			endcase
		end
		
	end
	
	
	// =========================================================
	// Extract data
	// + Data đầu vào là dữ liệu cấu hình trong firmware
	// VGA(FG, BG, 'ASCII');
	// + Ví dụ: VGA[0] = VGA_CHAR('A', RGB(15,0,0), RGB(0,0,0));
	// + Xác định ký tự, màu của ký tự, màu nền
	// =========================================================
	
	reg [7:0] ascii_reg;
	reg [11:0] bg_reg;		// Background color
	reg [11:0] fg_reg;		// Font color
	
	always @(posedge clk) begin
	
		if (pixel_tick) begin
			ascii_reg 	<= text_data[7:0];
			bg_reg 		<= text_data[19:8];
			fg_reg		<= text_data[31:20];
		end
		
	end
	
	
	// =========================================================
	// Font address
	// =========================================================
	
	always @(posedge clk) begin
		
		if (pixel_tick) begin
			case (font_h)
				// 8 = 2^3
				8: font_addr <= (ascii_reg << 3) + row_reg;
				
				// 16 = 2^4
				16: font_addr <= (ascii_reg << 4) + row_reg;
				
				default: font_addr <= (ascii_reg << 4) + row_reg;
			endcase
		end
		
	end
	
	
	// =========================================================
	// Pixel Select
	// + Kiểm tra xem pixel đó có bật hay không
	// + Độc pixel theo từng cột trong hàng của 1 ký tự
	// + font_data gửi sang sẽ là từng hàng của 1 ô ký tự
	// =========================================================
	
	reg pixel_on_reg;
	
	always @(posedge clk) begin
	
		if (pixel_tick) begin
			pixel_on_reg <= font_data[7 - col_reg];
		end
	
	end
	
	
	// =========================================
	// RGB Output
	// =========================================
	
	reg [11:0] rgb_reg;
	
	always @(posedge clk) begin
		
		if (pixel_tick) begin
			rgb_reg <= pixel_on_reg ? fg_reg : bg_reg;
		end
		
	end
	
	
	always @(posedge clk) begin
		
		if (pixel_tick) begin
			if (video_on) begin
				R <= rgb_reg[11:8];
				G <= rgb_reg[7:4];
				B <= rgb_reg[3:0];
			end
			
			else begin
				R <= 0;
				G <= 0;
				B <= 0;
			end
		end
		
	end


endmodule