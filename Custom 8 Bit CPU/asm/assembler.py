#!/usr/bin/env python3
"""Tiny two-pass assembler for the educational 8-bit CPU."""

import argparse
import re
from pathlib import Path

OPCODES = {
    "NOP": 0x00,
    "LDI": 0x10,
    "LDA": 0x11,
    "STA": 0x12,
    "ADD": 0x20,
    "SUB": 0x21,
    "AND": 0x22,
    "OR":  0x23,
    "XOR": 0x24,
    "JMP": 0x30,
    "JZ":  0x31,
    "JNZ": 0x32,
    "OUT": 0x40,
    "HLT": 0xFF,
}
ONE_BYTE = {"NOP", "OUT", "HLT"}
TWO_BYTE = set(OPCODES) - ONE_BYTE


def parse_number(token, labels):
    token = token.strip()
    if token in labels:
        return labels[token]
    try:
        return int(token, 0)
    except ValueError as exc:
        raise ValueError(f"Unknown number or label: {token}") from exc


def clean_lines(source):
    result = []
    for raw in source.splitlines():
        line = raw.split(";", 1)[0].split("#", 1)[0].strip()
        if line:
            result.append(line)
    return result


def assemble(source):
    lines = clean_lines(source)
    labels = {}
    instructions = []
    address = 0

    # Pass 1: collect labels and instruction addresses.
    for line in lines:
        while ":" in line:
            label, remainder = line.split(":", 1)
            label = label.strip()
            if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", label):
                raise ValueError(f"Invalid label: {label}")
            if label in labels:
                raise ValueError(f"Duplicate label: {label}")
            labels[label] = address
            line = remainder.strip()
            if not line:
                break
        if not line:
            continue

        parts = line.replace(",", " ").split()
        mnemonic = parts[0].upper()
        if mnemonic not in OPCODES:
            raise ValueError(f"Unknown instruction: {mnemonic}")
        expected = 1 if mnemonic in ONE_BYTE else 2
        if len(parts) != expected:
            raise ValueError(f"{mnemonic} expects {expected - 1} operand(s)")
        instructions.append((address, mnemonic, parts[1:]))
        address += expected
        if address > 256:
            raise ValueError("Program exceeds the 256-byte address space")

    # Pass 2: encode instructions and operands.
    memory = [0x00] * 256
    for address, mnemonic, operands in instructions:
        memory[address] = OPCODES[mnemonic]
        if mnemonic in TWO_BYTE:
            value = parse_number(operands[0], labels)
            if not 0 <= value <= 255:
                raise ValueError(f"Operand out of 8-bit range: {operands[0]}")
            memory[address + 1] = value

    return memory


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="Assembly source file")
    parser.add_argument("-o", "--output", default="program.hex",
                        help="Output memory image (default: program.hex)")
    args = parser.parse_args()

    source = Path(args.source).read_text(encoding="utf-8")
    memory = assemble(source)
    Path(args.output).write_text(
        "".join(f"{byte:02X}\\n" for byte in memory), encoding="ascii"
    )
    print(f"Assembled 256 bytes into {args.output}")


if __name__ == "__main__":
    main()
