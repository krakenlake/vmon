#include "config.h"
#include "vmon/stack.h"
#include "vmon/register.h"
#include "vmon/error.h"


#ifdef WITH_CMD_G

.global cmd_G

.text


cmd_G:
	jal		skip_whitespace
	jal		get_numeric					# read start addr from text buffer
	bnez	a2, cmd_G_error_params		# abort command if not found
	mv		s1, a1
	mv		a0, a1
	jal		is_valid_insn_addr
	beqz	a1, cmd_G_addr_valid
	li		a0, ERR_INSN_ADDR
	j		cmd_G_error
cmd_G_addr_valid:
	la		a0, string_go
	jal		print_string
	mv		a0, s1
	jal		print_hex

	# patch ra that was saved on the stack on entry, exit routine will load it later
	la		a0, stack + STACK_SIZE - STK_FRAME_SIZE_INT + STK_OFF_RA
	SAVE_X	s1, 0(a0)

	#ifdef WITH_CMD_B
		jal		break_activate			# activate all breakpoints
	#endif /* WITH_CMD_B */

	j		vmon_exit
cmd_G_error_params:
	li		a0, ERR_CMD_PARAMS
cmd_G_error:
	jal		print_error
	j		main_prompt
.size cmd_G, .-cmd_G


.data

string_go:	.string "jumping to ";
.size string_go, .-string_go


#endif /* WITH_CMD_G */
