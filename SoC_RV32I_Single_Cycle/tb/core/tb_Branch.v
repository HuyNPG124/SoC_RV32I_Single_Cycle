// ==============================================
// Testbench Branch
// ==============================================
`timescale 1ns/1ps

module tb_Branch;
	reg [31:0]	A;
	reg [31:0]	B;
	reg			BrUn;
	wire			BrLT;
	wire 			BrEQ;
	
	Branch branch_uut (
		.A (A),
		.B (B),
		.BrUn (BrUn),
		.BrLT (BrLT),
		.BrEQ (BrEQ)
	);
	
	initial begin
		// Test case 1 (unsigned)
		BrUn = 1'b1;
		A = 32'h0000_0004;
		B = 32'h0000_0009;
		
		#10
		A = 32'h0000_0005;
		B = 32'h0000_0005;
		
		#10
		A = -32'h0000_0004;
		B = -32'h0000_0009;
		
		//Test case 2 (signed)
		#10
		A = 32'h0000_0004;
		B = 32'h0000_0009;
		
		#10
		A = 32'h0000_0005;
		B = 32'h0000_0005;
		
		#10
		A = -32'h0000_0004;
		B = -32'h0000_0009;
		
		#10 $finish;
		
	end
endmodule 