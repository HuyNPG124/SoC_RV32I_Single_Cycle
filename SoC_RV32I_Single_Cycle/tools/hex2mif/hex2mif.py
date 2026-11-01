import sys
import os

def read_hex_file(hex_file):
    data = []

    with open(hex_file, "r") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            if "//" in line:
                line = line.split("//")[0].strip()
            if "#" in line:
                line = line.split("#")[0].strip()

            if not line:
                continue

            if line.startswith("0x") or line.startswith("0X"):
                line = line[2:]

            line = line.upper()

            try:
                int(line, 16)
            except:
                print("Skip invalid:", line)
                continue

            data.append(line)

    return data


def write_mif(data, mif_file, depth):
    with open(mif_file, "w") as f:
        f.write("WIDTH=32;\n")
        f.write("DEPTH=%d;\n\n" % depth)

        f.write("ADDRESS_RADIX=HEX;\n")
        f.write("DATA_RADIX=HEX;\n\n")

        f.write("CONTENT BEGIN\n")

        for addr, value in enumerate(data):
            f.write("%04X : %s;\n" % (addr, value))

        if len(data) < depth:
            f.write("[%04X..%04X] : 00000000;\n" % (len(data), depth - 1))

        f.write("END;\n")


def main():
    if len(sys.argv) < 3:
        print("Usage: python hex2mif.py input.hex output.mif [depth]")
        return

    hex_file = sys.argv[1]
    mif_file = sys.argv[2]

    if len(sys.argv) > 3:
        depth = int(sys.argv[3])
    else:
        depth = 1024

    if not os.path.exists(hex_file):
        print("File not found:", hex_file)
        return

    data = read_hex_file(hex_file)

    if len(data) > depth:
        data = data[:depth]

    write_mif(data, mif_file, depth)

    print("Done:", mif_file)


if __name__ == "__main__":
    main()