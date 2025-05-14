#include "vmon/config.h"


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
	
	# TODO: restore registers
	
	# TODO make this a far call
	
	jalr	ra, s1, 0
	j		start					# start over if the call returns
cmd_G_error:
	la		a0, error_param
	jal		print_string
	j		main_prompt
.size cmd_G, .-cmd_G


.data

string_go:	.string "jumping to ";
.size string_go, .-string_go


#endif /* WITH_CMD_G */
