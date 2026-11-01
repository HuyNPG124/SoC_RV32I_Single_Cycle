// ===========================================
// Testbench UART_Tx
// Tạo baud_tick giả để mô phỏng tín hiệu
// ===========================================

`timescale 1ns/1ps

module tb_UART_Tx;
	
	parameter integer DATA_BITS 	= 8;
	parameter integer OVERSAMPLE 	= 16;
	
	reg clk;
	reg reset;
	reg baud_tick;
	reg [DATA_BITS - 1:0] data_in;
	reg i_send;
	
	wire tx;
	wire tx_ready;
	
	UART_Tx #(
		.DATA_BITS 	(DATA_BITS),
		.OVERSAMPLE (OVERSAMPLE)
	)
	UART_Tx_uut (
		.clk			(clk),
		.reset		(reset),
		.baud_tick	(baud_tick),
		.data_in		(data_in),
		.i_send		(i_send),
		.tx			(tx),
		.tx_ready	(tx_ready)
	);
	
	// Mô phỏng clock 50MHz
	
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	// Fake baud_tick
	initial begin
		baud_tick = 1'b0;	
		
		forever begin
			#320
			baud_tick = 1'b1;
			#20						// baud_tick tồn tại trong 1 chu kỳ clock (1T = 20ns)
			baud_tick = 1'b0;
		end
	end
	
	// Test case
	initial begin
		reset = 1'b1;
		i_send = 1'b0;
		data_in = 8'b0000_0000;
		
		#200
		reset = 1'b0;
		
		// Gửi byte 1
		data_in = 8'b1001_0010;
		i_send = 1'b1;
		
		#20
		i_send = 2'b0;
		wait (tx_ready == 1)
		
		#5000		// Đợi cờ báo UART_Tx rảnh để chuẩn bị gửi byte mới
		
		// Gửi byte 2
		data_in = 8'b1010_1010;
		i_send = 1'b1;
		
		#20
		i_send = 1'b0;
		wait (tx_ready == 1);
		
		#5000
		
		// Gửi byte 3
		data_in = 8'b1100_1100;
		i_send = 1'b1;
		
		#20
		i_send = 1'b0;
		wait (tx_ready == 1);
		
		#5000
		
		// Gửi byte 4
		data_in = 8'b1111_0000;
		i_send = 1'b1;
		
		#20
		i_send = 1'b0;
		wait (tx_ready == 1);
		
		#10000 $finish;
		
	end
	
endmodule