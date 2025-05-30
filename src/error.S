#include "config.h"


.global error_param
.global error_unknown_command
.global error_break_table_full

.data


error_param:			.string "ERROR: parameter missing or invalid";
.size error_param, .-error_param

error_unknown_command:	.string "ERROR: unknown command";
.size error_unknown_command, .-error_unknown_command

#ifdef WITH_CMD_B
	error_break_table_full:	.string "ERROR: no more free breakpoints";
	.size error_break_table_full, .-error_break_table_full

	error_break_addr_invalid:	.string "ERROR: not a valid breakpoint address";
	.size error_break_addr_invalid, .-error_break_addr_invalid
#endif /* WITH_CMD_B */