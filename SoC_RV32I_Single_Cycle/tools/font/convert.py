import re

# đọc file .h
with open("font8x8_basic.h", "r") as f:
    text = f.read()

# lấy toàn bộ số hex
values = re.findall(r'0x[0-9A-Fa-f]+', text)

print("Total bytes:", len(values))  # phải = 1024

# ghi ra file .hex
with open("font.hex", "w") as f:
    for v in values:
        num = int(v, 16)
        f.write(f"{num:02X}\n")

print("DONE → font.hex")