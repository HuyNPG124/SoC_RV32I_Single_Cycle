module Program_Counter (
    input clk,
    input pc_reset,
    input stall,        // Tính hi?u stall t? l?nh Load
    
    // --- TÍN HI?U NG?T (M?I) ---
    input irq,          // C? ng?t t? ngo?i vi (Ví d?: I2S báo có data)
    input is_mret,      // C? báo l?nh "Return from Interrupt" t? kh?i Decode
    
    input      [31:0] pc_in,  // L?nh ti?p theo bình th??ng (PC+4 ho?c Branch)
    output reg [31:0] pc_out
);

    reg [31:0] epc;    // Thanh ghi gi?u kín: Ch?a PC lúc b? c?t ngang
    reg in_isr;        // C? báo CPU ?ang ? trong hàm ng?t (Ch?ng ng?t l?ng nhau)

    always @(posedge clk) begin
        if (pc_reset) begin
            pc_out <= 32'b0;
            epc    <= 32'b0;
            in_isr <= 1'b0;
        end 
        // 1. N?u có ng?t (irq=1), không b? k?t load (stall=0), và ch?a ? trong ng?t
        else if (irq && !in_isr && !stall) begin
            epc    <= pc_in;           // C?t cái PC_next (l?nh l? ra ???c ch?y) vào epc
            pc_out <= 32'h0000_0100;   // B? lái PC bay th?ng ??n ??a ch? hàm ng?t
            in_isr <= 1'b1;            // B?t khiên ch?ng ng?t
        end 
        // 2. Khi ph?n m?m g?i l?nh mret (Return)
        else if (is_mret && !stall) begin
            pc_out <= epc;             // Tr? l?i PC c? ?? ch?y ti?p công vi?c dang d?
            in_isr <= 1'b0;            // T?t khiên
        end 
        // 3. Ch?y bình th??ng
        else if (!stall) begin
            pc_out <= pc_in;
        end
    end

endmodule