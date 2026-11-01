# ==========================================
# RISC-V HEX → FULL DECODE TOOL
# HEX + BINARY + ASM + COMMENT + FIELDS
# ==========================================

import sys

# ================= SIGN EXTEND =================
def sign_extend(value, bits):
    if (value >> (bits - 1)) & 1:
        return value - (1 << bits)
    return value

# ================= BINARY =================
def to_binary32(inst):
    return format(inst, '032b')

# ================= DECODE ASM =================
def decode_instruction(inst):
    opcode = inst & 0x7F
    rd     = (inst >> 7) & 0x1F
    funct3 = (inst >> 12) & 0x7
    rs1    = (inst >> 15) & 0x1F
    rs2    = (inst >> 20) & 0x1F
    funct7 = (inst >> 25) & 0x7F

    if opcode == 0x33:  # R-type
        if funct3 == 0x0 and funct7 == 0x00:
            return f"add x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x0 and funct7 == 0x20:
            return f"sub x{rd}, x{rs1}, x{rs2}"

    elif opcode == 0x13:  # I-type
        imm = sign_extend((inst >> 20) & 0xFFF, 12)
        if funct3 == 0x0:
            return f"addi x{rd}, x{rs1}, {imm}"

    elif opcode == 0x03:  # LOAD
        imm = sign_extend((inst >> 20) & 0xFFF, 12)
        if funct3 == 0x2:
            return f"lw x{rd}, {imm}(x{rs1})"

    elif opcode == 0x23:  # STORE
        imm = ((inst >> 7) & 0x1F) | (((inst >> 25) & 0x7F) << 5)
        imm = sign_extend(imm, 12)
        if funct3 == 0x2:
            return f"sw x{rs2}, {imm}(x{rs1})"

    elif opcode == 0x63:  # BRANCH
        imm = (
            ((inst >> 7) & 0x1) << 11 |
            ((inst >> 8) & 0xF) << 1 |
            ((inst >> 25) & 0x3F) << 5 |
            ((inst >> 31) & 0x1) << 12
        )
        imm = sign_extend(imm, 13)
        if funct3 == 0x0:
            return f"beq x{rs1}, x{rs2}, {imm}"

    elif opcode == 0x37:
        imm = inst & 0xFFFFF000
        return f"lui x{rd}, {hex(imm)}"

    elif opcode == 0x17:
        imm = inst & 0xFFFFF000
        return f"auipc x{rd}, {hex(imm)}"

    elif opcode == 0x6F:
        imm = (
            ((inst >> 21) & 0x3FF) << 1 |
            ((inst >> 20) & 0x1) << 11 |
            ((inst >> 12) & 0xFF) << 12 |
            ((inst >> 31) & 0x1) << 20
        )
        imm = sign_extend(imm, 21)
        return f"jal x{rd}, {imm}"

    elif opcode == 0x67:
        imm = sign_extend((inst >> 20) & 0xFFF, 12)
        return f"jalr x{rd}, {imm}(x{rs1})"

    return "UNKNOWN"

# ================= COMMENT =================
def explain_instruction(asm):
    if asm.startswith("add "):
        return "Cộng hai thanh ghi"
    elif asm.startswith("sub "):
        return "Trừ hai thanh ghi"
    elif asm.startswith("addi "):
        return "Cộng với hằng số"
    elif asm.startswith("lw "):
        return "Load word từ bộ nhớ"
    elif asm.startswith("sw "):
        return "Store word ra bộ nhớ"
    elif asm.startswith("beq "):
        return "So sánh bằng, nếu đúng thì nhảy"
    elif asm.startswith("lui "):
        return "Load upper immediate"
    elif asm.startswith("auipc "):
        return "Tạo địa chỉ theo PC"
    elif asm.startswith("jal "):
        return "Jump + lưu return"
    elif asm.startswith("jalr "):
        return "Jump qua thanh ghi"
    else:
        return "Không xác định"

# ================= FIELD DECODE =================
def decode_fields(inst):
    opcode = inst & 0x7F
    rd     = (inst >> 7) & 0x1F
    funct3 = (inst >> 12) & 0x7
    rs1    = (inst >> 15) & 0x1F
    rs2    = (inst >> 20) & 0x1F
    funct7 = (inst >> 25) & 0x7F

    # detect type
    if opcode == 0x33:
        type_inst = "R"
        return f"{type_inst}: funct7={funct7:07b}, rs2={rs2:05b}, rs1={rs1:05b}, funct3={funct3:03b}, rd={rd:05b}, opcode={opcode:07b}"

    elif opcode in [0x13, 0x03, 0x67]:
        type_inst = "I"
        imm = (inst >> 20) & 0xFFF
        return f"{type_inst}: imm={imm:012b}, rs1={rs1:05b}, funct3={funct3:03b}, rd={rd:05b}, opcode={opcode:07b}"

    elif opcode == 0x23:
        type_inst = "S"
        imm = ((inst >> 7) & 0x1F) | (((inst >> 25) & 0x7F) << 5)
        return f"{type_inst}: imm={imm:012b}, rs2={rs2:05b}, rs1={rs1:05b}, funct3={funct3:03b}, opcode={opcode:07b}"

    elif opcode == 0x63:
        type_inst = "B"
        return f"{type_inst}: rs2={rs2:05b}, rs1={rs1:05b}, funct3={funct3:03b}, opcode={opcode:07b}"

    elif opcode in [0x37, 0x17]:
        type_inst = "U"
        imm = inst & 0xFFFFF000
        return f"{type_inst}: imm={imm >> 12:020b}, rd={rd:05b}, opcode={opcode:07b}"

    elif opcode == 0x6F:
        type_inst = "J"
        return f"{type_inst}: rd={rd:05b}, opcode={opcode:07b}"

    return "UNKNOWN"

# ================= MAIN =================
def decode_hex_file(input_file, output_file):
    with open(input_file, "r") as f:
        lines = f.readlines()

    with open(output_file, "w") as out:
        header = "IDX | PC       | HEX        | BINARY (32-bit)                      | ASM                | COMMENT              | FIELDS\n"
        out.write(header)
        out.write("-" * len(header) + "\n")

        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue

            inst = int(line, 16)
            binary = to_binary32(inst)
            asm = decode_instruction(inst)
            comment = explain_instruction(asm)
            fields = decode_fields(inst)
            pc = i * 4

            result = f"{i:02d} | {pc:08x} | {line} | {binary} | {asm:<18} | {comment:<20} | {fields}"
            print(result)
            out.write(result + "\n")

    print(f"\nSaved to {output_file}")

# ================= RUN =================
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python decode.py <input.hex> <output.txt>")
    else:
        decode_hex_file(sys.argv[1], sys.argv[2])


#python3 decode.py firmware.hex output.txt