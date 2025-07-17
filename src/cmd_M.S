#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/register.h"


#ifdef WITH_CMD_M

#ifndef M_BYTES_PER_LINE
	#define M_BYTES_PER_LINE 8
#endif


.global cmd_M


.text


cmd_M:
	jal		skip_whitespace
	jal		get_numeric						# read start addr from text buffer
	bnez	a2, cmd_M_from_last				# none given? continue from last saved addr
	mv		s0, a1							# save start addr of dump
	jal		skip_whitespace
	jal		get_numeric						# read end addr from text buffer
	mv		tp, a1							# save end addr of dump
	beqz	a2, cmd_M_next_line
	j		cmd_M_add_default 
cmd_M_from_last:
	# continue from last address used
	la		a1, last_address
	# TODO: this is messy
	LOAD_X	s0, 0(a1)
cmd_M_add_default:
	# no end addr? use default
	addi	tp, s0, DEFAULT_M_LINES*8-1	 
	# start addr now in s0, end addr now in tp

cmd_M_next_line:
	mv		a0, s0
	jal		print_hex
	li		a0, ':'
	jal		print_char
	# output hex bytes 
	addi	s1, s0, M_BYTES_PER_LINE		# set end addr for output line
cmd_M_next_byte:
	beq		s0, s1, cmd_M_print_ascii
	jal		print_space
	lbu		a0, 0(s0)						# get byte from memory address
	jal		print_hex_byte
	addi	s0, s0, 1
	j		cmd_M_next_byte
	# output the same hex bytes again, this time as ASCII chars
cmd_M_print_ascii:
	addi	s0, s0, -M_BYTES_PER_LINE
	jal		print_space
cmd_M_next_char:
	beq		s0, s1, cmd_M_ascii_done
	lbu		a0, 0(s0)						# get byte from memory address
	jal		print_ascii
	addi	s0, s0, 1
	j		cmd_M_next_char
cmd_M_ascii_done:
	bgt		s0, tp, cmd_M_done
	jal		print_newline
	j		cmd_M_next_line

cmd_M_done:
	la		a0, last_address 
	SAVE_X	s0, 0(a0)
	j		main_prompt
.size cmd_M, .-cmd_M

#endif /* WITH_CMD_M */
