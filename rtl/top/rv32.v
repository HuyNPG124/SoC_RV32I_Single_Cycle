// =========================================================
// Module Cyclone4_CORE
// + Module Top: Kết nối CORE với kit Cyclone IV EP4CE6E22C8N
// + Clock 50 MHz từ thạch anh
// + UART qua module USB-UART ngoài (CP2102/CH340) nối vào header
// + Đồng bộ reset về clock của core
// =========================================================

module rv32 #(
	parameter DIV2 = 0		// 0: core chạy 50 MHz, 1: core chạy 25 MHz (nếu 50 MHz không đạt timing)
)(

	input  clk,				// 50 MHz
	input  rst_n,			// Phím reset, nhấn = 0

	// UART (module USB-UART ngoài)
	input  uart_rx,			// nối vào TXD của module USB-UART
	output uart_tx,			// nối vào RXD của module USB-UART

	// INMP441 I2S
	input  inmp441_sd,
	output inmp441_sck,
	output inmp441_ws,

	output led_run			// LED trên board sáng (mức 0) khi CPU đang chạy
);

	// =====================================
	// Clock cho core
	// =====================================

	localparam CLK_FREQ = DIV2 ? 25_000_000 : 50_000_000;	// Phải khớp với clock thật vào CORE

	wire core_clk;

	generate
		if (DIV2) begin : g_div2
			reg clk_div = 1'b0;

			always @(posedge clk) begin
				clk_div <= ~clk_div;
			end

			assign core_clk = clk_div;
		end

		else begin : g_direct
			assign core_clk = clk;
		end
	endgenerate

	// =====================================
	// Reset
	// + Phím active-low --> đảo thành active-high cho core
	// + Nhấn: reset ngay (async), nhả: đồng bộ về core_clk
	// =====================================

	wire reset_req = ~rst_n;

	reg [1:0] reset_sync = 2'b11;

	always @(posedge core_clk or posedge reset_req) begin
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
	// + Không dùng SW, HEX: SW = 0, HEX bỏ trống
	// + KEY = 2'b11 (không nhấn): reset đã xử lý ở trên
	// =====================================

	CORE #(
		.CLK_FREQ	(CLK_FREQ)
	) CORE_uut (
		.clk		(core_clk),
		.reset		(reset),
		.SW			(8'b0),
		.KEY		(2'b11),
		.LEDR		(),
		.uart_rx	(uart_rx),
		.uart_tx	(uart_tx),
		.inmp441_sd		(inmp441_sd),
		.inmp441_sck	(inmp441_sck),
		.inmp441_ws		(inmp441_ws),
		.HEX0			(),
		.HEX1		(),
		.HEX2		(),
		.HEX3		(),
		.HEX4		(),
		.HEX5		()
	);

	assign led_run = reset;		// reset = 0 --> chân xuống 0 --> LED sáng

endmodule