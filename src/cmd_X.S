#include "vmon/config.h"


#ifdef WITH_CMD_X

.global cmd_X

.text


cmd_X:
    la      a0, string_exit
    jal     print_string

    # restore registers
    LOAD_X  ra, 0(sp)      
    LOAD_X  s0, (XLEN_BYTES*2)(sp)      
    LOAD_X  s1, (XLEN_BYTES*3)(sp)      
    LOAD_X  s2, (XLEN_BYTES*4)(sp)      
    LOAD_X  s3, (XLEN_BYTES*5)(sp)      
    LOAD_X  s4, (XLEN_BYTES*6)(sp)      
    LOAD_X  s5, (XLEN_BYTES*7)(sp)      
    LOAD_X  s6, (XLEN_BYTES*8)(sp)      
    LOAD_X  s7, (XLEN_BYTES*9)(sp)      
    LOAD_X  s8, (XLEN_BYTES*10)(sp)      
    LOAD_X  s9, (XLEN_BYTES*11)(sp)      
    LOAD_X  s10, (XLEN_BYTES*12)(sp)      
    LOAD_X  s11, (XLEN_BYTES*13)(sp)      
    # the original sp from caller
    LOAD_X  sp, (XLEN_BYTES*1)(sp)     
    # return control to caller     
    ret     


.data
string_exit:            .string "(exiting)\n";

#endif /* WITH_CMD_X */