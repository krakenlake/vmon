#include "vmon/config.h"


#ifdef WITH_CMD_C

.global cmd_C

.text


cmd_C:
    mv      a0, s4
    jal     skip_whitespace
    jal     get_hex_addr            # read src_start from text buffer
    bnez    a2, cmd_G_error         # abort command if not found
    mv		s2, a0
	mv      a0, a1
    jal     print_hex
	
	mv		a0, s2
	jal     skip_whitespace
    jal     get_hex_addr            # read src_end from text buffer
    bnez    a2, cmd_G_error         # abort command if not found
    mv		s2, a0
    mv      a0, a1
    jal     print_hex
	
	mv		a0, s2
	jal     skip_whitespace
    jal     get_hex_addr            # read dst_start from text buffer
    bnez    a2, cmd_G_error         # abort command if not found
    mv		s2, a0
    mv      a0, a1
    jal     print_hex
	
	# done
    j       main_prompt
cmd_G_error:
    la      a0, error_no_addr
    jal     print_string
    j       main_prompt
.size cmd_C, .-cmd_C


#endif /* WITH_CMD_C */
