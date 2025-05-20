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
	# did user enter an int register name?
	jal 	get_int_register_index_by_name
	li		t0, 32
	bge		a0, t0, cmd_S_error
	li		t0, 1
	blt		a0, t0, cmd_S_try_float
	# user wants to set int register
	mv 		s0, a0						# now save index in s0
	# get int value
	addi	a0, s1, 1
	jal		skip_whitespace
	jal		get_numeric					# read value from text buffer
	bnez	a2, cmd_S_error				# abort if no value given
	# patch
	mv		a0, s0
	jal 	patch_int_register	
	j		main_prompt

cmd_S_try_float:
	# fall through to cmd_S_error if RVF not enabled

	#ifdef ENABLE_RVF
		# now try if the name is a float register
		mv		a0, s0
		mv		a1, s1
		jal 	get_float_register_index_by_name
		li		t0, 32
		bge		a0, t0, cmd_S_error
		bltz	a0, cmd_S_error	
		# user wants to set float register
		mv 		s0, a0						# now save index in s0
		# get float value
		addi	a0, s1, 1
		jal		skip_whitespace
		# the user input value will be taken bitwise as-is, so it usually
		# only makes sense to enter a hex or bin value here that has before been
		# created by converting a number into their IEEE 754 representation
		# by some external tool, for example:
		# https://www.h-schmidt.net/FloatConverter/IEEE754.html
		jal		get_numeric					# read value from text buffer
		bnez	a2, cmd_S_error				# abort if no value given
		# patch
		mv		a0, s0
		jal 	patch_float_register	
		j		main_prompt
	#endif

cmd_S_error:
	la		a0, error_param
	jal		print_string
	j		main_prompt
.size cmd_S, .-cmd_S


#endif /* WITH_CMD_S */
