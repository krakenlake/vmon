#include "vmon/config.h"

#ifdef WITH_CMD_A

.global assemble_instruction

.global assemble_DUMMY


.text

# in: a0 = ptr to input text
# out: a0 = number of bytes written to memory (normal 4, 2 for RVC, 0 if error)
assemble_instruction:  
    addi    sp, sp, -(XLEN_BYTES*4)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s0, (XLEN_BYTES*1)(sp)
    SAVE_X  s1, (XLEN_BYTES*2)(sp)
    SAVE_X  s2, (XLEN_BYTES*3)(sp)

    jal     skip_whitespace
    mv      s0, a0
/*
    jal     find_word_end
    mv      s1, a0

    # find string between s0 and s1 in encoding table

    */

    # 4 bytes default instruction size    
    li      a0, 4


    jal     assemble_NOP
    
	LOAD_X  ra, 0(sp)               
    LOAD_X  s0, (XLEN_BYTES*1)(sp)               
    LOAD_X  s1, (XLEN_BYTES*2)(sp)               
    LOAD_X  s2, (XLEN_BYTES*3)(sp)               
    addi    sp, sp, (XLEN_BYTES*4)
    ret

# in: input string ptr in a0
assemble_DUMMY:
    ret
.size assemble_DUMMY, .-assemble_DUMMY

# in: input string ptr in a0
# out: instruction in a1
assemble_NOP:
    li      a1, 0x00000013
    ret





.data

.align 4



#endif /* WITH_CMD_A */
