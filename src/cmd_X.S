#include "vmon/config.h"


#ifdef WITH_CMD_X

.global cmd_X

.text


cmd_X:
    la      a0, string_exit
    jal     print_string
    LOAD_X  a0, 0(sp)      
    jal     print_hex
    # restore registers
    LOAD_X  ra, 0(sp)      
    LOAD_X  x3, (XLEN_BYTES*2)(sp)      
    LOAD_X  x4, (XLEN_BYTES*3)(sp)      
    LOAD_X  x5, (XLEN_BYTES*4)(sp)      
    LOAD_X  x6, (XLEN_BYTES*5)(sp)      
    LOAD_X  x7, (XLEN_BYTES*6)(sp)      
    LOAD_X  x8, (XLEN_BYTES*7)(sp)      
    LOAD_X  x9, (XLEN_BYTES*8)(sp)      
    LOAD_X  x10, (XLEN_BYTES*9)(sp)      
    LOAD_X  x11, (XLEN_BYTES*10)(sp)      
    LOAD_X  x12, (XLEN_BYTES*11)(sp)      
    LOAD_X  x13, (XLEN_BYTES*12)(sp)      
    LOAD_X  x14, (XLEN_BYTES*13)(sp)      
    LOAD_X  x15, (XLEN_BYTES*14)(sp)      
    LOAD_X  x16, (XLEN_BYTES*15)(sp)      
    LOAD_X  x17, (XLEN_BYTES*16)(sp)      
    LOAD_X  x18, (XLEN_BYTES*17)(sp)      
    LOAD_X  x19, (XLEN_BYTES*18)(sp)      
    LOAD_X  x20, (XLEN_BYTES*19)(sp)      
    LOAD_X  x21, (XLEN_BYTES*20)(sp)      
    LOAD_X  x22, (XLEN_BYTES*21)(sp)      
    LOAD_X  x23, (XLEN_BYTES*22)(sp)      
    LOAD_X  x24, (XLEN_BYTES*23)(sp)      
    LOAD_X  x25, (XLEN_BYTES*24)(sp)      
    LOAD_X  x26, (XLEN_BYTES*25)(sp)      
    LOAD_X  x27, (XLEN_BYTES*26)(sp)      
    LOAD_X  x28, (XLEN_BYTES*27)(sp)      
    LOAD_X  x29, (XLEN_BYTES*28)(sp)      
    LOAD_X  x30, (XLEN_BYTES*29)(sp)      
    LOAD_X  x31, (XLEN_BYTES*30)(sp)      
    # the original sp from caller
    LOAD_X  sp, (XLEN_BYTES*1)(sp)     
    # return control to caller     
    jalr    zero, ra, 0     
.size cmd_X, .-cmd_X


.data
string_exit:            .string "exiting: ret, ra=";
.size string_exit, .-string_exit

#endif /* WITH_CMD_X */
