// =====================================
// Testbench  Data_RAM
// =====================================

`timescale 1ns/1ps

module tb_Data_RAM;
	reg clk;
	reg [31:0] addr;
	reg [31:0] wr_data;
	reg read_en;
	reg write_en;
	reg [3:0] byte_en;
	
	wire [31:0] rd_data;
	
	Data_RAM data_ram_uut (
		.clk (clk),
		.addr (addr),
		.wr_data (wr_data),
		.read_en (read_en),
		.write_en (write_en),
		.byte_en (byte_en),
		.rd_data (rd_data)
	);
	
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	initial begin
		// reset
		addr = 0;
		wr_data = 0;
		read_en = 0;
		write_en = 0;
		byte_en = 4'b1111;	// Ghi cả word (SW)
		
		// Test case 1: Write
		addr = 32'h0000_0023;
		wr_data = 32'h0001_ABCD;
		read_en = 0;
		write_en = 1;
		
		// Test case 2: Write
		#25
		addr = 32'h0000_0034;
		wr_data = 32'h0000_1234;
		read_en = 0;
		write_en = 1;
		
		// Test case 3: Read
		#15
		addr = 32'h0000_0023;
		read_en = 1;
		write_en = 0;
		
		// Test case 4: Read
		#15
		addr = 32'h0000_0034;
		read_en = 1;
		write_en = 0;
		
		// Test case 5: Write 
		#15
		addr = 32'h0000_0034;
		wr_data = 32'h0000_4567;
		read_en = 0;
		write_en = 1;
		
		// Test case 6: Read
		#15
		addr = 32'h0000_0034;
		read_en = 1;
		write_en = 0;
		
		#20 $finish;
	end
	
	
endmodule