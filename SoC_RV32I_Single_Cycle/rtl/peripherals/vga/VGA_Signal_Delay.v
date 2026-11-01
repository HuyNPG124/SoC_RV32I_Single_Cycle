// ======================================================================
// Module VGA_Signal_Delay
// + Khắc phục delay của VGA_Text
// + Tọa độ x, y của VGA hoạt động theo clock hệ thống
// + VGA_Text xử lý tín hiệu cần 6 cycle (vì hoạt động theo pixel_tick)
// ==> Cần Timing delay cho x, y theo đúng VGA_Text
// ======================================================================

module VGA_Signal_Delay #(
	parameter DEPTH = 6		// Số cycle bị delay ở VGA_Text
)
(
	input clk,
	input reset,
	input pixel_tick,
	
	input [9:0] x_in,
	input [9:0] y_in,
	input video_on_in,
	input hsync_in,
	input vsync_in,
	
	output [9:0] x_out,
	output [9:0] y_out,
	output video_on_out,
	output hsync_out,
	output vsync_out
);
	
	reg [9:0] x_pipe [0: DEPTH - 1];
	reg [9:0] y_pipe [0: DEPTH - 1];
	reg video_on_pipe [0: DEPTH - 1];
	reg hsync_pipe [0: DEPTH - 1];
	reg vsync_pipe [0: DEPTH - 1];
	
	integer i;
	
	always @(posedge clk) begin
		
		if (reset) begin
			for (i = 0; i < DEPTH; i = i + 1) begin
				x_pipe[i]			<= 0;
				y_pipe[i]			<= 0;
				video_on_pipe[i]	<= 0;
				hsync_pipe[i]		<= 0;
				vsync_pipe[i]		<= 0;
			end
		end
		
		else if (pixel_tick) begin
			x_pipe[0] 			<= x_in;
			y_pipe[0] 			<= y_in;
			video_on_pipe[0] 	<= video_on_in;
			hsync_pipe[0] 		<= hsync_in;
			vsync_pipe[0] 		<= vsync_in;
		end
		
		for (i = 1; i < DEPTH; i = i + 1) begin
			x_pipe[i]			<= x_pipe[i - 1];
			y_pipe[i]			<= y_pipe[i - 1];
			video_on_pipe[i]	<= video_on_pipe[i - 1];
			hsync_pipe[i]		<= hsync_pipe[i - 1];
			vsync_pipe[i]		<= vsync_pipe[i - 1];
		end
	
	end
	
	assign x_out			= x_pipe[DEPTH - 1];
	assign y_out			= y_pipe[DEPTH - 1];
	assign video_on_out	= video_on_pipe[DEPTH - 1];
	assign hsync_out		= hsync_pipe[DEPTH - 1];
	assign vsync_out		= vsync_pipe[DEPTH - 1];

endmodule