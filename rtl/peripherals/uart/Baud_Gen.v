// ======================================================
// Module Baud_Gen
// + Module lấy mẫu bit cho UART
// + Lấy mẫu 16 lần
// + Hạ thấp tần số của clock hệ thống
// ======================================================

module Baud_Gen #(

	parameter integer CLK_SYS 		= 50_000_000,	// Tần số clock đưa vào module (Hz)
	parameter integer BAUD_RATE	= 115200,
	parameter integer OVERSAMPLE	= 16				// Số lần lấy mẫu bit
)
(
	input clk,
	input reset,

	output reg baud_tick		// Xung kích hoạt UART (Tín hiệu enable để UART bắt đầu bộ đếm lấy mẫu)
);

	// ===================================================
	// Bộ chia phân số (accumulator)
	// + Mỗi clock cộng thêm BAUD_RATE * OVERSAMPLE
	// + Khi tổng >= CLK_SYS: phát 1 baud_tick và trừ đi CLK_SYS
	// --> Tần số baud_tick trung bình đúng bằng BAUD_RATE * OVERSAMPLE,
	//     kể cả khi CLK_SYS không chia hết
	//     (VD: 25 MHz / (115200 * 16) = 13.56, chia nguyên sẽ lệch 4.3%)
	// ===================================================

	localparam integer ACC_W = $clog2(CLK_SYS) + 1;

	localparam [ACC_W:0] TICK_INC	= BAUD_RATE * OVERSAMPLE;
	localparam [ACC_W:0] TICK_LIMIT	= CLK_SYS;

	reg [ACC_W:0] acc;

	wire [ACC_W:0] acc_next = acc + TICK_INC;

	// ===================================================
	// Baud Tick
	// ===================================================

	always @(posedge clk) begin

		if (reset) begin
			acc			<= {(ACC_W + 1){1'b0}};
			baud_tick	<= 1'b0;
		end

		else begin
			if (acc_next >= TICK_LIMIT) begin
				acc			<= acc_next - TICK_LIMIT;
				baud_tick	<= 1'b1;
			end

			else begin
				acc			<= acc_next;
				baud_tick	<= 1'b0;
			end

		end

	end

endmodule
