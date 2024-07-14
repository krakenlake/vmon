#include "vmon/config.h"


#ifdef WITH_CMD_C

.global cmd_C

.text


cmd_C:
    mv      a0, s4
    jal     skip_whitespace
    jal     get_hex_addr            # read src_start from text buffer
    bnez    a2, cmd_C_error         # abort command if not found
    mv		s2, a0
	mv		a3, a1
	
	mv		a0, s2
	jal     skip_whitespace
    jal     get_hex_addr            # read src_end from text buffer
    bnez    a2, cmd_C_error         # abort command if not found
    mv		s2, a0
    mv		a4, a1
	
	mv		a0, s2
	jal     skip_whitespace
    jal     get_hex_addr            # read dst_start from text buffer
    bnez    a2, cmd_C_error         # abort command if not found
    mv      a5, a1
	
	# a3: src_start
	# a4: src_end
	# a5: dst_start
cmd_C_loop:
	# TODO: make this work in case areas overlap
	lb		t0, 0(a3)
	sb		t0, 0(a5)
	addi	a3, a3, 1
	addi 	a5, a5, 1
	bne		a3, a4, cmd_C_loop
	# done
    j       main_prompt
cmd_C_error:
    la      a0, error_no_addr
    jal     print_string
    j       main_prompt
.size cmd_C, .-cmd_C


#endif /* WITH_CMD_C */
