// ========================================================
// Module UART_Tx
// + Bộ Tx của UART
// + Gửi tín hiệu từ kit DE10 tới máy tính qua CP2102 TTL
// + Thiết kế theo FSM
// ========================================================

module UART_Tx #(
	
	parameter DATA_BITS	= 8,		// Số bit dữ liệu mà UART truyền trong mỗi frame
	parameter OVERSAMPLE	= 16
	
)
(
	input clk,
	input reset,
	input baud_tick,
	input [DATA_BITS - 1:0] data_in,		// Dữ liệu cần gửi đi
	input i_send,								// Tín hiệu cho phép gửi tín hiệu đi
	
	output reg tx,			// Đường truyền dữ liệu ra ngoài (tryền 1 bit 1 lần)
	output tx_ready		// Cờ báo Tx sẵn sàng nhận dữ liệu mới để truyền
);
	
	// Các trạng thái của FSM
	localparam IDLE 	= 0;
	localparam START	= 1;
	localparam DATA	= 2;
	localparam STOP	= 3;
	
	reg [1:0] state;												// Trạng thái hiện tại của FSM
	reg [$clog2(DATA_BITS) - 1:0] bit_cnt;					// Thanh ghi đếm số bit đã truyền đi
	reg [DATA_BITS - 1:0] shift;								//	Thanh ghi trung gian cho data_in
	reg [$clog2(OVERSAMPLE) - 1:0] tick_cnt;				// Thanh ghi đếm số lần lấy mẫu bit
	
	assign tx_ready = (state == IDLE);	// Tx sẵn sàng nhận dữ liệu khi FSM ở IDLE
	
	always @(posedge clk) begin
		
		if (reset) begin
			state 	<= IDLE;
			tick_cnt	<= 0;
			bit_cnt	<= 0;
			shift		<= 0;
			tx			<= 1'b1;
		end
		
		// FSM
		else begin
			
			case (state)
				
				// IDLE
				IDLE: 
				begin
					tx 		<= 1'b1;
					tick_cnt <= 0;
					
					if (i_send) begin
						shift 	<= data_in;
						bit_cnt 	<= 0;
						state		<= START;
					end
					
				end
				
				// START
				START:
				begin
					tx <= 1'b0;
					
					if (baud_tick) begin
						if (tick_cnt == OVERSAMPLE - 1) begin
							tick_cnt <= 0;
							state		<= DATA;
						end
						
						else begin
							tick_cnt <= tick_cnt + 1;
						end
					end
					
				end
				
				// DATA
				DATA:
				begin
					
					if (baud_tick) begin
						// Lấy mẫu bit để truyền đi
						if (tick_cnt == 0)
							begin
								tx <= shift[0];
							end
							
						if (tick_cnt == OVERSAMPLE - 1) begin
							shift		<= shift >> 1;
							tick_cnt <= 0;
							
							// Đếm số bit đã truyền đi
							if (bit_cnt == DATA_BITS - 1) begin
								state <= STOP;
							end
							
							else begin
								bit_cnt <= bit_cnt + 1;
							end
						end
						
						else begin
							tick_cnt <= tick_cnt + 1;
						end
					end
					
				end
				
				// STOP
				STOP:
				begin
					tx <= 1'b1;
					
					if (baud_tick) begin
						if (tick_cnt == OVERSAMPLE - 1) begin
							tick_cnt <= 0;
							state <= IDLE;
						end
						
						else begin
							tick_cnt <= tick_cnt + 1;
						end
					end
				end
				
				// Default
				default: state <= IDLE;
				
			endcase
			
		end
		
	end

endmodule