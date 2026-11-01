// =========================================================
// Module TangNano20K_CORE
// + Module Top: Kết nối CORE với kit Tang Nano 20K
// + Clock 27 MHz từ thạch anh, đưa thẳng vào core (không dùng PLL)
// + UART qua mạch USB-UART có sẵn trên board
// + Đồng bộ reset về clock của core
// =========================================================

module TangNano20K_CORE (

	input clk,				// 27 MHz
	input rst,				// Nút S1 (chân 88), nhấn = 1

	// UART (mạch USB-UART trên board)
	input uart_rx,
	output uart_tx,

	output led_run			// LED trên board sáng (mức 0) khi CPU đang chạy
);

	localparam CLK_FREQ = 27_000_000;		// Phải khớp với clock thật vào CORE

	// =====================================
	// Reset
	// + Bật reset ngay khi nhấn rst
	// =====================================

	wire reset_req = rst;

	reg [1:0] reset_sync;

	always @(posedge clk or posedge reset_req) begin
		if (reset_req) begin
			reset_sync <= 2'b11;
		end

		else begin
			reset_sync <= {reset_sync[0], 1'b0};
		end
	end

	wire reset = reset_sync[1];

	// =====================================
	// CORE
	// + Tang Nano không có SW, HEX: SW = 0, HEX bỏ trống
	// + KEY = 2'b11 (không nhấn): reset đã xử lý ở trên
	// =====================================

	CORE #(
		.CLK_FREQ	(CLK_FREQ)
	) CORE_uut (
		.clk		(clk),
		.reset		(reset),
		.SW			(8'b0),
		.KEY		(2'b11),
		.LEDR		(),
		.uart_rx	(uart_rx),
		.uart_tx	(uart_tx),
		.HEX0		(),
		.HEX1		(),
		.HEX2		(),
		.HEX3		(),
		.HEX4		(),
		.HEX5		()
	);

	assign led_run = reset;		// reset = 0 --> chân xuống 0 --> LED sáng

endmodule
