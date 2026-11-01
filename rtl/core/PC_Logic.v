// =======================================
// 
// =======================================

module PC_Logic (

	input [31:0] pc_current,
	input [31:0] imm,
	input [31:0] rs1_data,
	
	input PCSel,
	input is_jalr,
	//input is_jal,
	//input is_branch,
	
	output [31:0] pc_next
	
);

	wire [31:0] pc_plus4;
	wire [31:0] pc_branch;
	wire [31:0] pc_jalr;
	
	// PC + 4
	assign pc_plus4 = pc_current + 4;
	
	// PC + imm (Branch / Jal)
	assign pc_branch = pc_current + imm;
	
	// rs1 + imm
	assign pc_jalr = (rs1_data + imm) & ~32'b1;

	assign pc_next = (is_jalr) ? pc_jalr : 
					 (PCSel)   ? pc_branch:
								 pc_plus4;
	
endmodule