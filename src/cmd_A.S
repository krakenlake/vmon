#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/error.h"


#ifdef WITH_CMD_A

.global cmd_A

.text


cmd_A:
	# read dst_start from text buffer	
	jal		skip_whitespace
	jal		get_numeric						# read dst_start from text buffer
	bnez	a2, cmd_A_error_params			# abort command if not found
	mv		s0, a1

	mv		a0, a1
	jal		is_valid_insn_addr
	beqz	a1, cmd_A_input_loop
	li		a0, ERR_INSN_ADDR
	j		cmd_A_error

cmd_A_input_loop:
	# print line prefix
	la		a0, string_line_prefix_A
	jal		print_string
	# print current dst_address
	mv		a0, s0
	jal		print_hex
	# print assembly input prompt
	la		a0, string_ass_prompt
	jal		print_string
	# get one line of asembly input (until ASCII_RETURN)
	jal		uart_getline
	# buffer start in a0
	# exit loop if line was empty
	jal		skip_whitespace
	lb		t0, 0(a0)
	li		t1, ASCII_RETURN
	beq		t0, t1, cmd_A_done
	# read input line and assemble one instruction
	mv		a2, s0							# current memory address
	jal		assemble_instruction
	# insn now in a1
	beqz	a0, cmd_A_assembly_error

#ifdef DISASS_RVC
		mv		a0, a1
		jal		insn_is_compressed
		beqz	a0, cmd_A_write_4_bytes

cmd_A_write_2_bytes:
		sh 		a1, 0(s0)
		addi	s0, s0, 2
		j 		cmd_A_input_loop
#endif

cmd_A_write_4_bytes: 
	sw		a1, 0(s0)
	addi		s0, s0, 4
	j 		cmd_A_input_loop

cmd_A_assembly_error:
	# user entered garbage in assembly line
	la		a0, string_ass_error
	jal		print_string

cmd_A_error_params:
	li		a0, ERR_CMD_PARAMS
cmd_A_error:
	jal		print_error
cmd_A_done:
	j		main_prompt
.size cmd_A, .-cmd_A


string_line_prefix_A:	.string "A ";
.size string_line_prefix_A, .-string_line_prefix_A

string_ass_prompt:		.string " := ";
.size string_ass_prompt, .-string_ass_prompt

string_ass_error:		.string "\t\t???\n\r";
.size string_ass_error, .-string_ass_error


#endif /* WITH_CMD_A */
