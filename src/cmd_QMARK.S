#include "vmon/config.h"
#include "vmon/register.h"


#ifdef WITH_CMD_QMARK

.global cmd_QMARK

.text

cmd_QMARK:
	jal		skip_whitespace
	jal		get_numeric
	bnez	a2, cmd_QMARK_error

cmd_QMARK_display:
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
	j		cmd_QMARK_end

cmd_QMARK_error:
	la		a0, error_param
	jal		print_string

cmd_QMARK_end:
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
	
.size cmd_QMARK, .-cmd_QMARK

#endif /* WITH_cmd_QMARK */
