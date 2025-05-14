#ifndef VMON_CONFIG_H
#define VMON_CONFIG_H

// int register width
#if XLEN == 32
	#define	SAVE_X	sw
	#define LOAD_X	lw
#endif
#if XLEN == 64
	#define	SAVE_X	sd
	#define LOAD_X	ld
#endif
#define XLEN_BYTES			(XLEN/8)

// float register width
#if FLEN == 32
	#define SAVE_F	fsw
	#define LOAD_F	flw
#endif
#if FLEN == 64
	#define	SAVE_F	fsd
	#define LOAD_F	fld
#endif
#define FLEN_BYTES			(FLEN/8)

// always use only one of these
#define M_MODE
//#define S_MODE
//#define U_MODE

// which user commands shall be in the binary?
#define WITH_CMD_A			// assemble	
#define WITH_CMD_C			// copy memory	
#define WITH_CMD_D			// disassemble	
#define WITH_CMD_F			// find
#define WITH_CMD_G			// go
#define WITH_CMD_H			// help
#define WITH_CMD_I			// info	
#define WITH_CMD_M			// memory dump
#define WITH_CMD_P			// poke
#define WITH_CMD_R			// register dump
#define WITH_CMD_X			// exit
#define WITH_CMD_SLASH		// base conversion	

// if undefined, simply "x0...x31" will be used instead
#define ABI_REGISTER_NAMES
// if this is defined, "fp" will be used for x8 instead of "s0"
//#define ABI_REGISTER_NAMES_X8_FP

// include test code in the binary?
// if yes, the "i" command shows the location at runtime
#define WITH_TESTCODE

// configure which parts of the test code will be present
// in the executable
#define WITH_TESTCODE_RV32I
#define WITH_TESTCODE_RV64I
#define WITH_TESTCODE_RVM
#define WITH_TESTCODE_RVA
#define WITH_TESTCODE_RVF
//#define WITH_TESTCODE_RVD
//#define WITH_TESTCODE_RVQ
//#define WITH_TESTCODE_RVC
//#define WITH_TESTCODE_RVB
//#define WITH_TESTCODE_RVP
//#define WITH_TESTCODE_RVV
//#define WITH_TESTCODE_RVH
#define WITH_TESTCODE_RVZicsr
#define WITH_TESTCODE_RVZifencei
#define WITH_TESTCODE_RVPRIV
#define WITH_TESTCODE_PSEUDO

// configure which instructions and extensions the
// executable will recognize 
#define ENABLE_RVM
#define ENABLE_RVA
#define ENABLE_RVF
//#define ENABLE_RVD
//#define ENABLE_RVQ
//#define ENABLE_RVC
//#define ENABLE_RVB
//#define ENABLE_RVP
//#define ENABLE_RVV
//#define ENABLE_RVH
#define ENABLE_RVZicsr
#define ENABLE_RVZifencei
#define ENABLE_RVPRIV

// enable printing of pseudo opcodes in disassembly?
#define ENABLE_PSEUDO

// include strings for MCAUSE verbose output?
#define MCAUSE_VERBOSE

// default number of lines for the "d" command if no end address is given
#define	DEFAULT_D_LINES		16

// default number of lines for the "m" command if no end address is given
#define DEFAULT_M_LINES		16

// print a space after commas in disassembler output
#define SPACE_AFTER_COMMA

// print a CR before each LF
// Note: at higher levels this varies by system but at this level most
// things expect both.
#define USE_CRLF

// size of character input buffer in bytes
#define BUFFER_SIZE			128

// size of runtime stack in bytes
#define STACK_SIZE			1024

#endif /* VMON_CONFIG_H */
