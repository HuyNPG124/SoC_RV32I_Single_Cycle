// ============================================================
// INMP441 I2S receiver
// - Generates I2S BCLK/LRCLK from a 50 MHz system clock
// - 16 kHz sample rate, 32 BCLKs per channel
// - Captures one selected channel from the INMP441
// - Outputs a sign-extended 24-bit sample in a 32-bit register
// - sample_valid is a one-system-clock pulse for each new sample
// ============================================================

module INMP441_Reader #(
    parameter integer CLK_FREQ    = 50_000_000,
    parameter integer SAMPLE_RATE = 16_000,
    // 1 selects the left slot (LRCLK low); 0 selects the right slot.
    parameter integer LEFT_CHANNEL = 1
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        serial_data,

    output wire        i2s_bclk,
    output wire        i2s_lrclk,
    output reg [31:0]  sample_data,
    output reg         sample_valid
);

    localparam integer BCLK_FREQ = SAMPLE_RATE * 64;
    localparam integer PHASE_WIDTH = 32;

    // The accumulator toggles BCLK on overflow. This gives an average
    // BCLK of 64 * SAMPLE_RATE, including when the clock is not divisible.
    localparam [PHASE_WIDTH-1:0] PHASE_INC =
        (64'd2 * BCLK_FREQ * (64'd1 << PHASE_WIDTH)) / CLK_FREQ;

    reg [PHASE_WIDTH-1:0] phase_acc;
    reg bclk_reg;
    reg lrclk_reg;
    reg [5:0] bit_count;
    reg [31:0] shift_reg;
    reg lrclk_pending;

    wire [PHASE_WIDTH-1:0] phase_sum = phase_acc + PHASE_INC;
    wire bclk_toggle = (phase_sum < phase_acc);
    wire bclk_rising = bclk_toggle && !bclk_reg;
    wire [31:0] shift_next = {shift_reg[30:0], serial_data};

    assign i2s_bclk  = bclk_reg;
    assign i2s_lrclk = lrclk_reg;

    always @(posedge clk) begin
        if (reset) begin
            phase_acc    <= {PHASE_WIDTH{1'b0}};
            bclk_reg     <= 1'b0;
            lrclk_reg    <= 1'b0;
            bit_count    <= 6'd0;
            shift_reg    <= 32'd0;
            lrclk_pending <= 1'b0;
            sample_data  <= 32'd0;
            sample_valid <= 1'b0;
        end
        else begin
            phase_acc    <= phase_sum;
            sample_valid <= 1'b0;

            if (bclk_toggle) begin
                bclk_reg <= ~bclk_reg;
            end

            if (bclk_toggle && bclk_reg && lrclk_pending) begin
                lrclk_reg     <= ~lrclk_reg;
                lrclk_pending <= 1'b0;
            end

            if (bclk_rising) begin
                shift_reg <= shift_next;

                if (bit_count == 6'd31) begin
                    // LRCLK is low for the left channel and high for right.
                    if ((lrclk_reg == 1'b0) == (LEFT_CHANNEL != 0)) begin
                        // INMP441 transfers 24 useful bits followed by
                        // one leading delay bit and zero padding.
                        sample_data <= {
                            {8{shift_next[30]}},
                            shift_next[30:7]
                        };
                        sample_valid <= 1'b1;
                    end

                    bit_count <= 6'd0;
                    lrclk_pending <= 1'b1;
                end
                else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule
