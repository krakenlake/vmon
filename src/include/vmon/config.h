#ifndef VMON_CONFIG_H
#define VMON_CONFIG_H

// register width
#if XLEN == 32
	#define	SAVE_X	sw
	#define LOAD_X	lw
#endif
#if XLEN == 64
	#define	SAVE_X	sd
	#define LOAD_X	ld
#endif
#define XLEN_BYTES			(XLEN/8)

// this will include code that
// - sets up a stack
// - makes sure we are running on hart #0 only
#define BARE_METAL

// which user commands shall be in the binary?
#define WITH_CMD_D		// disassemble	
#define WITH_CMD_G		// go
#define WITH_CMD_H		// help
#define WITH_CMD_I		// info	
#define WITH_CMD_M		// memory dump
#define WITH_CMD_X		// exit

// if undefined, simply "x0...x31" will be used instead
#define ABI_REGISTER_NAMES

// include test code in the binary?
// if yes, the "i" command shows the location at runtime
#define WITH_TESTCODE

// enable M extension disassembly?
#define ENABLE_RVM

// enable A extension disassembly?
#define ENABLE_RVA

// enable F extension disassembly?
//#define ENABLE_RVF

// enable D extension disassembly?
//#define ENABLE_RVD

// enable Q extension disassembly?
//#define ENABLE_RVQ

// enable C extension disassembly?
//#define ENABLE_RVC

// enable B extension disassembly?
//#define ENABLE_RVB

// enable P extension disassembly?
//#define ENABLE_RVP

// enable V extension disassembly?
//#define ENABLE_RVV

// enable H extension disassembly?
//#define ENABLE_RVH


// enable Zicsr extension disassembly?
#define ENABLE_RVZicsr

// enable Zifencei extension disassembly?
#define ENABLE_RVZifencei

// enable printing of pseudo opcodes in disassembly?
#define ENABLE_PSEUDO

// default number of lines for the "d" command if no end address is given
#define	DEFAULT_D_LINES		16

// default number of lines for the "m" command if no end address is given
#define DEFAULT_M_LINES		16

// size of character input buffer in bytes
#define BUFFER_SIZE			128

// size of runtime stack in bytes
#define STACK_SIZE			1024

#endif /* VMON_CONFIG_H */