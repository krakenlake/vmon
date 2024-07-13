#include "vmon/config.h"

#ifdef WITH_CMD_D

#ifdef ENABLE_RVF

.global decode_FL
.global decode_FS


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


decode_FL:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp) 
    mv      s2, a0   
    jal     print_frd

    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_FL, .-decode_FL


decode_FS:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp) 
    mv      s2, a0   
    jal     print_frs2
    jal     print_comma
    mv      a0, s2
    jal     decode_S_type_imm
    li      a0, '('
    jal     print_char
    mv      a0, s2
    jal     print_rs1
    li      a0, ')'
    jal     print_char
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_FL, .-decode_FL


.data

#endif /* ENABLE_RVF */

#endif /* WITH_CMD_D */
