// ==========================================
// Testbench Baud_Gen
// ==========================================

`timescale 1ns/1ps

module tb_Baud_Gen;
	
	parameter integer CLK_SYS		= 50_000_000;
	parameter integer BAUD_RATE	= 9600;
	parameter integer OVERSAMPLE	= 16;
	
	reg clk;
	reg reset;
	
	wire baud_tick;
	
	
	Baud_Gen #(
		.CLK_SYS		(CLK_SYS),
		.BAUD_RATE	(BAUD_RATE),
		.OVERSAMPLE	(OVERSAMPLE)
	)
	Baud_Gen_uut (
		.clk			(clk),
		.reset		(reset),
		.baud_tick	(baud_tick)
	);
	
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	initial begin
		reset = 1'b1;
		#100
		reset = 1'b0;
		
		#200_000
		$finish;
	end
	
endmodule