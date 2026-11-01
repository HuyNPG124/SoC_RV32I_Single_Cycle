// ===================
// Version 2
// 31-03-2026
// ===================

module UART #(

	parameter CLK_SYS		= 50_000_000,
	parameter BAUD_RATE	= 115200,
	parameter DATA_BITS	= 8,
	parameter OVERSAMPLE	= 16,
	parameter FIFO_WIDTH	= 8,
	parameter FIFO_DEPTH	= 32
)(
	input clk,
	input reset,
	
	// UART Pins
	input rx,		// Tín hiệu CPU nhận được	<-- CP2102
	output tx,		// Tín hiệu CPU gửi đi --> CP2102
	
	// ====================
	// CPU Interface
	// ====================
	
	// Tx (CPU --> UART)
	input tx_wr_en, 							// Tín hiệu cho phép ghi vào FIFO
	input [DATA_BITS - 1:0] tx_data,		// Dữ liệu cần gửi đi 
	output tx_full,							// Cờ báo FIFO của Tx đầy
	
	// Rx (UART --> CPU)
	input rx_rd_en,							// Tín hiệu cho phép đọc dữ liệu trong FIFO của rx
	output [DATA_BITS - 1:0] rx_data,	// Dữ liệu CPU nhận được
	output rx_empty,							// Cờ báo FIFO Rx rỗng
	
	// Interrupt
	output rx_irq		// Cờ báo trong FIFO Rx vẫn còn dữ liệu chưa đọc
);


	// =======================================
	// BAUD GENERATOR
	// =======================================
	
	wire baud_tick;
	
	Baud_Gen #(
		.CLK_SYS		(CLK_SYS),
		.BAUD_RATE	(BAUD_RATE),
		.OVERSAMPLE	(OVERSAMPLE)
	) baud_gen (
		.clk			(clk),
		.reset		(reset),
		.baud_tick	(baud_tick)
	);
	
	
	// =======================================
	// TX PATH
	// =======================================
	
	wire [DATA_BITS - 1:0] tx_fifo_data;
	wire tx_fifo_empty;
	wire tx_ready;
	
	reg rd_en;
	reg i_send;
	reg [DATA_BITS - 1:0] tx_data_reg;
	
	// FIFO TX
	
	FIFO #(
		.W	(FIFO_WIDTH),
		.L (FIFO_DEPTH)
	) tx_fifo (
		.clk			(clk),
		.reset		(reset),
		.write_en	(tx_wr_en),
		.read_en		(rd_en),
		.data_in		(tx_data),
		.data_out	(tx_fifo_data),
		.empty		(tx_fifo_empty),
		.full			(tx_full)
	);
	
	// UART TX
	
	UART_Tx #(
		.DATA_BITS	(DATA_BITS),
		.OVERSAMPLE	(OVERSAMPLE)
	) uart_tx (
		.clk			(clk),
		.reset		(reset),
		.baud_tick	(baud_tick),
		.data_in		(tx_data_reg),
		.i_send		(i_send),
		.tx			(tx),
		.tx_ready	(tx_ready)
	);
	
	// CONTROL FSM TX
	
	localparam TX_IDLE = 0;
	localparam TX_READ = 1;
	localparam TX_WAIT = 2;
	localparam TX_SEND = 3;
	
	reg [1:0] tx_state;
	
	always @(posedge clk)
		begin
			
			if (reset) 
				begin
					tx_state		<= TX_IDLE;
					rd_en			<= 0;
					i_send		<= 0;
					tx_data_reg	<= 0;
				end
			
			else 
				begin
					rd_en 	<= 0;
					i_send	<= 0;
					
					case (tx_state)
					
						TX_IDLE:
							begin
								if (!tx_fifo_empty && tx_ready)
									begin
										rd_en		<= 1;
										tx_state	<= TX_READ;
									end
							end
							
						TX_READ:
							begin	
								tx_state <= TX_WAIT;
							end
							
						TX_WAIT:
							begin
								tx_data_reg	<= tx_fifo_data;
								tx_state		<= TX_SEND;
							end
							
						TX_SEND:
							begin
								if (tx_ready)
									begin
										i_send	<= 1;
										tx_state	<= TX_IDLE;
									end
							end
					
					endcase
				end
			
		end
			
	// =======================================
	// RX PATH
	// =======================================
	
	wire [DATA_BITS - 1:0] rx_data_wire;
	wire rx_valid;
	wire rx_full;
	
	// UART RX
	
	UART_Rx #(
		.DATA_BITS	(DATA_BITS),
		.OVERSAMPLE	(OVERSAMPLE)
	) uart_rx (
		.clk			(clk),
		.reset		(reset),
		.baud_tick	(baud_tick),
		.rx			(rx),
		.data_out	(rx_data_wire),
		.rx_valid	(rx_valid)
	);
	
	// FIFO RX
	
	FIFO #(
		.W (FIFO_WIDTH),
		.L (FIFO_DEPTH)
	) rx_fifo (
		.clk			(clk),
		.reset		(reset),
		.write_en	(rx_valid && !rx_full),
		.read_en		(rx_rd_en),
		.data_in		(rx_data_wire),
		.data_out	(rx_data),
		.empty		(rx_empty),
		.full			(rx_full)
	);
	
	
	// =============================
	// INTERRUPT
	// =============================
	
	assign rx_irq = !rx_empty;
	 
	
endmodule