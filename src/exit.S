#include "config.h"
#include "vmon/stack.h"
#include "vmon/register.h"


#if defined (WITH_CMD_X) || defined (WITH_CMD_G)

.global vmon_exit

.text


vmon_exit:

	la		a0, string_jump
	jal		print_string
	jal		print_pc
	jal		print_newline
	
	# set mstatus.MPP to 0b11 so that mret below will stay in M-mode
	#ifdef M_MODE
		#ifdef TARGET_HAS_Zicsr
			li		t0, 0b11 << 11
			csrs	mstatus, t0
		#endif /* TARGET_HAS_Zicsr */
	#endif /* M_MODE */ 

	#ifdef TARGET_HAS_RVF
		# restore float registers
		LOAD_F	f0, (STK_OFF_F0)(sp)
		LOAD_F	f1, (STK_OFF_F1)(sp)
		LOAD_F	f2, (STK_OFF_F2)(sp)
		LOAD_F	f3, (STK_OFF_F3)(sp)
		LOAD_F	f4, (STK_OFF_F4)(sp)
		LOAD_F	f5, (STK_OFF_F5)(sp)
		LOAD_F	f6, (STK_OFF_F6)(sp)
		LOAD_F	f7, (STK_OFF_F7)(sp)
		LOAD_F	f8, (STK_OFF_F8)(sp)
		LOAD_F	f9, (STK_OFF_F9)(sp)
		LOAD_F	f10, (STK_OFF_F10)(sp)
		LOAD_F	f11, (STK_OFF_F11)(sp)
		LOAD_F	f12, (STK_OFF_F12)(sp)
		LOAD_F	f13, (STK_OFF_F13)(sp)
		LOAD_F	f14, (STK_OFF_F14)(sp)
		LOAD_F	f15, (STK_OFF_F15)(sp)
		LOAD_F	f16, (STK_OFF_F16)(sp)
		LOAD_F	f17, (STK_OFF_F17)(sp)
		LOAD_F	f18, (STK_OFF_F18)(sp)
		LOAD_F	f19, (STK_OFF_F19)(sp)
		LOAD_F	f20, (STK_OFF_F20)(sp)
		LOAD_F	f21, (STK_OFF_F21)(sp)
		LOAD_F	f22, (STK_OFF_F22)(sp)
		LOAD_F	f23, (STK_OFF_F23)(sp)
		LOAD_F	f24, (STK_OFF_F24)(sp)
		LOAD_F	f25, (STK_OFF_F25)(sp)
		LOAD_F	f26, (STK_OFF_F26)(sp)
		LOAD_F	f27, (STK_OFF_F27)(sp)
		LOAD_F	f28, (STK_OFF_F28)(sp)
		LOAD_F	f29, (STK_OFF_F29)(sp)
		LOAD_F	f30, (STK_OFF_F30)(sp)
		LOAD_F	f31, (STK_OFF_F31)(sp)
		addi	sp, sp, (STK_FRAME_SIZE_FLOAT)
	#endif /* TARGET_HAS_RVF */

	# restore mepc
	#ifdef M_MODE
		#ifdef TARGET_HAS_Zicsr
			LOAD_X	t0, STK_OFF_PC(sp)
			# advance one instruction
			# todo: check for RVC
#			addi	t0, t0, 4
			csrw	mepc, t0
		#endif /* TARGET_HAS_Zicsr */
	#endif /* M_MODE */ 
	
	# restore int registers
	LOAD_X	ra, (STK_OFF_RA)(sp)
	# sp intentionally left out here, do below
	LOAD_X	x3, (STK_OFF_X3)(sp)
	LOAD_X	x4, (STK_OFF_X4)(sp)
	LOAD_X	x5, (STK_OFF_X5)(sp)
	LOAD_X	x6, (STK_OFF_X6)(sp)
	LOAD_X	x7, (STK_OFF_X7)(sp)
	LOAD_X	x8, (STK_OFF_X8)(sp)
	LOAD_X	x9, (STK_OFF_X9)(sp)
	LOAD_X	x10, (STK_OFF_X10)(sp)
	LOAD_X	x11, (STK_OFF_X11)(sp)
	LOAD_X	x12, (STK_OFF_X12)(sp)
	LOAD_X	x13, (STK_OFF_X13)(sp)
	LOAD_X	x14, (STK_OFF_X14)(sp)
	LOAD_X	x15, (STK_OFF_X15)(sp)
	#ifndef TARGET_RVE
		LOAD_X	x16, (STK_OFF_X16)(sp)
		LOAD_X	x17, (STK_OFF_X17)(sp)
		LOAD_X	x18, (STK_OFF_X18)(sp)
		LOAD_X	x19, (STK_OFF_X19)(sp)
		LOAD_X	x20, (STK_OFF_X20)(sp)
		LOAD_X	x21, (STK_OFF_X21)(sp)
		LOAD_X	x22, (STK_OFF_X22)(sp)
		LOAD_X	x23, (STK_OFF_X23)(sp)
		LOAD_X	x24, (STK_OFF_X24)(sp)
		LOAD_X	x25, (STK_OFF_X25)(sp)
		LOAD_X	x26, (STK_OFF_X26)(sp)
		LOAD_X	x27, (STK_OFF_X27)(sp)
		LOAD_X	x28, (STK_OFF_X28)(sp)
		LOAD_X	x29, (STK_OFF_X29)(sp)
		LOAD_X	x30, (STK_OFF_X30)(sp)
		LOAD_X	x31, (STK_OFF_X31)(sp)
	#endif /* TARGET_RVE */

	# restore original sp saved from caller on entry
	LOAD_X	sp, (STK_OFF_SP)(sp)

	# bye bye - jump to address in mepc (while staying in M-mode, see above)
	mret

.size vmon_exit, .-vmon_exit


string_jump:	.string "jumping to ";
.size string_jump, .-string_jump


#endif /* defined (WITH_CMD_X) || defined (WITH_CMD_G) */
