#include "vmon/config.h"


#ifdef WITH_CMD_B

.global cmd_B

.text


cmd_B:
    lb		t1, 0(a0)	# read byte following 'B'
	addi	a0, a0, 1
	li		t0, 'h'
	beq		t0, t1, cmd_B_read_hex
	li		t0, 'd'
	beq		t0, t1, cmd_B_read_dec
	li		t0, 'b'
	beq		t0, t1, cmd_B_read_bin

cmd_B_error:
	la		a0, error_param
	jal		print_string
	j		main_prompt

cmd_B_read_hex:
	jal		skip_whitespace
	jal		get_hex_addr
	bnez	a2, cmd_B_error
	j		cmd_B_display

cmd_B_read_dec:
	j		cmd_B_display	# XXX: not yet implemented

cmd_B_read_bin:
	j		cmd_B_display	# XXX: not yet implemented

cmd_B_display:
	addi	sp, sp, -(XLEN_BYTES*1) # XXX: should I also save ra? or no need as we j to main_prompt?
	SAVE_X	s0, 0(sp)
	mv		s0, a1
	la		a0, string_info_hex
	jal		print_string
	mv		a0, s0
	jal		print_hex
	la		a0, string_info_dec
	jal		print_string
	mv		a0, s0
	jal		print_decimal
	la		a0, string_info_bin
	jal		print_string
	mv		a0, s0
	jal		print_binary
	jal		print_newline
	LOAD_X	s0, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	j		main_prompt

string_info_hex:
	.string	"hex: "
.size string_info_hex, .-string_info_hex
string_info_dec:
	.string " dec: "
.size string_info_dec, .-string_info_dec
string_info_bin:
	.string " bin: "
.size string_info_bin, .-string_info_bin
	
.size cmd_B, .-cmd_B

#endif /* WITH_CMD_B */
