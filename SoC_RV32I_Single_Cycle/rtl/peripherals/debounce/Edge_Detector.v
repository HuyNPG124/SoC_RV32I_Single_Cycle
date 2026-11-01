// ========================================
// Debounce Button (FSM)
// Module Edge_Detector
// ========================================

module Edge_Detector (
    input  wire clk,
    input  wire sig_in,
    output wire pulse_out
);
    reg sig_delay;

    always @(posedge clk) begin
        sig_delay <= sig_in;
    end

    assign pulse_out = sig_in & (~sig_delay);

endmodule