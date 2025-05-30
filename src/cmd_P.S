#include "config.h"
#include "vmon/error.h"


#ifdef WITH_CMD_P

.global cmd_P

.text


cmd_P:
	li		s0, 1 					# number of bytes to poke (1 or 4)
	lb		t1, 0(a0)
	addi	a0, a0, 1
	li		t0, 'w'
	beq		t0, t1,	cmd_P_poke4
	addi	a0, a0, -1
	j		cmd_P_poke
cmd_P_poke4:
	li		s0, 4

cmd_P_poke:	
	# read dst_addr from text buffer	
	jal		skip_whitespace
	jal		get_numeric			# read src_start from text buffer
	bnez	a2, cmd_P_error			# abort command if not found
	mv		a3, a1

	# read poke value from text buffer
cmd_P_next_value:
	jal		skip_whitespace
	jal		get_numeric			
	bnez	a2, cmd_P_done		   # end if no more valid input
	mv		a4, a1

	# a3: dst_addr
	# a4: byte_value
	li		t0, 1
	bne		s0, t0, cmd_P_write4
	sb		a4, 0(a3)				# writes only lower 8 bits
	addi	a3, a3, 1
	j		cmd_P_next_value		# increase target addr by 1 byte
cmd_P_write4:
	sw		a4, 0(a3)
	addi	a3, a3, 4				# increase target addr by 4 byte
	j		cmd_P_next_value

cmd_P_error:
	li		a0, ERR_CMD_PARAMS
	jal		print_error

cmd_P_done:
	j		main_prompt
.size cmd_P, .-cmd_P


#endif /* WITH_CMD_P */
