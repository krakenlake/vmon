#include "vmon/config.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_S

.global cmd_S

.text


cmd_S:
	jal		skip_whitespace
	
	# get register
	
	jal		skip_whitespace
	jal		get_numeric			# read start addr from text buffer
	bnez	a2, cmd_S_error			# abort command if not found
	mv		s1, a1


	mv		a0, s1
	jal		print_hex

	# patch register that was saved on the stack on entry

	j		vmon_exit
cmd_S_error:
	la		a0, error_param
	jal		print_string
	j		main_prompt
.size cmd_S, .-cmd_S


#endif /* WITH_CMD_S */
