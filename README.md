# VMON - a RISC-V machine code monitor 

VMON is a tiny machine code monitor for RISC-V systems with UART 
communication written in RISC-V assembly language.

## Features
- hex and ASCII monitor 
- disassembler with hex and decimal output
- currently disassembles RV32/64IMA opcodes 
- (some) pseudo opcodes supported
- can be built for 32 or 64 bit targets
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
- make

## Running
- "make run" to run on QEMU

## Commands
VMON understands the following commands:  

**d <start_addr>**   
disassemble 16 instructions starting at start_addr 

**d <start_addr> <end_addr>**   
disassemble from <start_addr> to <end_addr>

**d**   
continue disassembly from last address used

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
