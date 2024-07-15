#include "vmon/config.h"


#ifdef WITH_CMD_P

.global cmd_P

.text


cmd_P:
	# read dst_addr from text buffer	
    mv      a0, s4
    jal     skip_whitespace
    jal     get_hex_addr            # read src_start from text buffer
    bnez    a2, cmd_P_error         # abort command if not found
	mv		a3, a1
	# read byte_value from text buffer
	jal     skip_whitespace
    jal     get_hex_addr            
    bnez    a2, cmd_P_error         # abort command if not found
    mv		a4, a1
	
	# a3: dst_addr
	# a4: byte_value
	sb		a4, 0(a3)				# writes only lower 8 bits
	j 		cmd_P_done

cmd_P_error:
    la      a0, error_param
    jal     print_string

cmd_P_done:
    j       main_prompt
.size cmd_P, .-cmd_P


#endif /* WITH_CMD_P */
