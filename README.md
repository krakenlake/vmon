# VMON - a RISC-V machine code monitor

VMON is a tiny machine code monitor for RISC-V systems with UART
communication written entirely in RISC-V assembly language.

![Screenshot 2025-05-16 at 00 02 59](https://github.com/user-attachments/assets/d5b9390c-b760-4423-af9e-ff9bced5b0a2)



## Features

- hex and ASCII monitor
- assembler/disassembler with hex and decimal output
- currently RV64G instructions supported
- (some) pseudo instructions supported
- hex/dec/bin conversion
- searching in memory areas
- copying memory areas
- exception catching
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

- set up `TARGET` in Makefile
- review `config.h` and define/undefine to taste
- review `src/include/vmon/UART.h` for target UART settings
- `make`

## Running

- `make run` to run on QEMU

## Using VMON

### Command Line ###

VMON understands the following commands:  

#### `a <start_addr>` ###

Assembly input (press ENTER to stop) [alpha testing, currently RV64G instructions supported].

#### `c <src_start> <src_end> <dst_addr>` ####

Copy memory contents. This also works correctly when both areas overlap.

#### `d [<start_addr>] [<end_addr]>` ####

Disassemble from <start_addr> to <end_addr>.
If <end_addr> is not given, 16 instructions are printed by default. 
If no address is given, dump will start from the last address used before.

#### `f <start_addr> <end_addr> <byte_value>` ####

#### `fb <start_addr> <end_addr> <byte_value>` ####

Find <byte_value> in memory from <start_addr> to <end_addr>.

#### `fh <start_addr> <end_addr> <16bit_value>` ####

Find <16bit_value> in memory from <start_addr> to <end_addr>.

#### `fw <start_addr> <end_addr> <32bit_value>` ####

Find <32bit_value> in memory from <start_addr> to <end_addr>.

#### `g <start_addr>` ####

Go to <start_addr> (restore registers as they were on entry and then execute `j <start_addr>`).

#### `h` ####

Print command line help information.

#### `i` ####

Print some internal information.

#### `m [<start_addr>] [<end_addr>]` ####

Memory dump from <start_addr> to <end_addr>.
If <end_addr> is not given, 16 lines (128 bytes) are printed by default.
If no address is given, dump will continue from the last address used before.

#### `p <dst_addr> <byte_value0> [<byte_value1>] [<byte_value2>] [...]` ####

Write ("poke") <byte_value0> to <dst_addr>, <byte_value1> to <dst_addr+1>, ...

#### `pw <dst_addr> <32bit_value0> [<32bit_value1>] [<32bit_value2>] [...]` ####

Write ("poke") <32bit_value0> to <dst_addr>, <32bit_value1> to <dst_addr+4>, ...

#### `r` ####

Dump registers as they were saved on entry.

#### `x` ####

Exit VMON (restore registers as they were saved on entry and then go to address in `ra`).

#### `/h <hex_value>` ####

Base conversion from hex. Prints value in hex, decimal, binary.

#### `/d <dec_value>` ####

Base conversion from signed decimal. Prints value in hex, decimal, binary.

#### `/b <bin_value>` ####

Base conversion from binary. Prints value in hex, decimal, binary.

### Numeric values ###

**All addresses and values are accepted in hex ("0x..."), binary ("0b..."), or decimal (no prefix).**

### Exceptions ###

VMON installs a trap handler (if running in M-mode) in order to catch exceptions. Exceptions are printed:

![Screenshot 2025-05-16 at 09 36 18](https://github.com/user-attachments/assets/f344bbd6-ae28-46a1-8e33-ba65f898c903)

## Known Problems

See [issues page](https://github.com/krakenlake/vmon/issues).

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
