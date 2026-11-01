// ===============================================
// Testbench VGA Control
// ===============================================

`timescale 1ns/1ps

module tb_VGA_Control;

	reg clk;
	reg reset;
	
	wire video_on;
	wire hsync;
	wire vsync;
	wire pixel_tick;
	wire [9:0] x;
	wire [9:0] y;
	
	VGA_Control VGA_Control_uut (
		.clk			(clk),
		.reset		(reset),
		.video_on	(video_on),
		.hsync		(hsync),
		.vsync		(vsync),
		.pixel_tick	(pixel_tick),
		.x				(x),
		.y				(y)
	);
	
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	initial begin
		reset = 1;
		
		#100
		reset = 0;
		
		// Load 2 frame
		repeat (2) begin
			wait(vsync == 1);
			wait(vsync == 0);
		end
		
		$finish;
		
	end
	
endmodule