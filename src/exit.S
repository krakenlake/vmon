#include "config.h"
#include "vmon/stack.h"
#include "vmon/trap.h"
#include "vmon/register.h"


#if defined (WITH_CMD_X) || defined (WITH_CMD_G)

.global vmon_exit

.text


vmon_exit:

	la		a0, string_jump
	jal		print_string
	jal		print_pc
	jal		print_newline
	
	# set xstatus.MPP to 0b11 so that xret in trap handler will stay in current mode
	#ifdef TARGET_HAS_Zicsr
		li		t0, 0b11 << 11
		csrs	MODE_PREFIX(status), t0
	#endif /* TARGET_HAS_Zicsr */

	j		exit_trap_handler
.size vmon_exit, .-vmon_exit


.section .rodata


string_jump:
	.string "exiting to ";
.size string_jump, .-string_jump


#endif /* defined (WITH_CMD_X) || defined (WITH_CMD_G) */
