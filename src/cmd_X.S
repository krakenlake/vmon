#include "config.h"
#include "vmon/register.h"


#ifdef WITH_CMD_X

.global cmd_X

.text


cmd_X:
	la		a0, string_exit
	jal		print_string
	la		a1, stack + STACK_SIZE - (XLEN_BYTES*31)
	LOAD_X	a0, 0(a1)
	jal		print_hex
	jal		print_newline
	j		vmon_exit
.size cmd_X, .-cmd_X


.data


string_exit:			.string "exiting: ret, ra=";
.size string_exit, .-string_exit

#endif /* WITH_CMD_X */
