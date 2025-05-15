#include "vmon/config.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_G

.global cmd_G

.text


cmd_G:
	jal		skip_whitespace
	jal		get_hex_addr			# read start addr from text buffer
	bnez	a2, cmd_G_error			# abort command if not found
	mv		s1, a1
	la		a0, string_go
	jal		print_string
	mv		a0, s1
	jal		print_hex

	# patch ra that was saved on the stack on entry, exit routine will load it later
	la		a0, stack + STACK_SIZE - STK_FRAME_SIZE_INT + STK_OFF_RA
	SAVE_X	s1, 0(a0)

	j		vmon_exit
cmd_G_error:
	la		a0, error_param
	jal		print_string
	j		main_prompt
.size cmd_G, .-cmd_G


.data

string_go:	.string "jumping to ";
.size string_go, .-string_go


#endif /* WITH_CMD_G */
