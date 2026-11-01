module pitch_shifter #(
    // Khai báo tham số để dễ cấu hình theo IP Core của Gowin
    parameter NLMS_WIDTH = 32,   // Số bit đầu ra e_out của khối NLMS
    parameter RAM_DEPTH  = 4096  // Kích thước bộ đệm vòng
)(
    input  wire                   clk,
    input  wire                   rst_n,
    
    // Giao tiếp với Gowin NLMS IP Core
    input  wire [NLMS_WIDTH-1:0]  nlms_data,   // Cổng e_out từ NLMS
    input  wire                   nlms_valid,  // Cổng out_valid từ NLMS
    
    // Giao tiếp với RISC-V MMIO
    input  wire [23:0]            pitch_delta, 
    
    // Giao tiếp với I2S TX
    output wire [15:0]            audio_out,
    output reg                    dsp_valid
);

    // ==============================================================================
    // 1. MẠCH BÃO HÒA CHỐNG TRÀN (Saturation Logic)
    // Chuyển đổi dữ liệu lớn (32-bit) từ DSP IP về chuẩn Audio 16-bit có dấu.
    // Nếu chỉ lấy nlms_data[15:0] một cách mù quáng, khi âm thanh quá to sẽ bị tràn số,
    // sóng dương đột ngột lật thành sóng âm gây tiếng nổ (clipping) cực lớn ra loa.
    // ==============================================================================
    reg signed [15:0] audio_in_16b;
    wire signed [NLMS_WIDTH-1:0] signed_nlms = nlms_data;

    always @(*) begin
        // Giới hạn kịch trần dương của 16-bit có dấu (0x7FFF)
        if (signed_nlms > (2**(NLMS_WIDTH-1) - 1)) begin
            if (signed_nlms > 32'sd32767) 
                audio_in_16b = 16'sd32767;
            else 
                audio_in_16b = nlms_data[15:0];
        end
        // Giới hạn kịch sàn âm của 16-bit có dấu (0x8000)
        else if (signed_nlms < -32'sd32768) begin
            audio_in_16b = -16'sd32768;
        end
        // Nằm trong dải an toàn, xén bit bình thường
        else begin
            audio_in_16b = nlms_data[15:0];
        end
    end

    // ==============================================================================
    // 2. KHAI BÁO BỘ NHỚ VÀ CON TRỎ (Giữ nguyên dung lượng 16-bit)
    // ==============================================================================
    reg [11:0] wr_ptr;                  
    reg [23:0] rd_ptr;                  
    
    reg [15:0] circular_buffer [0:RAM_DEPTH-1];
    reg [15:0] read_data;

    wire [11:0] rd_addr = rd_ptr[23:12];

    // Khởi tạo RAM rỗng để tránh lỗi XXXX khi chạy mô phỏng
    integer i;
    initial begin
        for (i = 0; i < RAM_DEPTH; i = i + 1) begin
            circular_buffer[i] = 16'd0;
        end
    end

    // ==============================================================================
    // 3. LOGIC QUẢN LÝ CON TRỎ 
    // ==============================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr    <= 12'd0;
            rd_ptr    <= {12'd2048, 12'd0}; // Cách một nửa vòng RAM an toàn
            dsp_valid <= 1'b0;
        end 
        else begin
            dsp_valid <= nlms_valid;

            if (nlms_valid) begin
                wr_ptr <= wr_ptr + 1'b1;
                rd_ptr <= rd_ptr + pitch_delta;
            end
        end
    end

    // ==============================================================================
    // 4. THAO TÁC ĐỌC/GHI BRAM ĐỒNG BỘ
    // ==============================================================================
    always @(posedge clk) begin
        if (nlms_valid) begin
            // GHI DỮ LIỆU ĐÃ QUA MẠCH BÃO HÒA VÀO RAM
            circular_buffer[wr_ptr] <= audio_in_16b;
            read_data <= circular_buffer[rd_addr];
        end
    end

    assign audio_out = read_data;

endmodule