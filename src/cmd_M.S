#include "vmon/config.h"
#include "vmon/ASCII.h"


#ifdef WITH_CMD_M

.global cmd_M

.text


cmd_M:
	jal		skip_whitespace
	jal		get_hex_addr			# read start addr from text buffer
	bnez	a2, cmd_M_from_last		# none given? continue from last saved addr
	mv		s5, a1					# save start addr of dump
	jal		skip_whitespace
	jal		get_hex_addr			# read end addr from text buffer
	mv		s7, a1					# save end addr of dump
	beqz	a2, cmd_M_next_line
	j		cmd_M_add_default 
cmd_M_from_last:
	# continue from last address used
	la		a1, last_address
	# TODO: this is messy
	LOAD_X	s5, 0(a1)
cmd_M_add_default:
	# no end addr? use default
	addi	s7, s5, DEFAULT_M_LINES*8-1	 
	# start addr now in s5, end addr now in s7
cmd_M_next_line:
	mv		a0, s5
	jal		print_hex
	li		a0, ':'
	jal		print_char
	# output hex bytes 
	addi	s6, s5, 8				# set end addr for output line
cmd_M_next_byte:
	beq		s5, s6, cmd_M_print_ascii  
	li		a0, ' '
	jal		print_char
	lbu		a0, 0(s5)				# get byte from memory address
	jal		print_hex_byte
	addi	s5, s5, 1
	j		cmd_M_next_byte
	# output the same hex bytes again, this time as ASCII chars
cmd_M_print_ascii:
	addi	s5, s5, -8
	li		a0, ' '
	jal		print_char
cmd_M_next_char:
	beq		s5, s6, cmd_M_ascii_done
	lbu		a0, 0(s5)			   # get byte from memory address
	jal		print_ascii
	addi	s5, s5, 1
	j		cmd_M_next_char
cmd_M_ascii_done:
	bgt		s5, s7, cmd_M_done
	jal		print_newline
	j		cmd_M_next_line
cmd_M_done:
	la		a0, last_address 
	SAVE_X	s5, 0(a0)
	j		main_prompt
.size cmd_M, .-cmd_M

#endif /* WITH_CMD_M */
