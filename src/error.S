#include "config.h"
#include "vmon/register.h"
#include "vmon/error.h"


.global print_error


.text

#ifdef ERROR_VERBOSE
	# in: a0 = error code (0=none)
	print_error:
		addi	sp, sp, -(XLEN_BYTES*2)
		SAVE_X	s0, 0(sp)
		SAVE_X	ra, (XLEN_BYTES*1)(sp)
		beqz	a0, print_error_done		# done when errorcode == 0
		la		t0, error_table
		li		t2, 0xff					# table end marker
	print_error_next_entry:
		lbu		t1, 0(t0)					# load error code byte from table
		beq		t1, a0, print_error_do	
		beq		t1, t2, print_error_do		# last table entry?
	print_error_skip:
		# go to beginning of next enty
		addi	t0, t0, 1
		lbu		t1, 0(t0)
		bnez	t1, print_error_skip		# goto next zero
		addi	t0, t0, 1
		j		print_error_next_entry
	print_error_do:
		addi	s0, t0, 1
		la		a0, string_error_prefix
		jal		print_string
		mv		a0, s0
		jal		print_string
		jal		print_newline
	print_error_done:
		j		pop_s0_ra_ret
#else
	print_error:
		addi	sp, sp, -(XLEN_BYTES*2)
		SAVE_X	s0, 0(sp)
		SAVE_X	ra, (XLEN_BYTES*1)(sp)
		mv		s0, a0
		la		a0, string_error_prefix		
		jal		print_string
		mv		a0, s0
		li		a1, 1						# one byte
		li		a2, 1						# with prefix
		jal		print_hex_fixed_width
		jal		print_newline
	print_error_done:
		j		pop_s0_ra_ret
#endif /* ERROR_VERBOSE */

.data


error_unknown_command:	.string "ERROR: unknown command";
.size error_unknown_command, .-error_unknown_command

#ifdef WITH_CMD_B
	error_break_table_full:	.string "ERROR: no more free breakpoints";
	.size error_break_table_full, .-error_break_table_full

	error_break_addr_invalid:	.string "ERROR: not a valid breakpoint address";
	.size error_break_addr_invalid, .-error_break_addr_invalid
#endif /* WITH_CMD_B */


string_error_prefix:
.string "ERROR: "

#ifdef ERROR_VERBOSE
error_table:
# errorcode, string
.byte ERR_CMD_PARAMS;	.string "parameter missing or invalid"
.byte ERR_CMD_UNKNOWN;	.string "unknown command"
.byte ERR_BREAK_FULL;	.string "out of breakpoints"
.byte ERR_INSN_ADDR;	.string "not a valid instruction address"

.byte ERR_UNDEFINED;	.string "undefined error"
#endif /* ERROR_VERBOSE */