// =================================
// Debounce Button (FSM)
// Module Time_Counter
// =================================

module Time_Counter
    #(parameter TIME = 1_999_999)
(
    input  clk,
    input  reset,          // active HIGH
    input  timer_reset,
    output reg time_done
);

    localparam CNT_WIDTH = $clog2(TIME + 1);
    reg [CNT_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter   <= 'd0;
            time_done <= 1'b0;
        end
        else if (timer_reset) begin
            counter   <= 'd0;
            time_done <= 1'b0;
        end
        else if (counter < TIME) begin
            counter   <= counter + 1;
            time_done <= 1'b0;
        end
        else begin
            time_done <= 1'b1;
        end
    end

endmodule