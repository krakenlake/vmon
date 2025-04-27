#include "vmon/config.h"


#ifdef WITH_CMD_C

.global cmd_C

.text


cmd_C:
	# read src_start from text buffer	
    jal     skip_whitespace
    jal     get_hex_addr            # read src_start from text buffer
    bnez    a2, cmd_C_error         # abort command if not found
	mv		a3, a1
	# read src_end from text buffer
	jal     skip_whitespace
    jal     get_hex_addr            
    bnez    a2, cmd_C_error         # abort command if not found
    mv		a4, a1
	# read dst_start from text buffer
	jal     skip_whitespace
    jal     get_hex_addr            
    bnez    a2, cmd_C_error         # abort command if not found
    mv      a5, a1
	
	# a3: src_start
	# a4: src_end
	# a5: dst_start
	
	# loop forward or backwards, depending how areas might overlap
	bgt		a5, a3, cmd_C_do_backwards

cmd_C_loop_forward:
	lb		t0, 0(a3)
	sb		t0, 0(a5)
	addi	a3, a3, 1
	addi 	a5, a5, 1
	bgt		a3, a4, cmd_C_done
    j       cmd_C_loop_forward

cmd_C_do_backwards:
	sub		t1, a4, a3
	add		a5, a5, t1				# point a5 to last dst byte
cmd_C_loop_backwards:
	lb		t0, 0(a4)
	sb		t0, 0(a5)
	addi	a4, a4, -1
	addi 	a5, a5, -1
	blt 	a4, a3, cmd_C_done
    j       cmd_C_loop_backwards

cmd_C_error:
    la      a0, error_param
    jal     print_string

cmd_C_done:
    j       main_prompt
.size cmd_C, .-cmd_C


#endif /* WITH_CMD_C */
