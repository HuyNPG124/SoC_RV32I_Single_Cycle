// ===========================================
// Module FIFO
// + FIFO có thể lưu trữ tối đa 32 byte
// ===========================================

module FIFO #(
    parameter W = 8,
    parameter L = 32
)
(
    input clk,
    input reset,
    input write_en,
    input read_en,
    input [W-1:0] data_in,

    output full,
    output empty,
    output reg [W-1:0] data_out
);

    localparam ADDR_WIDTH = $clog2(L);

    reg [W-1:0] mem [0:L-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    reg [ADDR_WIDTH:0] count;

    wire write = write_en && !full;
    wire read  = read_en  && !empty;

    assign full  = (count == L);
    assign empty = (count == 0);

    // WRITE
    always @(posedge clk) begin
        if (reset)
            wr_ptr <= 0;
        else if (write) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // READ
    always @(posedge clk) begin
        if (reset) begin
            rd_ptr <= 0;
            data_out <= 0;
        end
        else if (read) begin
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // COUNT
    always @(posedge clk) begin
        if (reset)
            count <= 0;
        else begin
            case ({write, read})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

endmodule