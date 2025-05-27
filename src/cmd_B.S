#include "config.h"
#include "vmon/register.h"
#include "vmon/breakpoints.h"


#ifdef WITH_CMD_B

.global cmd_B

.text

cmd_B:
	lb		t1, 0(a0)					# read byte following b
	addi	a0, a0, 1
	li		t0, 's'
	beq		t0, t1, cmd_B_set
	li		t0, 'c'
	beq		t0, t1, cmd_B_clear
	li		t0, 'r'
	beq		t0, t1, cmd_B_reset
	addi	a0, a0, -1
cmd_B_list:
	jal		break_list
	j		cmd_B_done
cmd_B_set:
	# add one breakpoint to bp_table
	jal		skip_whitespace
	jal		get_numeric					# read addr from text buffer
	bnez	a2, cmd_B_error				# abort command if not found
	mv		a0, a1
	jal		break_set
	j		cmd_B_done
cmd_B_clear:
	# remove one breakpoint from bp_table
	jal		skip_whitespace
	jal		get_numeric					# read addr from text buffer
	bnez	a2, cmd_B_error				# abort command if not found
	mv		a0, a1
	jal		break_clear
	j		cmd_B_done
cmd_B_reset:
	# remove all breakpoints from bp_table
	jal		break_reset
	j		cmd_B_done
cmd_B_error:
	la		a0, error_param
	jal		print_string
cmd_B_done:
	j		main_prompt
.size cmd_B, .-cmd_B



#endif /* WITH_CMD_B */
