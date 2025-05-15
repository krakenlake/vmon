#include "vmon/config.h"


#ifdef WITH_CMD_F

.global cmd_F

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
	li		s0, 1
	j	cmd_F_read_start
cmd_F_find_h:
	li		s0, 2
	j	cmd_F_read_start
cmd_F_find_w:
	li		s0, 4
cmd_F_read_start:
	# read src_start from text buffer
	jal		skip_whitespace
	jal		get_numeric				# read start_addr from text buffer
	bnez	a2, cmd_F_error				# abort command if not found
	mv		a3, a1
	# read src_end from text buffer
	jal		skip_whitespace
	jal		get_numeric				# read end_addr from text buffer
	bnez	a2, cmd_F_error				# abort command if not found
	mv		a4, a1
	# read search value from text buffer
	jal		skip_whitespace
	jal		get_numeric
	bnez	a2, cmd_F_error				# abort command if not found
	mv		a5, a1

	# XXX: ensure no overflow of 8, 16, 32 value?

	# a3: src_start
	# a4: src_end
	# a5: value to search for

cmd_F_loop_forward:
	li		t4, 1
	bne		s0, t4, cmd_F_loop_h
	lbu		t0, 0(a3)
	j		cmd_F_compare
cmd_F_loop_h:
	li		t4, 2
	bne		s0, t4, cmd_F_loop_w
	lhu		t0, 0(a3)
	j		cmd_F_compare
cmd_F_loop_w:
#if	XLEN == 32
	lw		t0, 0(a3)
#else
	lwu		t0, 0(a3)
#endif
cmd_F_compare:
	beq		t0, a5, cmd_F_found
	addi	a3, a3, 1
	bgt		a3, a4, cmd_F_done
	j		cmd_F_loop_forward

cmd_F_found:
	mv		a0, a3
	jal		print_hex
	j		cmd_F_done
cmd_F_error:
	la		a0, error_param
	jal		print_string
cmd_F_done:
	j		main_prompt
.size cmd_F, .-cmd_F


#endif /* WITH_CMD_F */
