// ===================================================
// VGA
// Module VGA_Control
// + Điều khiển các tín hiệu màn hình VGA
// ===================================================

module VGA_Control (

	input clk,				// Clock hệ thống 50MHz
	input reset,
	
	output video_on,		// Tín hiệu báo đang trong vùng hiển thị hình ảnh của màn hình
	output hsync,			// Tín hiệu báo đã hết một dòng màn hình (Quay về vị trí đầu tiên của dòng tiếp theo)
	output vsync,			// Tín hiệu báo truyền hết một frame (Quay về vị trí (0, 0)
	output pixel_tick,	// Tín hiệu cho phép hoạt động pixel tiếp theo
	output [9:0] x,		// Vị trí pixel trên màn hình theo chiều ngang
	output [9:0] y 		// Vị trí pixel trên màn hình theo chiều dọc
	
);

	// =====================================
	// Kích thước một frame màn hình
	// + Kích thước màn hình: 640x480
	// + Tần số quét: 60Hz
	// =====================================
	
	parameter HD	= 640;		// Display
	parameter HF	= 16;			// Front Porch
	parameter HS	= 96;			// H Sync
	parameter HB	= 48;			// Back Porch
	parameter HMAX	= HD + HF + HS + HB - 1;	// Kích thước một frame theo chiều ngang
	
	parameter VD	= 480;		// Display
	parameter VF	= 10;			// Front Porch
	parameter VS	= 2;			// V Sync
	parameter VB	= 33;			// Back Porch
	parameter VMAX	= VD + VF + VS + VB - 1;	// Kích thước một frame theo chiều dọc
	
	
	// =====================================
	// Tạo pixel tick 25MHz từ 50MHz
	// + Tạo tần số 60Hz
	// =====================================
	
	reg pixel_reg;
	
	always @(posedge clk or posedge reset) begin
		if (reset)
			begin
				pixel_reg <= 0;
			end
			
		else
			begin
				pixel_reg <= ~pixel_reg;		// Chia 2 tần số clock 50MHz
			end
	end
	
	assign pixel_tick = pixel_reg;
	
	
	// =====================================
	// Horizonal & Vertical counters
	// =====================================
	
	reg [9:0] h_count_reg;
	reg [9:0] v_count_reg;
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			h_count_reg <= 0;
			v_count_reg <= 0;
		end
		
		else if (pixel_tick) begin
			// Horizonal counter
			if (h_count_reg == HMAX) begin
				h_count_reg <= 0;
				
				// Verical counter
				if (v_count_reg == VMAX) begin
					v_count_reg <= 0;
				end
				
				else begin
					v_count_reg <= v_count_reg + 1;
				end
				
			end
			
			else begin
				h_count_reg <= h_count_reg + 1;
			end
		end
	end
	
	
	// ======================================
	// HSYNC & VSYNC (Active LOW)
	// ======================================
	
	assign hsync = ~((h_count_reg >= (HD + HF)) && (h_count_reg < (HD + HF + HS)));
	
	assign vsync = ~((v_count_reg >= (VD + VF)) && (v_count_reg < (VD + VF + VS)));
	
	
	// =====================================
	// Video ON
	// =====================================
	
	assign video_on = (h_count_reg < HD) && (v_count_reg < VD);
	
	// =====================================
	// Output Position
	// + Tọa độ pixel trên màn hình
	// =====================================
	
	assign x = h_count_reg;
	assign y = v_count_reg;
	
endmodule