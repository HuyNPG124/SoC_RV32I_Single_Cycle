// ===============================
// Testbench Regfile
// ===============================

`timescale 1ns/1ps

module tb_Regfile;
	reg clk;
	reg reset_n;
	reg write_en;
	reg [4:0] rs1_Add;
	reg [4:0] rs2_Add;
	reg [4:0] rd_Add;
	reg [31:0] wr_data;
	
	wire [31:0] rs_data1;
	wire [31:0] rs_data2;
	
	Regfile regfile_uut (
		.clk (clk),
		.reset_n (reset_n),
		.write_en (write_en),
		.rs1_Add (rs1_Add),
		.rs2_Add (rs2_Add),
		.rd_Add (rd_Add),
		.wr_data (wr_data),
		.rs_data1 (rs_data1),
		.rs_data2 (rs_data2)
	);
	
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	initial begin
		reset_n = 0;
		write_en = 0;
		wr_data = 32'h0000_0000;
		
		#15
		reset_n = 1;
		write_en = 1;
		
		// Test ghi dữ liệu
		// Test case 1
		wr_data = 32'h0000_1234;
		rd_Add = 5;
		
		// Test case 2
		#15
		wr_data = 32'h0000_4567;
		rd_Add = 7;
		
		// Test đọc dữ liệu từ thanh ghi nguồn
		// Test case 1
		#15
		write_en = 0;
		rs1_Add = 5;
		rs2_Add = 4;
		
		// Test case 2
		#15
		rs1_Add = 6;
		rs2_Add = 7;
		
		#20 $finish;
	end
	
endmodule