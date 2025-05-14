#include "vmon/config.h"


#ifdef WITH_CMD_X

.global cmd_X

.text


cmd_X:
	la		a0, string_exit
	jal		print_string
	LOAD_X	a0, 0(sp)
	jal		print_hex
	jal		print_newline

	#ifdef ENABLE_RVF
/*
		# restore float registers
		LOAD_F	f0, 0(sp)
		LOAD_F	f1, (XLEN_BYTES*1)(sp)
		LOAD_F	f2, (XLEN_BYTES*2)(sp)
		LOAD_F	f3, (XLEN_BYTES*3)(sp)
		LOAD_F	f4, (XLEN_BYTES*4)(sp)
		LOAD_F	f5, (XLEN_BYTES*5)(sp)
		LOAD_F	f6, (XLEN_BYTES*6)(sp)
		LOAD_F	f7, (XLEN_BYTES*7)(sp)
		LOAD_F	f8, (XLEN_BYTES*8)(sp)
		LOAD_F	f9, (XLEN_BYTES*9)(sp)
		LOAD_F	f10, (XLEN_BYTES*10)(sp)
		LOAD_F	f11, (XLEN_BYTES*11)(sp)
		LOAD_F	f12, (XLEN_BYTES*12)(sp)
		LOAD_F	f13, (XLEN_BYTES*13)(sp)
		LOAD_F	f14, (XLEN_BYTES*14)(sp)
		LOAD_F	f15, (XLEN_BYTES*15)(sp)
		LOAD_F	f16, (XLEN_BYTES*16)(sp)
		LOAD_F	f17, (XLEN_BYTES*17)(sp)
		LOAD_F	f18, (XLEN_BYTES*18)(sp)
		LOAD_F	f19, (XLEN_BYTES*19)(sp)
		LOAD_F	f20, (XLEN_BYTES*20)(sp)
		LOAD_F	f21, (XLEN_BYTES*21)(sp)
		LOAD_F	f22, (XLEN_BYTES*22)(sp)
		LOAD_F	f23, (XLEN_BYTES*23)(sp)
		LOAD_F	f24, (XLEN_BYTES*24)(sp)
		LOAD_F	f25, (XLEN_BYTES*25)(sp)
		LOAD_F	f26, (XLEN_BYTES*26)(sp)
		LOAD_F	f27, (XLEN_BYTES*27)(sp)
		LOAD_F	f28, (XLEN_BYTES*28)(sp)
		LOAD_F	f29, (XLEN_BYTES*29)(sp)
		LOAD_F	f30, (XLEN_BYTES*30)(sp)
		LOAD_F	f31, (XLEN_BYTES*31)(sp)
		addi	sp, sp, (XLEN_BYTES*32)
*/
	#endif /* ENABLE_RVF */

	# restore mepc
	#ifdef M_MODE
		LOAD_X	t0, 0(sp)	
		csrw	mepc, t0
		addi	sp, sp, (XLEN_BYTES*1)
	#endif /* M_MODE */ 

	# restore int registers
	LOAD_X	ra, 0(sp)
	LOAD_X	x3, (XLEN_BYTES*2)(sp)
	LOAD_X	x4, (XLEN_BYTES*3)(sp)
	LOAD_X	x5, (XLEN_BYTES*4)(sp)
	LOAD_X	x6, (XLEN_BYTES*5)(sp)
	LOAD_X	x7, (XLEN_BYTES*6)(sp)
	LOAD_X	x8, (XLEN_BYTES*7)(sp)
	LOAD_X	x9, (XLEN_BYTES*8)(sp)
	LOAD_X	x10, (XLEN_BYTES*9)(sp)
	LOAD_X	x11, (XLEN_BYTES*10)(sp)
	LOAD_X	x12, (XLEN_BYTES*11)(sp)
	LOAD_X	x13, (XLEN_BYTES*12)(sp)
	LOAD_X	x14, (XLEN_BYTES*13)(sp)
	LOAD_X	x15, (XLEN_BYTES*14)(sp)
	LOAD_X	x16, (XLEN_BYTES*15)(sp)
	LOAD_X	x17, (XLEN_BYTES*16)(sp)
	LOAD_X	x18, (XLEN_BYTES*17)(sp)
	LOAD_X	x19, (XLEN_BYTES*18)(sp)
	LOAD_X	x20, (XLEN_BYTES*19)(sp)
	LOAD_X	x21, (XLEN_BYTES*20)(sp)
	LOAD_X	x22, (XLEN_BYTES*21)(sp)
	LOAD_X	x23, (XLEN_BYTES*22)(sp)
	LOAD_X	x24, (XLEN_BYTES*23)(sp)
	LOAD_X	x25, (XLEN_BYTES*24)(sp)
	LOAD_X	x26, (XLEN_BYTES*25)(sp)
	LOAD_X	x27, (XLEN_BYTES*26)(sp)
	LOAD_X	x28, (XLEN_BYTES*27)(sp)
	LOAD_X	x29, (XLEN_BYTES*28)(sp)
	LOAD_X	x30, (XLEN_BYTES*29)(sp)
	LOAD_X	x31, (XLEN_BYTES*30)(sp)
	# the original sp from caller
	LOAD_X	sp, (XLEN_BYTES*1)(sp)
	# return control to caller
	ret
.size cmd_X, .-cmd_X


.data


string_exit:			.string "exiting: ret, ra=";
.size string_exit, .-string_exit

#endif /* WITH_CMD_X */
