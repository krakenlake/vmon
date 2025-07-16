#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/register.h"


#ifdef WITH_CMD_D

.global cmd_D

.text


cmd_D:
	jal		skip_whitespace
	jal		get_numeric					# read start addr from text buffer
	bnez	a2, cmd_D_from_last			# none given? continue from last saved addr
	mv		s0, a1						# save start addr of dump
	jal		skip_whitespace
	jal		get_numeric					# read start addr from text buffer
	mv		s1, a1						# save end addr of dump
	beqz	a2, cmd_D_next_instruction
	j		cmd_D_add_default 
cmd_D_from_last:
	# continue from last address used
	la		a1, last_address
	LOAD_X	s0, 0(a1)
cmd_D_add_default:
	# no end addr? use default 
	addi	s1, s0, DEFAULT_D_LINES*4-1			 
	li		tp, DEFAULT_D_LINES			# count lines as well (due to RVC)
	# start addr now in s0, end addr now in s1

cmd_D_next_instruction:
	# print memory address
	mv		a0, s0						# print current address
	jal		print_hex
	la		a0, string_asm_sep1
	jal		print_string
	
	# print word at this memory address
	LWU		a0, 0(s0)					# load instruction word
	li		a1, 4						# print 4 bytes
	li		a2, 0						# no "0x" prefix
	#ifdef DISASS_RVC
		jal		insn_is_compressed
		beqz	a0, cmd_D_word_not_RVC
		la		a0, string_WORD_ALIGN
		jal		print_string			# print 4 spaces for alignment
		li		a1, 2					# print only 2 bytes
	cmd_D_word_not_RVC:
		LWU		a0, 0(s0)
	#endif
	jal		print_hex_fixed_width

cmd_D_disass:
	la		a0, string_asm_sep2		
	jal		print_string
	# disassemble this word
	LWU		a0, 0(s0)					# load instruction word
	jal		get_data_by_insn_word
	beqz	a3, cmd_D_opcode_unknown
	jal		print_instruction
	j		cmd_D_advance
cmd_D_opcode_unknown:
	la		a0, string_OP_UNKNOWN
	jal		print_string
	j		cmd_D_advance
cmd_D_advance:
	LWU		a0, 0(s0)					# load instruction word
	addi	s0, s0, 4					# advance 4 bytes

	#ifdef DISASS_RVC
		jal		insn_is_compressed
		beqz	a0, cmd_D_check_end
		addi	s0, s0, -2				# go 2 bytes back if compressed
	#endif

cmd_D_check_end:
	bgt		s0, s1, cmd_D_done			# check if end address reached
	addi	tp, tp, -1
	beqz	tp, cmd_D_done				# check if default number of lines reached
cmd_D_check_end_no:
	jal		print_newline
	j		cmd_D_next_instruction
cmd_D_done:
	la		a0, last_address 
	SAVE_X	s0, 0(a0)
	j		main_prompt
.size cmd_D, .-cmd_D


string_OP_UNKNOWN:		.string "???";
.size string_OP_UNKNOWN, .-string_OP_UNKNOWN

#ifdef DISASS_RVC
	string_WORD_ALIGN:		.string "    ";
	.size string_WORD_ALIGN, .-string_WORD_ALIGN
#endif /* DISASS_RVC */

#endif /* WITH_CMD_D */
