module dsp_audio_wrapper #(
    parameter NLMS_WIDTH = 32,   // Khớp với độ rộng bit của khối NLMS
    parameter RAM_DEPTH  = 4096
)(
    // ==========================================
    // 1. Giao tiếp điều khiển với CORE RISC-V
    // ==========================================
    input  wire        clk,
    input  wire        reset,          // Lõi CORE.v dùng reset tích cực mức CAO
    
    input  wire [31:0] dsp_wr_data,    // Dữ liệu từ CPU đẩy xuống
    input  wire        dsp_pitch_we,   // Xung Cờ ghi (Write Enable) từ Address Decoder

    // ==========================================
    // 2. Giao tiếp luồng dữ liệu Âm thanh (Datapath)
    // ==========================================
    input  wire [NLMS_WIDTH-1:0] nlms_data,
    input  wire                  nlms_valid,
    output wire [15:0]           audio_out,
    output wire                  dsp_valid
);

    // Thanh ghi lưu hệ số Delta do RISC-V cấu hình
    reg [23:0] delta_reg;

    // Bắt tín hiệu Write Enable trực tiếp từ CPU (Không cần giải mã địa chỉ nữa)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            delta_reg <= 24'd4096; // Mặc định Delta = 1.0 (Giọng bình thường)
        end 
        else if (dsp_pitch_we) begin
            // Mỗi khi CPU ghi vào địa chỉ 0x2000_0000, dsp_pitch_we sẽ nháy lên 1
            // Ta chốt ngay dữ liệu từ bus vào thanh ghi
            delta_reg <= dsp_wr_data[23:0]; 
        end
    end

    // Nghịch đảo tín hiệu reset để cấp cho khối lõi (vì lõi dùng rst_n tích cực thấp)
    wire rst_n = ~reset;

    // Khởi tạo khối Pitch Shifter lõi bên trong (Phiên bản mới nhất)
    pitch_shifter #(
        .NLMS_WIDTH(NLMS_WIDTH),
        .RAM_DEPTH(RAM_DEPTH)
    ) core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .nlms_data(nlms_data),
        .nlms_valid(nlms_valid),
        .pitch_delta(delta_reg),   // Cấp hệ số Delta từ thanh ghi CPU vào lõi DSP
        .audio_out(audio_out),
        .dsp_valid(dsp_valid)
    );

endmodule