module BSRAM_Buffer (
    input clk,
    input we,
    input [31:0] addr, 
    input [31:0] wd,
    output reg [31:0] rd
);
    // T?o b? ??m 2KB (512 t? 32-bit)
    reg [31:0] ram [0:511];
    
    // B? qua 2 bit cu?i (vì ??a ch? CPU nh?y cách 4 byte)
    wire [8:0] word_addr = addr[10:2]; 

    always @(posedge clk) begin
        if (we) begin
            ram[word_addr] <= wd;
        end
        // BSRAM luôn có ?? tr? 1 chu k? khi ??c (chu?n xác v?i FPGA th?t)
        rd <= ram[word_addr];
    end
endmodule