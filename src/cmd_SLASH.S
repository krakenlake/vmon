#include "vmon/config.h"


#ifdef WITH_CMD_SLASH

.global cmd_SLASH

.text


cmd_SLASH:
    lb		t1, 0(a0)	# read byte following 'B'
	addi	a0, a0, 1
	li		t0, 'h'
	beq		t0, t1, cmd_slash_read_hex
	li		t0, 'd'
	beq		t0, t1, cmd_slash_read_dec
	li		t0, 'b'
	beq		t0, t1, cmd_slash_read_bin

cmd_slash_error:
	la		a0, error_param
	jal		print_string
	j		cmd_slash_end

cmd_slash_read_hex:
	jal		skip_whitespace
	jal		get_hex_addr
	bnez	a2, cmd_slash_error
	j		cmd_slash_display

cmd_slash_read_dec:
	jal		skip_whitespace
	jal		parse_decimal
	bnez	a2, cmd_slash_error
	j		cmd_slash_display

cmd_slash_read_bin:
	jal		skip_whitespace
	jal		parse_binary
	bnez	a2, cmd_slash_error
	j		cmd_slash_display

cmd_slash_display:
	mv		s0, a1
	la		a0, string_info_hex
	jal		print_string
	mv		a0, s0
	li		a1, XLEN_BYTES
	li		a2, 1
	call	print_hex_fixed_width
	la		a0, string_info_dec
	jal		print_string
	mv		a0, s0
	jal		print_decimal
	la		a0, string_info_bin
	jal		print_string
	mv		a0, s0
	jal		print_binary
	jal		print_newline
cmd_slash_end:
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
	
.size cmd_SLASH, .-cmd_SLASH

#endif /* WITH_CMD_SLASH */
