# VMON - a RISC-V machine code monitor 

VMON is a tiny machine code monitor for RISC-V systems with UART 
communication written in RISC-V assembly language.

![Screenshot 2024-07-10 at 08 43 44](https://github.com/krakenlake/vmon/assets/119040831/bec982cd-4b34-4433-8ef7-bfcc173d30bd)

## Features
- hex and ASCII monitor 
- disassembler with hex and decimal output
- currently disassembles RV32/64IMA instructions 
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

**c <src_start> <src_end> <dst_addr>**   
copy memory contents

**d <start_addr>**   
disassemble 16 instructions starting at start_addr 

**d <start_addr> <end_addr>**   
disassemble from <start_addr> to <end_addr>

**d**   
continue disassembly from last address used

**f <start_addr> <end_addr> <byte_value>**   
find <byte_value> in memory from <start_addr> to <end_addr>

**g <start_addr>**   
start program execution at <start_addr>

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

**p <dst_addr> <byte_value>**   
write <byte_value> to <dst_addr>

## Known Problems
see [issues page](https://github.com/krakenlake/vmon/issues)
