// ===========================================
// Module FPGA_Test
// + Test các module UART
// ===========================================

module FPGA_Test (
	input CLOCK_50,
	input KEY0,
	input [7:0] SW,
	input SW9,
	output GPIO0
);

	localparam CLK_SYS		= 50_000_000;
	localparam BAUD_RATE	= 9600;
	localparam DATA_BITS	= 8;
	localparam OVERSAMPLE	= 16;
	localparam FIFO_WIDTH	= 8;
	localparam FIFO_DEPTH	= 32;
	
	Tx_TOP #(
		.CLK_SYS (CLK_SYS),
		.BAUD_RATE (BAUD_RATE),
		.DATA_BITS (DATA_BITS),
		.OVERSAMPLE (OVERSAMPLE),
		.FIFO_WIDTH (FIFO_WIDTH),
		.FIFO_DEPTH (FIFO_DEPTH)
	) tx_top (
		.clk (CLOCK_50),
		.reset (KEY0),
		.tx_data_in (SW),
		.fifo_tx_wr_en (SW9),
		.tx (GPIO0)
	);
	
endmodule