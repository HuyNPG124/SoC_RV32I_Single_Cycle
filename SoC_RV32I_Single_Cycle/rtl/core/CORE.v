// =================================================
// Module CORE (Version 5 - Tích h?p DSP & I2S)
// + CPU RV32I ??n chu k? (không pipeline)
// ================================================

module CORE #(
    parameter CLK_FREQ = 25_000_000     
)(
    input clk,
    input reset,

    // GPIO (B? qua)
    input [1:0] KEY,
    input [7:0] SW,
    output [7:0] LEDR,

    // UART Pins
    input uart_rx,
    output uart_tx,

    // Màn hình LED 7 ?o?n (B? qua)
    output [6:0] HEX0, output [6:0] HEX1, output [6:0] HEX2,
    output [6:0] HEX3, output [6:0] HEX4, output [6:0] HEX5,
    
    // Giao ti?p DSP Audio
    output [31:0] dsp_wr_data,  
    output        dsp_pitch_we, 
    output        dsp_nlms_we,  
    
    // Giao ti?p I2S 
    input  [31:0] i2s_status_in,
    input  [31:0] i2s_data_rx_in
);
    
    // ================================
    // PC (Program Counter)
    // ================================
    wire [31:0] pc_out;
    wire [31:0] pc_next;
    reg [7:0] led_reg;
    reg [31:0] wr_data;
    wire load_stall;

    Program_Counter PC_uut (
        .clk        (clk),
        .pc_reset   (reset),
        .stall      (load_stall),
        .pc_in      (pc_next),
        .pc_out     (pc_out)
    );
    
    // ================================
    // Instruction Memory
    // ================================
    wire [31:0] instruction;
    wire [31:0] imem_addr = reset ? 32'b0 : (load_stall ? pc_out : pc_next);

    Instr_Memory IM_uut (
        .clk            (clk),
        .addr           (imem_addr),
        .instruction    (instruction)
    );

    // ================================
    // Decode
    // ================================
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire is_rtype, is_itype, is_load, is_store, is_branch, is_jal, is_jalr, is_lui, is_auipc;

    Decode DC_uut (
        .instruction    (instruction),
        .opcode         (opcode),
        .funct3         (funct3),
        .funct7         (funct7),
        .is_rtype       (is_rtype),
        .is_itype       (is_itype),
        .is_load        (is_load),
        .is_store       (is_store),
        .is_branch      (is_branch),
        .is_jal         (is_jal),
        .is_jalr        (is_jalr),
        .is_lui         (is_lui),
        .is_auipc       (is_auipc)
    );

    // =================================
    // LOAD STALL
    // =================================
    reg load_wait;
    assign load_stall = is_load && !load_wait;

    always @(posedge clk) begin
        if (reset) load_wait <= 1'b0;
        else       load_wait <= load_stall;
    end

    // =================================
    // Control
    // =================================
    wire BrEq, BrLt, Asel, Bsel, RegWEn, MemRead, MemWrite, PCSel, BrUn;
    wire [1:0] WBsel;
    wire [2:0] ImmSel;

    Control CT_uut (
        .instruction    (instruction),
        .BrEq           (BrEq),
        .BrLt           (BrLt),
        .is_rtype       (is_rtype),
        .is_itype       (is_itype),
        .is_load        (is_load),
        .is_store       (is_store),
        .is_branch      (is_branch),
        .is_jal         (is_jal),
        .is_jalr        (is_jalr),
        .is_lui         (is_lui),
        .is_auipc       (is_auipc),
        .Asel           (Asel),
        .Bsel           (Bsel),
        .RegWEn         (RegWEn),
        .MemRead        (MemRead),
        .MemWrite       (MemWrite),
        .WBsel          (WBsel),
        .PCSel          (PCSel),
        .BrUn           (BrUn),
        .ImmSel         (ImmSel)
    );

    // ===================================
    // Register File & ImmGen
    // ===================================
    wire [31:0] rs1_data, rs2_data, imm;

    Regfile RF_uut (
        .clk        (clk),
        .reset_n    (~reset),
        .write_en   (RegWEn && !load_stall),   
        .rs1_Add    (instruction[19:15]),
        .rs2_Add    (instruction[24:20]),
        .rd_Add     (instruction[11:7]),
        .wr_data    (wr_data),
        .rs_data1   (rs1_data),
        .rs_data2   (rs2_data)
    );

    ImmGen IG_uut (
        .instruction    (instruction),
        .ImmSel         (ImmSel),
        .imm            (imm)
    );

    // =============================================
    // ALU & Branch
    // =============================================
    wire [31:0] alu_in1 = Asel ? pc_out : rs1_data;
    wire [31:0] alu_in2 = Bsel ? imm : rs2_data;
    wire [3:0] alu_op;
    wire [31:0] alu_result;
    wire zero;

    ALU_Control AC_uut (
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .alu_op (alu_op)
    );

    ALU ALU_uut (
        .aluIn1 (alu_in1),
        .aluIn2 (alu_in2),
        .alu_op (alu_op),
        .result (alu_result),
        .zero   (zero)
    );

    Branch BR_uut (
        .A      (rs1_data),
        .B      (rs2_data),
        .BrUn   (BrUn),
        .BrEq   (BrEq),
        .BrLt   (BrLt)
    );
    
    // ==========================================
    // MEMORY MAPPING CHÍNH TH?C
    // ==========================================
    wire mem_write = MemWrite && !reset;
    wire [31:0] store_data;
    
    // 1. Phân gi?i ??a ch? DSP (GHI)
    wire is_dsp_pitch = (alu_result == 32'h2000_0000);
    wire is_dsp_nlms  = (alu_result == 32'h2000_0004);
    
    assign dsp_wr_data  = store_data;
    assign dsp_pitch_we = mem_write & is_dsp_pitch;
    assign dsp_nlms_we  = mem_write & is_dsp_nlms;

    // 2. Phân gi?i ??a ch? I2S (??C)
    wire is_i2s_status = (alu_result == 32'h2000_0010);
    wire is_i2s_data   = (alu_result == 32'h2000_0014);

    // 3. Phân lu?ng RAM n?i b?
    wire is_ram = !(is_dsp_pitch | is_dsp_nlms | is_i2s_status | is_i2s_data);
    wire [31:0] ram_data;
    
    wire ram_we = mem_write && is_ram;
    wire ram_re = MemRead && is_ram;

    // =========================================
    // Load / Store Unit
    // =========================================
    wire [3:0] byte_en;
    wire [31:0] load_data;
    wire [31:0] data_out; // Dây này ch?a d? li?u t?ng sau khi MUX

    Load_Store_Unit LSU_uut (
        .funct3     (funct3),
        .addr_low   (alu_result[1:0]),
        .store_in   (rs2_data),
        .store_data (store_data),
        .byte_en    (byte_en),
        .load_word  (data_out),
        .load_data  (load_data)
    );

    // =========================================
    // Data_RAM
    // =========================================
    Data_RAM DR_uut (
        .clk        (clk),
        .addr       (alu_result),
        .wr_data    (store_data),
        .byte_en    (byte_en),
        .read_en    (ram_re),
        .write_en   (ram_we),
        .rd_data    (ram_data)
    );

    // =======================================
    // READ MUX (B? ch?n lu?ng d? li?u ??c v?)
    // =======================================
    assign data_out = is_i2s_status ? i2s_status_in :
                      is_i2s_data   ? i2s_data_rx_in :
                                      ram_data;

    // =======================================
    // WRITE BACK
    // =======================================
    always @(*) begin
        case (WBsel)
            2'b00: wr_data = alu_result;
            2'b01: wr_data = load_data;
            2'b10: wr_data = pc_out + 4;
            default: wr_data = 32'b0;
        endcase
    end

    // ========================================
    // PC Logic
    // ========================================
    PC_Logic PCL_uut (
        .pc_current (pc_out),
        .imm        (imm),
        .rs1_data   (rs1_data),
        .PCSel      (PCSel),
        .is_jalr    (is_jalr),
        .pc_next    (pc_next)
    );
    // --- 1. MÓC DÂY CHO PC VÀ DECODE ---
    wire is_mret; // Nh?n t? Decode
    
    // (Trong lúc kh?i t?o Program_Counter, n?i thêm dây này vào)
    // .irq(irq), 
    // .is_mret(is_mret),

    // --- 2. ÁNH X? B? NH? BSRAM (Ví d?: D?i ??a ch? 0x4000_0000) ---
    wire is_bsram = (alu_result[31:16] == 16'h4000); 
    wire bsram_we = mem_write & is_bsram;
    wire [31:0] bsram_rd;

    BSRAM_Buffer BSRAM_inst (
        .clk(clk),
        .we(bsram_we),
        .addr(alu_result),
        .wd(store_data),
        .rd(bsram_rd)
    );

    // --- 3. C?P NH?T L?I MUX ??C D? LI?U CHÍNH ---
    assign data_out = is_i2s_status ? i2s_status_in :
                      is_i2s_data   ? i2s_data_rx_in :
                      is_bsram      ? bsram_rd :    // <--- ?ã thêm BSRAM vào MUX
                                      ram_data;
    // ==========================================
    // OUTPUT REGISTER (LEDR)
    // ==========================================
    assign LEDR = 8'b0; // B? qua GPIO ?? t?p trung I2S

endmodule