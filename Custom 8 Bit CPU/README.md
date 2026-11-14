# Modular 8-bit Von Neumann CPU

A small educational 8-bit CPU written in Verilog-2001. Instructions and data
share one 256-byte memory (a Von Neumann architecture).

## Project layout

- `rtl/alu.v` — arithmetic and bitwise logic
- `rtl/unified_memory.v` — 256 x 8-bit shared instruction/data memory
- `rtl/cpu_core.v` — registers, control FSM, instruction decode and execution
- `rtl/cpu_system.v` — connects the CPU core to unified memory
- `asm/assembler.py` — two-pass assembler
- `asm/example.asm` — example program
- `sim/tb_cpu_system.v` — simulation testbench

## CPU characteristics

- 8-bit data path and 8-bit address space
- 256 bytes of unified memory
- Accumulator-based design
- Program counter, instruction register, operand register and zero flag
- Fetch / decode / operand-fetch / execute state machine
- Asynchronous memory reads and synchronous memory writes
- Simple one-byte output port with a one-cycle `output_valid` pulse

## Instruction set

| Mnemonic | Encoding | Meaning |
|---|---:|---|
| `NOP` | `00` | No operation |
| `LDI value` | `10 value` | Load immediate value into ACC |
| `LDA address` | `11 address` | ACC = memory[address] |
| `STA address` | `12 address` | memory[address] = ACC |
| `ADD address` | `20 address` | ACC = ACC + memory[address] |
| `SUB address` | `21 address` | ACC = ACC - memory[address] |
| `AND address` | `22 address` | ACC = ACC AND memory[address] |
| `OR address` | `23 address` | ACC = ACC OR memory[address] |
| `XOR address` | `24 address` | ACC = ACC XOR memory[address] |
| `JMP address` | `30 address` | Unconditional jump |
| `JZ address` | `31 address` | Jump if zero flag is set |
| `JNZ address` | `32 address` | Jump if zero flag is clear |
| `OUT` | `40` | Copy ACC to output port |
| `HLT` | `FF` | Halt CPU |

Arithmetic wraps around modulo 256. The zero flag is updated by `LDI`,
`LDA`, and ALU operations. This first version has no carry flag or stack.

## Assemble

From the project root:

```bash
python asm/assembler.py asm/example.asm -o program.hex
```

The assembler writes a 256-line hexadecimal memory image. Labels are supported:

```asm
        LDI 3
        STA counter
loop:   LDA counter
        SUB one
        STA counter
        JNZ loop
        HLT

; Data can be placed after the program:
counter: NOP
one:     NOP
```

For this minimal assembler, labels refer to byte addresses, and data storage
should be initialized with instructions or added to the memory image manually.
The example above illustrates label syntax, not a recommended data layout.

Numbers may be decimal (`12`) or hexadecimal (`0x0C`). `;` and `#` begin
comments.

## Simulate with Icarus Verilog

From the project root:

```bash
python asm/assembler.py asm/example.asm -o program.hex

iverilog -g2001 -o cpu_sim \
  rtl/alu.v \
  rtl/unified_memory.v \
  rtl/cpu_core.v \
  rtl/cpu_system.v \
  sim/tb_cpu_system.v

vvp cpu_sim
```

Expected output includes:

```text
Starting 8-bit CPU simulation...
CPU OUTPUT: 12 (0x0c)
CPU halted.
```

The testbench uses a relative path for `program.hex`, so run the commands
from the project root.

## Hardware notes

This implementation uses asynchronous memory reads to keep the first CPU
version easy to understand and simulate. Many FPGA block RAMs require
synchronous reads; adapting this design to a particular FPGA may require
adding memory-wait states to the controller. The shared memory bus is
time-multiplexed across instruction fetches and data accesses, so instruction
execution takes multiple clock cycles.

This is a teaching CPU, not a hardened processor. It does not implement
interrupts, a stack, memory-mapped peripherals, or a carry flag.
