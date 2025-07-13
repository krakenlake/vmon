#include "config.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_X

.global cmd_X

.text


cmd_X:
	la		a0, string_exit
	jal		print_string

	#ifdef TARGET_HAS_RVF
		LOAD_X	a0, (STK_FRAME_SIZE_FLOAT + STK_OFF_PC)(sp)
	#else
		LOAD_X	a0, (STK_OFF_PC)(sp)
	#endif

	jal		print_hex
	jal		print_newline
	j		vmon_exit
.size cmd_X, .-cmd_X


.data


string_exit:			.string "exiting to ";
.size string_exit, .-string_exit

#endif /* WITH_CMD_X */
