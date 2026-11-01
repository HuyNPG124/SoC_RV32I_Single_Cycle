//`timescale 1ns/1ps
//
//module tb_UART_Rx;
//
//	parameter DATA_BITS  = 8;
//	parameter OVERSAMPLE = 16;
//
//	localparam integer TICK_TIME = 320;
//	localparam integer BIT_TIME  = TICK_TIME * OVERSAMPLE;
//
//	reg clk;
//	reg reset;
//	reg baud_tick;
//	reg rx;
//
//	wire [DATA_BITS - 1:0] data_out;
//	wire rx_valid;
//
//	// =============================
//	// DUT
//	// =============================
//	UART_Rx #(
//		.DATA_BITS  (DATA_BITS),
//		.OVERSAMPLE (OVERSAMPLE)
//	)
//	UART_Rx_uut (
//		.clk        (clk),
//		.reset      (reset),
//		.baud_tick  (baud_tick),
//		.rx         (rx),
//		.data_out   (data_out),
//		.rx_valid   (rx_valid)
//	);
//
//	// =============================
//	// Clock
//	// =============================
//	initial begin		
//		clk = 0;
//		forever #10 clk = ~clk;
//	end
//
//	// =============================
//	// baud_tick
//	// =============================
//	initial begin
//		baud_tick = 0;	
//		forever begin
//			#(TICK_TIME)
//			baud_tick = 1;
//			#20
//			baud_tick = 0;
//		end
//	end
//
//	// =============================
//	// TASK: gửi 1 byte UART
//	// =============================
//	task send_byte(input [7:0] data);
//	integer i;
//	begin
//		// START
//		rx = 0;
//		#(BIT_TIME);
//
//		// DATA (LSB first)
//		for (i = 0; i < 8; i = i + 1) begin
//			rx = data[i];
//			#(BIT_TIME);
//		end
//
//		// STOP
//		rx = 1;
//		#(BIT_TIME);
//
//		// idle giữa frame
//		#(BIT_TIME);
//	end
//	endtask
//
//	// =============================
//	// TEST
//	// =============================
//	initial begin
//		reset = 1;
//		rx    = 1;   // idle
//
//		#200;
//		reset = 0;
//
//		// Gửi 3 byte
//		send_byte(8'hAA);
//		send_byte(8'hE7);
//		send_byte(8'hC3);
//
//		#5000;
//		$finish;
//	end
//
//	// =============================
//	// Monitor
//	// =============================
//	always @(posedge rx_valid) begin
//		$display("Time=%0t | RX=%h (%b)", $time, data_out, data_out);
//	end
//
//endmodule


`timescale 1ns/1ps

module tb_UART_Rx;

    parameter DATA_BITS  = 8;
    parameter OVERSAMPLE = 16;

    localparam integer TICK_TIME = 320;

    reg clk;
    reg reset;
    reg baud_tick;
    reg rx;

    wire [DATA_BITS-1:0] data_out;
    wire rx_valid;

    // =============================
    // DUT
    // =============================
    UART_Rx #(
        .DATA_BITS  (DATA_BITS),
        .OVERSAMPLE (OVERSAMPLE)
    ) UART_Rx_uut (
        .clk        (clk),
        .reset      (reset),
        .baud_tick  (baud_tick),
        .rx         (rx),
        .data_out   (data_out),
        .rx_valid   (rx_valid)
    );

    // =============================
    // CLOCK 50MHz
    // =============================
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // =============================
    // BAUD TICK (pulse 1 cycle)
    // =============================
    initial begin
        baud_tick = 0;
        forever begin
            #(TICK_TIME) baud_tick = 1;
            #20          baud_tick = 0;
        end
    end

    // =============================
    // TASK: chờ N baud_tick
    // =============================
    task wait_ticks(input integer n);
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge baud_tick);
        end
    endtask

    // =============================
    // TASK: gửi 1 byte UART (CHUẨN)
    // =============================
    task send_byte(input [7:0] data);
        integer i;
        begin
            $display("[%0t] SEND = 0x%02h", $time, data);

            // START
            rx = 0;
            wait_ticks(OVERSAMPLE);

            // DATA (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                wait_ticks(OVERSAMPLE);
            end

            // STOP
            rx = 1;
            wait_ticks(OVERSAMPLE);

            // IDLE (rất quan trọng)
            wait_ticks(OVERSAMPLE);
        end
    endtask

    // =============================
    // MONITOR realtime
    // =============================
    initial begin
        $display("===== UART RX TEST START =====");
        $monitor("[%0t] rx=%b | data_out=0x%02h | valid=%b",
                  $time, rx, data_out, rx_valid);
    end

    // =============================
    // RX VALID MONITOR
    // =============================
    always @(posedge rx_valid) begin
        $display(">>> [%0t] RX DONE: 0x%02h (%b)",
                  $time, data_out, data_out);
    end

    // =============================
    // TEST SEQUENCE
    // =============================
    initial begin
        reset = 1;
        rx    = 1;   // idle

        #200;
        reset = 0;

        // Gửi nhiều byte
        send_byte(8'hAA);
        send_byte(8'hE7);
        send_byte(8'hC3);
        send_byte(8'h55);
        send_byte(8'h00);

        // đợi xử lý xong
        wait_ticks(50);

        $display("===== TEST DONE =====");
        #1000;
        $finish;
    end

endmodule