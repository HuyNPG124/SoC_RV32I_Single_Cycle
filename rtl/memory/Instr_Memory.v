// ====================================
//	Module Instruction Memory
// + Lưu trữ chương trình (firmware)
// + ROM nằm trong M9K (đọc đồng bộ)
//
// *Cách dùng trong core đơn chu kỳ:
// + addr nối với địa chỉ của lệnh KẾ TIẾP (pc_next)
// + Tại cạnh clock PC nhận pc_next, ROM cũng chốt pc_next
// --> instruction luôn là mem[PC] trong suốt chu kỳ
// ====================================

module Instr_Memory #(
	parameter INIT_FILE = "firmware/firmware.hex"
) (
	input clk,
	input [31:0] addr,						// Địa chỉ lệnh kế tiếp (pc_next)
	output reg [31:0] instruction		// Lệnh tại PC hiện tại
);

	(* romstyle = "M9K" *) reg [31:0] mem [0:1023];		// Bộ nhớ lưu firmware

	// Load firmware
	initial begin
		$readmemh(INIT_FILE, mem);
	end

	always @(posedge clk) begin
		instruction <= mem[addr[11:2]];
	end

endmodule
