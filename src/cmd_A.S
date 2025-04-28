#include "vmon/config.h"
#include "vmon/ASCII.h"


#ifdef WITH_CMD_A

.global cmd_A

.text


cmd_A:
	# read dst_start from text buffer	
    jal     skip_whitespace
    jal     get_hex_addr            # read dst_start from text buffer
    bnez    a2, cmd_A_error         # abort command if not found
	mv		s0, a1
	
	# a3: dst_start

	# TODO: should we check for dst_start alignment?

cmd_A_input_loop:
	# print line prefix
    la      a0, string_line_prefix_A
    jal     print_string
	# print current dst_address
	mv      a0, s0
    jal     print_hex
	# print assembly input prompt
    la      a0, string_ass_prompt
    jal     print_string
	# get one line of asembly input (until ASCII_RETURN)
	jal		uart_getline
	#  buffer start in a0
	mv		s2, a0					# save for later
	li      a0, ASCII_NEWLINE
    jal     print_char
	# exit loop if line was empty
	mv		a0, s2
	jal		skip_whitespace
	lb		t0, 0(a0)
	li		t1, ASCII_RETURN
	beq		t0, t1, cmd_A_done
	# read input line and assemble one instruction
	mv		a0, s2
	jal		assemble_instruction
	bnez	a0, cmd_A_continue

	# user entered garbage in assembly line
    la      a0, string_ass_error
    jal     print_string
	j 		cmd_A_input_loop

cmd_A_continue:
	# instruction now in a1
	# store assembled instruction in memory at dst_address
	sw		a1, 0(s0)
	# advance dst addr			
	add		s0, s0, a0
	j		cmd_A_input_loop

cmd_A_error:
    la      a0, error_param
    jal     print_string
cmd_A_done:
    j       main_prompt
.size cmd_A, .-cmd_A


.data

string_line_prefix_A:   .string "A ";
.size string_line_prefix_A, .-string_line_prefix_A

string_ass_prompt:	.string " := ";
.size string_ass_prompt, .-string_ass_prompt

string_ass_error:	.string "\t\t???\n\r";
.size string_ass_error, .-string_ass_error

#endif /* WITH_CMD_A */
