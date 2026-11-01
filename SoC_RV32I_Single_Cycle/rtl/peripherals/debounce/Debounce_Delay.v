// ============================================
// Debounce Button (FSM)
// Module Debounce_Delay
// ============================================


module Debounce_Delay (
    input  clk,
    input  reset,       // Reset toàn bộ hệ thống (active-low)
    input  noisy,
    input  time_done,
    output debounced,
    output timer_reset
);

    reg [1:0] state_reg, state_next;

    // State encoding
    parameter s0 = 2'b00;
    parameter s1 = 2'b01;
    parameter s2 = 2'b10;
    parameter s3 = 2'b11;

    // --------------------------------------------------
    // State register
    // --------------------------------------------------
    always @(posedge clk or negedge reset) begin
        if (!reset)
            state_reg <= s0;
        else
            state_reg <= state_next;
    end

    // --------------------------------------------------
    // Next-state logic
    // --------------------------------------------------
    always @(*) begin
        state_next = state_reg;   // default

        case (state_reg)
            s0: begin
                if (noisy)
                    state_next = s1;
            end

            s1: begin
                if (!noisy)
                    state_next = s0;
                else if (time_done)
                    state_next = s2;
            end

            s2: begin
                if (!noisy)
                    state_next = s3;
            end

            s3: begin
                if (noisy)
                    state_next = s2;
                else if (time_done)
                    state_next = s0;
            end

            default: state_next = s0;
        endcase
    end

    // --------------------------------------------------
    // Output logic (Moore FSM)
    // --------------------------------------------------
    assign timer_reset = (state_reg == s0) || (state_reg == s2);
    assign debounced   = (state_reg == s2) || (state_reg == s3);

endmodule
