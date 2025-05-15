# VMON - a RISC-V machine code monitor

VMON is a tiny machine code monitor for RISC-V systems with UART
communication written in RISC-V assembly language.

![Screenshot 2025-05-15 at 23 55 12](https://github.com/user-attachments/assets/fe625a98-4e65-4455-98a1-bdcfa1c57d05)


## Features

- hex and ASCII monitor
- disassembler with hex and decimal output
- currently disassembles RV32/64G instructions
- (some) pseudo instructions supported
- can be built for RV32 or RV64 targets
- runs in QEMU or on RISC-V hardware
- runs bare-metal or can be called from outside
- terminal I/O via UART
- set of included commands configurable in build process
- executable can be built with or without RISC-V example code included

## Requirements

- riscv32/riscv64 GNU toolchain for building (depending on target)

- Make to build executables
- QEMU or RISC-V hardware to run on

## Building

- set up TARGET in Makefile
- review config.h and define/undefine to taste
- review src/include/vmon/UART.h for target UART settings
- make

## Running

- "make run" to run on QEMU

## Commands

VMON understands the following commands:  

**a <start_addr>**
assembly input (ENTER to stop) [alpha testing, currently RV64G supported]

**c <src_start> <src_end> <dst_addr>**
copy memory contents

**d <start_addr>**
disassemble 16 instructions starting at start_addr

**d <start_addr> <end_addr>**
disassemble from <start_addr> to <end_addr>

**d**
continue disassembly from last address used

**f <start_addr> <end_addr> <byte_value>**
**fb <start_addr> <end_addr> <byte_value>** 
find <byte_value> in memory from <start_addr> to <end_addr>

**fh <start_addr> <end_addr> <16bit_value>**
find <16bit_value> in memory from <start_addr> to <end_addr>

**fw <start_addr> <end_addr> <32bit_value>**
find <32bit_value> in memory from <start_addr> to <end_addr>

**g <start_addr>**
goto (restore registers and execute 'j <start_addr>')

**h**
help

**i**
print some internal information

**m <start_addr>**
memory dump 128 bytes starting at <start_addr>

**m <start_addr> <end_addr>**
memory dump from <start_addr> to <end_addr>

**m**
continue memory dump from last address used

**p <dst_addr> <byte_value0> [<byte_value1>] [<byte_value2>] [...]**
write <byte_value0> to <dst_addr>, <byte_value1> to <dst_addr+1>, ...

**pw <dst_addr> <32bit_value0> [<32bit_value1>] [<32bit_value2>] [...]**
write <32bit_value0> to <dst_addr>, <32bit_value1> to <dst_addr+4>, ...

**r**
dump registers as saved on entry

**x**
exit (restore registers and execute a 'ret')

**/h <hex_value>**
Base conversion from hex. Prints value in hex, decimal, binary.

**/d <dec_value>**
Base conversion from signed decimal. Prints value in hex, decimal, binary.

**/b <bin_value>**
Base conversion from binary. Prints value in hex, decimal, binary.

**Numeric values**
All addresses and values are accepted in hex (0x...), bin (0b...) or decimal (no prefix).


## Known Problems

see [issues page](https://github.com/krakenlake/vmon/issues)

## History

Steve Wozniak wrote the
[WOZ monitor (aka WOZMON)](https://github.com/jefftranter/6502/blob/master/asm/wozmon/wozmon.s)
in 1976. The early PET/CBM models came with machine code monitors. I spent hours
to find out the correct monitor entry address on the C64, only to realise (much)
later that it actually didn't have one (in ROM at least, later
[SMON](https://www.c64-wiki.com/wiki/SMON) and others came out). Then, at the end of
the 80s, 8-bit days as well as controlling and understanding your home
computer entirely from electromechanical level to application level was
kind of over.

Fast forward to 2023, when Brouce Hoult somehow challenged
[r/RISCV](https://www.reddit.com/r/RISCV/comments/1446c0i/comment/jnft8wa/)
to port WOZMON to RISC-V assembly. I took a look at the original code, and
as much as I admire this type of wizardry and actually wanted to take on the
challenge, I decided against that. Times have changed, nothing needs to fit
into 256 Bytes any more today, and although I started this as a
"just me learning RISC-V" project, I wanted the code to be maintainable,
meaning easy to understand, better structured, a bit more bulletproof and
easily extendable by others, so that it still might be useful for someone
in the future.
