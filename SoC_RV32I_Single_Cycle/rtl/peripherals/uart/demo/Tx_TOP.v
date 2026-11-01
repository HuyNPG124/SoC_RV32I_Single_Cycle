//// ======================================================
//// Module Tx_TOP
//// + Kết hợp Baud_gen + Tx + FIFO
//// + CPU --> FIFO_Tx --> UART_Tx
//// + Module dùng để kiểm tra chức năng của Tx tổng hợp
//// ======================================================
//
//module Tx_TOP #(
//
//	parameter CLK_SYS		= 50_000_000,
//	parameter BAUD_RATE	= 9600,
//	parameter DATA_BITS	= 8,
//	parameter OVERSAMPLE	= 16,
//	parameter FIFO_WIDTH	= 8,
//	parameter FIFO_DEPTH	= 32
//)
//(
//	input clk,
//	input reset,
//	input [DATA_BITS - 1:0] fifo_data_in,
//	input fifo_wr_en,
//	
//	output tx_serial_out
//);
//
//	wire baud_tick;
//	
//	Baud_Gen #(
//		.CLK_SYS		(CLK_SYS),
//		.BAUD_RATE	(BAUD_RATE),
//		.OVERSAMPLE	(OVERSAMPLE)
//	) baud_gen_test (
//		.clk			(clk),
//		.reset		(reset),
//		.baud_tick	(baud_tick)
//	);
//
//	wire fifo_empty;
//	wire fifo_full;
//	
//	wire [DATA_BITS - 1:0] data_out_fifo;
//	
//	wire tx_ready;
//	wire not_empty;
//	
//	assign not_empty = ~fifo_empty;
//	
//	wire rd_en;
//	
//	// ===========================
//	// HANDSHAKE
//	// ===========================
//	wire send_req;
//	assign send_req = tx_ready && !fifo_empty;
//	
//	reg send_req_d;
//	reg [DATA_BITS - 1:0] tx_data_reg;
//	
//	always @(posedge clk) begin
//		if (reset) begin
//			send_req_d <= 0;
//			tx_data_reg <= 0;
//		end
//		
//		else begin
//			send_req_d <= send_req;
//			
//			if (send_req) begin
//				tx_data_reg <= data_out_fifo;
//			end
//		end
//	end
//	
//	assign rd_en = send_req;
//	
//	FIFO #(
//		.W (FIFO_WIDTH),
//		.L (FIFO_DEPTH)
//	) tx_fifo_test (
//		.clk			(clk),
//		.reset		(reset),
//		.wr_en		(fifo_wr_en),
//		//.rd_en		(tx_ready),
//		.rd_en		(rd_en),
//		.wr_data		(fifo_data_in),
//		.rd_data		(data_out_fifo),
//		.empty		(fifo_empty),
//		.full			(fifo_full)
//	);
//	
//	UART_Tx #(
//		.DATA_BITS	(DATA_BITS),
//		.OVERSAMPLE	(OVERSAMPLE)
//	) uart_tx_test (
//		.clk			(clk),
//		.reset		(reset),
//		.baud_tick	(baud_tick),
//		//.data_in		(data_out_fifo),
//		.data_in		(tx_data_reg),
//		//.i_send		(not_empty),
//		.i_send 		(send_req_d),
//		.tx			(tx_serial_out),
//		.tx_ready	(tx_ready)
//	);
//
//
//
//endmodule

// Version 2: 30-03-2026
module Tx_TOP #(
    parameter CLK_SYS     = 50_000_000,
    parameter BAUD_RATE   = 9600,
    parameter DATA_BITS   = 8,
    parameter OVERSAMPLE  = 16,
    parameter FIFO_WIDTH  = 8,
    parameter FIFO_DEPTH  = 32
)(
    input clk,
    input reset,
    input [DATA_BITS-1:0] fifo_data_in,
    input fifo_wr_en,

    output tx_serial_out
);

    // =========================
    // Baud Generator
    // =========================
    wire baud_tick;

    Baud_Gen #(
        .CLK_SYS    (CLK_SYS),
        .BAUD_RATE  (BAUD_RATE),
        .OVERSAMPLE (OVERSAMPLE)
    ) baud_gen (
        .clk       (clk),
        .reset     (reset),
        .baud_tick (baud_tick)
    );

    // =========================
    // FIFO
    // =========================
    wire fifo_empty;
    wire fifo_full;
    wire [DATA_BITS-1:0] data_out_fifo;

    reg rd_en;

    FIFO #(
        .W (FIFO_WIDTH),
        .L (FIFO_DEPTH)
    ) tx_fifo (
        .clk       (clk),
        .reset     (reset),
        .write_en  (fifo_wr_en),
        .read_en   (rd_en),
        .data_in   (fifo_data_in),
        .data_out  (data_out_fifo),
        .empty     (fifo_empty),
        .full      (fifo_full)
    );

    // =========================
    // UART TX
    // =========================
    wire tx_ready;

    reg i_send;
    reg [DATA_BITS-1:0] tx_data_reg;

    UART_Tx #(
        .DATA_BITS  (DATA_BITS),
        .OVERSAMPLE (OVERSAMPLE)
    ) uart_tx (
        .clk        (clk),
        .reset      (reset),
        .baud_tick  (baud_tick),
        .data_in    (tx_data_reg),
        .i_send     (i_send),
        .tx         (tx_serial_out),
        .tx_ready   (tx_ready)
    );

    // =========================
    // CONTROL FSM (FIXED)
    // =========================
    localparam IDLE  = 0;
    localparam READ  = 1;
    localparam WAIT  = 2;
    localparam SEND  = 3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            rd_en       <= 0;
            i_send      <= 0;
            tx_data_reg <= 0;
        end else begin

            // default
            rd_en  <= 0;
            i_send <= 0;

            case (state)

                // ================= IDLE =================
                IDLE: begin
                    if (!fifo_empty && tx_ready) begin
                        rd_en <= 1;      // đọc FIFO
                        state <= READ;
                    end
                end

                // ================= READ =================
                READ: begin
                    // vừa assert rd_en xong
                    state <= WAIT;
                end

                // ================= WAIT =================
                WAIT: begin
                    // data_out_fifo valid ở đây
                    tx_data_reg <= data_out_fifo;
                    state <= SEND;
                end

                // ================= SEND =================
                SEND: begin
                    if (tx_ready) begin
                        i_send <= 1;     // gửi UART
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule


//module Tx_TOP #(
//    parameter CLK_SYS     = 50_000_000,
//    parameter BAUD_RATE   = 9600,
//    parameter DATA_BITS   = 8,
//    parameter OVERSAMPLE  = 16,
//    parameter FIFO_WIDTH  = 8,
//    parameter FIFO_DEPTH  = 32
//)(
//    input clk,
//    input reset,
//
//    input  [DATA_BITS-1:0] fifo_data_in,
//    input  fifo_wr_en,
//
//    output tx_serial_out
//);
//
//    // =========================
//    // Baud Generator
//    // =========================
//    wire baud_tick;
//
//    Baud_Gen #(
//        .CLK_SYS    (CLK_SYS),
//        .BAUD_RATE  (BAUD_RATE),
//        .OVERSAMPLE (OVERSAMPLE)
//    ) baud_gen (
//        .clk       (clk),
//        .reset     (reset),
//        .baud_tick (baud_tick)
//    );
//
//    // =========================
//    // FIFO
//    // =========================
//    wire fifo_empty;
//    wire fifo_full;
//    wire [DATA_BITS-1:0] fifo_data_out;
//
//    reg rd_en;
//
//    FIFO #(
//        .W (FIFO_WIDTH),
//        .L (FIFO_DEPTH)
//    ) tx_fifo (
//        .clk       (clk),
//        .reset     (reset),
//        .write_en  (fifo_wr_en),
//        .read_en   (rd_en),
//        .data_in   (fifo_data_in),
//        .data_out  (fifo_data_out),
//        .empty     (fifo_empty),
//        .full      (fifo_full)
//    );
//
//    // =========================
//    // UART TX
//    // =========================
//    wire tx_ready;
//
//    reg i_send;
//    reg [DATA_BITS-1:0] tx_data_reg;
//
//    UART_Tx #(
//        .DATA_BITS  (DATA_BITS),
//        .OVERSAMPLE (OVERSAMPLE)
//    ) uart_tx (
//        .clk        (clk),
//        .reset      (reset),
//        .baud_tick  (baud_tick),
//        .data_in    (tx_data_reg),
//        .i_send     (i_send),
//        .tx         (tx_serial_out),
//        .tx_ready   (tx_ready)
//    );
//
//    // =========================
//    // HANDSHAKE PIPELINE (CHUẨN)
//    // =========================
//
//    // delay 1 cycle để align FIFO read
////    reg rd_en_d;
////
////    always @(posedge clk) begin
////        if (reset) begin
////            rd_en        <= 0;
////            rd_en_d      <= 0;
////            i_send       <= 0;
////            tx_data_reg  <= 0;
////        end else begin
////            // ================= DEFAULT =================
////            rd_en   <= 0;
////            i_send  <= 0;
////
////            // ================= READ FIFO =================
////            if (!fifo_empty && tx_ready) begin
////                rd_en <= 1;
////            end
////
////            // delay signal
////            rd_en_d <= rd_en;
////
////            // ================= LOAD DATA =================
////            if (rd_en_d) begin
////                tx_data_reg <= fifo_data_out;
////                i_send      <= 1;
////            end
////        end
////    end
//
//		reg rd_en_d;
//reg send_pending;
//
//always @(posedge clk) begin
//    if (reset) begin
//        rd_en        <= 0;
//        rd_en_d      <= 0;
//        i_send       <= 0;
//        tx_data_reg  <= 0;
//        send_pending <= 0;
//    end else begin
//        // default
//        rd_en  <= 0;
//        i_send <= 0;
//
//        // ================= READ FIFO =================
//        if (!fifo_empty && tx_ready && !send_pending) begin
//            rd_en <= 1;
//        end
//
//        rd_en_d <= rd_en;
//
//        // ================= LOAD DATA =================
//        if (rd_en_d) begin
//            tx_data_reg  <= fifo_data_out;
//            send_pending <= 1;   // có data chờ gửi
//        end
//
//        // ================= SEND UART =================
//        if (send_pending && tx_ready) begin
//            i_send       <= 1;
//            send_pending <= 0;
//        end
//    end
//end
//
//endmodule