#include "vmon/config.h"


#ifdef WITH_CMD_F

.global cmd_F

.text


cmd_F:
	# read src_start from text buffer	
    mv      a0, s4
    jal     skip_whitespace
    jal     get_hex_addr            # read start_addr from text buffer
    bnez    a2, cmd_F_error         # abort command if not found
	mv		a3, a1
	# read src_end from text buffer
	jal     skip_whitespace
    jal     get_hex_addr            # read end_addr from text buffer
    bnez    a2, cmd_F_error         # abort command if not found
    mv		a4, a1
	# read byte_value from text buffer
	jal     skip_whitespace
    jal     get_hex_addr            
    bnez    a2, cmd_F_error         # abort command if not found
    mv      a5, a1
	
	# a3: src_start
	# a4: src_end
	
cmd_F_loop_forward:
	lb		t0, 0(a3)
	beq		t0, a5, cmd_F_found
	addi	a3, a3, 1
	bgt		a3, a4, cmd_F_done
    j       cmd_F_loop_forward

cmd_F_found:
	mv		a0, a3
	jal		print_hex
	j 		cmd_F_done
cmd_F_error:
    la      a0, error_param
    jal     print_string
cmd_F_done:
    j       main_prompt
.size cmd_F, .-cmd_F


#endif /* WITH_CMD_F */
