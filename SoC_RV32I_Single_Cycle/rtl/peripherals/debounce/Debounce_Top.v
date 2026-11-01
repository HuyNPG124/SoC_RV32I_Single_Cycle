// =======================================
// Debounce Button (FSM)
// Module Debounce_Top
// =======================================

module Debounce_Top (
    input  clk,
    input  reset,
    input  key_n,       // KEY (active LOW)

    output debounced,   // level ổn định
    output pulse        // xung 1 clock
);

    // ==================================================
    // 1. Synchronizer (QUAN TRỌNG)
    // ==================================================
    reg sync0, sync1;

    always @(posedge clk) begin
        sync0 <= ~key_n;   // convert active LOW → HIGH
        sync1 <= sync0;
    end

    // ==================================================
    // 2. Wires
    // ==================================================
    wire time_done;
    wire timer_reset;

    // ==================================================
    // 3. Debounce FSM
    // ==================================================
    Debounce_Delay u1 (
        .clk        (clk),
        .reset      (reset),
        .noisy      (sync1),   // dùng tín hiệu đã sync
        .time_done  (time_done),
        .debounced  (debounced),
        .timer_reset(timer_reset)
    );

    // ==================================================
    // 4. Time counter (20ms)
    // ==================================================
    Time_Counter #(
        .TIME(1_999_999)
    ) u2 (
        .clk        (clk),
        .reset      (reset),
        .timer_reset(timer_reset),
        .time_done  (time_done)
    );

    // ==================================================
    // 5. Edge detector
    // ==================================================
    Edge_Detector u3 (
        .clk       (clk),
        .sig_in    (debounced),
        .pulse_out (pulse)
    );

endmodule