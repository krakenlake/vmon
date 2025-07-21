#ifndef STACK_H
#define STACK_H

#include "config.h"
#include "vmon/register.h"


// this is actually enough at the moment, but might be tight for further extensions
#define STACK_SIZE_RUNTIME		32 * XLEN_BYTES


// stack space needed to save all registers on entry
// (x0 will not be saved, but slot will be used for PC instead)
#ifdef TARGET_HAS_RVF
	#define STACK_SIZE_REGISTERS			(XLEN_BYTES * NUM_INT_REGISTERS + FLEN_BYTES * NUM_FLOAT_REGISTERS)
#else
	#define STACK_SIZE_REGISTERS			(XLEN_BYTES * NUM_INT_REGISTERS)
#endif

#define STACK_SIZE				STACK_SIZE_RUNTIME + STACK_SIZE_REGISTERS


// int register offsets from start of int stack frame
// store pc in position 0; x0 is always 0 and will not be saved on stack
#define STK_OFF_PC		(0)
#define STK_OFF_X1		(XLEN_BYTES*1)
#define STK_OFF_X2		(XLEN_BYTES*2)
#define STK_OFF_X3		(XLEN_BYTES*3)
#define STK_OFF_X4		(XLEN_BYTES*4)
#define STK_OFF_X5		(XLEN_BYTES*5)
#define STK_OFF_X6		(XLEN_BYTES*6)
#define STK_OFF_X7		(XLEN_BYTES*7)
#define STK_OFF_X8		(XLEN_BYTES*8)
#define STK_OFF_X9		(XLEN_BYTES*9)
#define STK_OFF_X10		(XLEN_BYTES*10)
#define STK_OFF_X11		(XLEN_BYTES*11)
#define STK_OFF_X12		(XLEN_BYTES*12)
#define STK_OFF_X13		(XLEN_BYTES*13)
#define STK_OFF_X14		(XLEN_BYTES*14)
#define STK_OFF_X15		(XLEN_BYTES*15)
#define STK_OFF_X16		(XLEN_BYTES*16)
#define STK_OFF_X17		(XLEN_BYTES*17)
#define STK_OFF_X18		(XLEN_BYTES*18)
#define STK_OFF_X19		(XLEN_BYTES*19)
#define STK_OFF_X20		(XLEN_BYTES*20)
#define STK_OFF_X21		(XLEN_BYTES*21)
#define STK_OFF_X22		(XLEN_BYTES*22)
#define STK_OFF_X23		(XLEN_BYTES*23)
#define STK_OFF_X24		(XLEN_BYTES*24)
#define STK_OFF_X25		(XLEN_BYTES*25)
#define STK_OFF_X26		(XLEN_BYTES*26)
#define STK_OFF_X27		(XLEN_BYTES*27)
#define STK_OFF_X28		(XLEN_BYTES*28)
#define STK_OFF_X29		(XLEN_BYTES*29)
#define STK_OFF_X30		(XLEN_BYTES*30)
#define STK_OFF_X31		(XLEN_BYTES*31)

#define STK_FRAME_SIZE_INT		(XLEN_BYTES * NUM_INT_REGISTERS)

// aliases
#define STK_OFF_RA		(STK_OFF_X1)
#define STK_OFF_SP		(STK_OFF_X2)


// float register offsets from start of float stack frame
#define STK_OFF_F0		(0)
#define STK_OFF_F1		(FLEN_BYTES*1)
#define STK_OFF_F2		(FLEN_BYTES*2)
#define STK_OFF_F3		(FLEN_BYTES*3)
#define STK_OFF_F4		(FLEN_BYTES*4)
#define STK_OFF_F5		(FLEN_BYTES*5)
#define STK_OFF_F6		(FLEN_BYTES*6)
#define STK_OFF_F7		(FLEN_BYTES*7)
#define STK_OFF_F8		(FLEN_BYTES*8)
#define STK_OFF_F9		(FLEN_BYTES*9)
#define STK_OFF_F10		(FLEN_BYTES*10)
#define STK_OFF_F11		(FLEN_BYTES*11)
#define STK_OFF_F12		(FLEN_BYTES*12)
#define STK_OFF_F13		(FLEN_BYTES*13)
#define STK_OFF_F14		(FLEN_BYTES*14)
#define STK_OFF_F15		(FLEN_BYTES*15)
#define STK_OFF_F16		(FLEN_BYTES*16)
#define STK_OFF_F17		(FLEN_BYTES*17)
#define STK_OFF_F18		(FLEN_BYTES*18)
#define STK_OFF_F19		(FLEN_BYTES*19)
#define STK_OFF_F20		(FLEN_BYTES*20)
#define STK_OFF_F21		(FLEN_BYTES*21)
#define STK_OFF_F22		(FLEN_BYTES*22)
#define STK_OFF_F23		(FLEN_BYTES*23)
#define STK_OFF_F24		(FLEN_BYTES*24)
#define STK_OFF_F25		(FLEN_BYTES*25)
#define STK_OFF_F26		(FLEN_BYTES*26)
#define STK_OFF_F27		(FLEN_BYTES*27)
#define STK_OFF_F28		(FLEN_BYTES*28)
#define STK_OFF_F29		(FLEN_BYTES*29)
#define STK_OFF_F30		(FLEN_BYTES*30)
#define STK_OFF_F31		(FLEN_BYTES*31)

#define STK_FRAME_SIZE_FLOAT	(FLEN_BYTES * NUM_FLOAT_REGISTERS)


// function prologue/epilogue optimisation

#define PUSH_RA						jal		gp, push_ra
#define POP_RA_RET					j		pop_ra_ret

#define PUSH_S0_RA					jal		gp, push_s0_ra
#define POP_S0_RA_RET				j		pop_s0_ra_ret

#define PUSH_S1_S0_RA				jal		gp, push_s1_s0_ra
#define POP_S1_S0_RA_RET			j		pop_s1_s0_ra_ret

#define PUSH_TP_S1_S0_RA			jal		gp, push_tp_s1_s0_ra
#define POP_TP_S1_S0_RA_RET			j		pop_tp_s1_s0_ra_ret


#endif /* STACK_H */
