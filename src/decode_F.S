#include "vmon/config.h"

#ifdef WITH_CMD_D


.global decode_FLW
.global decode_FSW


.text

# in: instruction word in a0
print_frd:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp) 
    srli    a0, a0, 7
    andi    a0, a0, 0b11111
    la      a1, float_register_names
    jal     print_register_name
    jal     print_comma
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size print_frd, .-print_frd


# in: instruction word in a0
print_frs1:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp) 
    srli    a0, a0, 15
    and     a0, a0, 0b11111
    la      a1, float_register_names
    jal     print_register_name
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size print_frs1, .-print_frs1


# in: instruction word in a0
print_frs2:
    # rs2 just needs 5 shifts more than rs1, rest works the same
    srli    a0, a0, 5           
    j       print_frs1  
.size print_frs2, .-print_frs2


.data


#endif /* WITH_CMD_D */
