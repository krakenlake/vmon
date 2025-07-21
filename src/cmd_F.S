#include "config.h"
#include "vmon/register.h"
#include "vmon/error.h"


#ifdef WITH_CMD_F

.global cmd_F

#define		MASK_BYTE			0xff
#define		MASK_HALFWORD		0xffff
#define		MASK_WORD			0xffffffff

.text


cmd_F:
	lb		t1, 0(a0)					# read byte following f
	addi	a0, a0, 1
	li		t0, 'b'
	beq		t0, t1, cmd_F_find_b
	li		t0, 'h'
	beq		t0, t1, cmd_F_find_h
	li		t0, 'w'
	beq		t0, t1, cmd_F_find_w
	addi	a0, a0, -1

cmd_F_find_b:
	li		s0, MASK_BYTE
	j	cmd_F_read_start
cmd_F_find_h:
	li		s0, MASK_HALFWORD
	j	cmd_F_read_start
cmd_F_find_w:
	li		s0, MASK_WORD

cmd_F_read_start:
	# read src_start from text buffer
	jal		skip_whitespace
	jal		get_numeric					# read start_addr from text buffer
	bnez	a2, cmd_F_error				# abort command if not found
	mv		s1, a1

	# read src_end from text buffer
	jal		skip_whitespace
	jal		get_numeric					# read end_addr from text buffer
	bnez	a2, cmd_F_error				# abort command if not found
	mv		a4, a1

	# read search value from text buffer
	jal		skip_whitespace
	jal		get_numeric
	bnez	a2, cmd_F_error				# abort command if not found
	mv		a5, a1

	# s1: src_start
	# a4: src_end
	# a5: value to search for
	# s0: mask

cmd_F_loop:
	bgt		s1, a4, cmd_F_done
	LWU		t0, 0(s1)
	and		t0, t0, s0

cmd_F_compare:
	beq		t0, a5, cmd_F_match
cmd_F_no_match:
	addi	s1, s1, 1
	j		cmd_F_loop

cmd_F_match:
	mv		a0, s1
	jal		print_hex
	jal		print_newline
	j		cmd_F_no_match

cmd_F_error:
	li		a0, ERR_CMD_PARAMS
	jal		print_error

cmd_F_done:
	j		main_prompt
.size cmd_F, .-cmd_F


#endif /* WITH_CMD_F */
