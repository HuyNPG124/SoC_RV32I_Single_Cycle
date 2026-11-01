

`timescale 1ns/1ps

module tb_Rx_TOP;
	
	parameter CLK_SYS    = 50_000_000;
    parameter BAUD_RATE  = 9600;
    parameter DATA_BITS  = 8;
	parameter FIFO_WIDTH = 8;
	parameter FIFO_DEPTH = 32;
	
	localparam integer BIT_TIME = 1_000_000_000 / BAUD_RATE;
	
	reg clk;
	reg reset;
	reg rx_serial_in;
	reg fifo_rd_en;
	
	wire [DATA_BITS - 1:0] fifo_data_out;
	wire fifo_empty;
	wire fifo_full;
	wire rx_irq;
	
	// =========================
	// DUT
	// =========================
	Rx_TOP #(
		.CLK_SYS    (CLK_SYS),
		.BAUD_RATE  (BAUD_RATE),
		.DATA_BITS  (DATA_BITS),
		.FIFO_WIDTH (FIFO_WIDTH),
		.FIFO_DEPTH (FIFO_DEPTH)
	) uut (
		.clk            (clk),
		.reset          (reset),
		.rx_serial_in   (rx_serial_in),
		.fifo_rd_en     (fifo_rd_en),
		.fifo_data_out  (fifo_data_out),
		.fifo_empty     (fifo_empty),
		.fifo_full      (fifo_full),
		.rx_irq         (rx_irq)
	);
	
	// =========================
	// Clock
	// =========================
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	// =========================
	// UART SEND
	// =========================
	task send_byte(input [7:0] data);
		integer i;
		begin
			// START
			rx_serial_in = 0;
			#(BIT_TIME);
			
			// DATA
			for (i = 0; i < 8; i = i + 1) begin
				rx_serial_in = data[i];
				#(BIT_TIME);
			end
			
			// STOP
			rx_serial_in = 1;
			#(BIT_TIME);
			
			// IDLE
			#(BIT_TIME);
		end
	endtask
	
	// =========================
	// FIFO READ (QUAN TRỌNG)
	// =========================
	task fifo_read;
		begin
			@(posedge clk);
			fifo_rd_en = 1;
			
			@(posedge clk);
			fifo_rd_en = 0;
			
			// 🔥 đợi data valid
			@(posedge clk);
			
			$display("[%0t] READ = 0x%02h", $time, fifo_data_out);
		end
	endtask
	
	// =========================
	// TEST
	// =========================
	initial begin
		reset = 1;
		rx_serial_in = 1;
		fifo_rd_en = 0;
		
		#100;
		reset = 0;
		
		// =====================
		// SEND DATA
		// =====================
		send_byte(8'hF8);
		send_byte(8'hBD);
		send_byte(8'h8E);
		
		// =====================
		// ĐỢI FIFO có data
		// =====================
		wait (rx_irq == 1);
		
		#1000;
		
		// =====================
		// READ FIFO (giống CPU)
		// =====================
		while (!fifo_empty) begin
			fifo_read();
		end
		
		#10000;
		$stop;
	end
	
endmodule