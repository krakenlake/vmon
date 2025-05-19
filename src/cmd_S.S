#include "vmon/config.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_S

.global cmd_S

.text


cmd_S:
	jal		skip_whitespace
	# get register
	mv		s0, a0						# save string start
	jal		find_register_name_end
	mv		a1, a0
	mv		a0, s0
	mv		s1, a1
	jal 	get_int_register_index_by_name
	bltz	a0, cmd_S_error
	li		t0, 32
	bge		a0, t0, cmd_S_error
	mv 		s0, a0						# now save index in s0
	# get value
	addi	a0, s1, 1
	jal		skip_whitespace
	jal		get_numeric					# read start addr from text buffer
	bnez	a2, cmd_S_error				# abort command if not found
	# patch
	mv		a0, s0
	jal 	patch_int_register	
	j		main_prompt
cmd_S_error:
	la		a0, error_param
	jal		print_string
	j		main_prompt
.size cmd_S, .-cmd_S


#endif /* WITH_CMD_S */
