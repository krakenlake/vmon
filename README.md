# VMON - a RISC-V machine code monitor

VMON is a tiny machine code monitor for RISC-V systems with UART
communication written entirely in RISC-V assembly language.

![Screenshot 2025-05-16 at 00 02 59](https://github.com/user-attachments/assets/d5b9390c-b760-4423-af9e-ff9bced5b0a2)

## Features

- hex and ASCII memory dump
- disassembler with hex/dec output
- assembler with hex/dec/bin input
- RV64GC instructions supported (prepared for RV128)
- (some) pseudo instructions supported
- hex/dec/bin conversion
- searching in memory areas
- copying memory areas
- exception catching
- can be built for RV32/RV64/RV128 targets
- runs in QEMU or on RISC-V hardware
- runs in M-mode or S-mode
- runs bare-metal or can be called from outside
- terminal I/O via UART
- set of included commands configurable in build process
- supported ISA and extensions configurable in build process
- executable can be built with or without RISC-V example code included

## Requirements

- riscv32/riscv64 GNU toolchain for building (depending on target)

- Make to build executables
- QEMU or RISC-V hardware to run on

## Building

- choose one of the `TARGET`s in Makefile (or set up a new one)
- review `config/config.<TARGET>.h` and define/undefine to taste
- review `src/include/vmon/UART.h` for target UART settings
- `make`

## Configuration Options

### Commands

You can use the `WITH_CMD_...` definitions to configure the set of commands that a specific version of VMON shall include. This is useful for systems with very small memory - you may configure your build to include only those commands that you need and you can leave chatty ones like `i` or `h` (which come with a lot of ASCII data) out.

### Register Names

Define `ABI_REGISTER_NAMES` if you want to work with ABI register names in VMON, otherwise `x0`-`x31` will be used.

### Test Code

Use the `WITH_TESTCODE_...`definitions to configure what test code will be in your executable.

### Supported Instructions

Use the `DISASS_...` definitions to define which set of instructions you will be able
to assemble/disassemble using VMON.

Note regarding RVC: As additonally supporting to assemble/disassemble RVC instructions
makes the matter quite a bit more complex, an executable that supports RVC will be
considerably larger. So, on systems that support RVC and have small memory, there are
two options:

1. Add RVC support, be able to assemble/disassemble RVC instructions but have a larger executable
2. Do not add RVC support, work with non-RVC instructions only (which makes for larger
hand-written assembly code), but have a smaller executable

So, choose your poison wisely.

## Running

- `make run` to run on QEMU

## Using VMON

### Command Line ###

VMON understands the following commands:  

#### `a <start_addr>` ####

Assembly input (press ENTER to stop) [still testing, so proceed with caution].

#### `b` ####

List all breakpoints (fixed number of max. 8 breakpoints available).

#### `bc <addr>` ####

Clear breakpoint at given address.

#### `br <addr>` ####

Reset (clear) all breakpoints.

#### `bs <addr>` ####

Set a breakpoint at given address. If the max. number of breakpoints has already been
reached, the breakpoint will not be set. Only valid instruction adresses are accepted
(4 byte alignment, or 2 byte alignment if RVC is enabled).
If the given breakpoint address is not read/write-accessible to VMON, this will cause
an exception later when command `g` is executed, as the `g` command will try to
activate all breakpoints by saving the original instructions at all breakpoint addresses
and overwriting them with `ebreak` instructions. VMON will restore the original instructions
when coming back to the command line.

#### `c <src_start> <src_end> <dst_addr>` ####

Copy memory contents. This also works correctly when both areas overlap.

#### `d [<start_addr>] [<end_addr]>` ####

Disassemble from <start_addr> to <end_addr> [still testing, so proceed with caution].
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

Go to <start_addr>.
Restore registers as they were saved on entry and execute `j <start_addr>`).
Breakpoints will be activated.

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
(in little endian order)

#### `r` ####

Dump registers as they were saved on entry.

#### `s <register_name> <numeric value>` ####

Set the value of a register. For float registers, the effective bit pattern will 
be taken as-is, so for example in order to set a float register to the value "42.0", you actually need to enter "s ft0 0x42280000", as 0x42280000 is a IEEE 754
representation of that value.

#### `x` ####

Exit VMON.
Restore registers and pc as they were saved on entry.
Breakpoints will not be activated.

#### `? <numeric_value>` ####

Print <numeric_value> in hex, decimal and binary representation.
<numeric_value> will be interpreted as hex, if it starts with "0x",
and it will be interpreted as binary, if it starts with "0b".
Otherwise, it will be interpreted as decimal.

#### Numeric values ####

**All addresses and values are accepted in hex ("0x..."), binary ("0b..."), or decimal (no prefix).**

### Assembler input ###

The `a` command switches to assembly input mode. The given memory address will be printed and an instruction
can be entered at the prompt. If the instruction syntax is valid, the instruction word will be 
assembled and stored at the indicated memory address, the current address will be incremented by the 
size of the instruction and the next instruction can be entered.

#### Register names ####

VMON accepts the defined RISC-V syntax for instructions and registers. Registers can either be referred to
by `x0`-`x31` or by their ABI names `zero`, `ra`, `sp`, ... `t6`. What flavour of register naming VMON accepts
is configured at compile time by setting `ABI_REGISTER_NAMES`in `config.h`.

#### Jump addresses ####

Target addresses for branch instructions and `JAL` are encoded into the instructions as offsets, but
for convenience expected to be entered here as absolute addresses, for example:

<img width="643" alt="Screenshot 2025-05-21 at 16 36 56" src="https://github.com/user-attachments/assets/7966a45b-c659-4bd5-a676-54ce9b049976" />


Offsets for `JALR` are expected as relative offsets:

<img width="644" alt="Screenshot 2025-05-21 at 16 39 00" src="https://github.com/user-attachments/assets/44188f23-1482-4d14-af6c-3de6edad31b9" />


### Exceptions ###

VMON installs a trap handler in order to catch exceptions. Exceptions are printed:

![Screenshot 2025-05-16 at 09 36 18](https://github.com/user-attachments/assets/f344bbd6-ae28-46a1-8e33-ba65f898c903)

VMON can only enable the trap handler during startup if the executable contains the trap
handler (default if possible), the target platform implements the Zicsr extension and the
executable runs in M-mode.

### Stack handling ###
If VMON is running in M-mode, it will set up its own stack on startup.
Otherwise, the incoming `sp` from the caller will be used.
In any case, all integer and float registers will be saved on the stack on entry and restored on exit. 
The saved registers can be printed using the `r`command and modified using the `s` command.

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
