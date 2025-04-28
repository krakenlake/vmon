#include "vmon/config.h"
#include "vmon/ASCII.h"

#ifdef WITH_CMD_A

.global assemble_instruction

.global assemble_DUMMY
.global assemble_NOP
.global assemble_RET
.global assemble_BRANCH


.text

# in: a0 = ptr to input text
# out: a0 = number of bytes written to memory (normal 4, 2 for RVC, 0 if error)
assemble_instruction:  
    addi    sp, sp, -(XLEN_BYTES*3)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s0, (XLEN_BYTES*1)(sp)
    SAVE_X  s1, (XLEN_BYTES*2)(sp)
    jal     skip_whitespace
    mv      s0, a0
    jal     find_insn_name_end
    mv      s1, a0
    # find string between s0 and s1 in encoding table
    jal     find_insn_in_table
    # function ptr now in a0
    beqz    a0, assemble_instruction_done
    jalr    a0
    # 4 bytes default instruction size    
    li      a0, 4
assemble_instruction_done:
	LOAD_X  ra, 0(sp)               
    LOAD_X  s0, (XLEN_BYTES*1)(sp)               
    LOAD_X  s1, (XLEN_BYTES*2)(sp)               
    addi    sp, sp, (XLEN_BYTES*3)
    ret


# in: input string ptr start in s0
# in: input string ptr end+1 in s1
# out: ptr to assemble function in a0 (0 if not found)
find_insn_in_table:
    la      t0, encoding_table
find_insn_in_table_next:
#if XLEN >= 64
    lwu     t1, 12(t0)                       # get string ptr from table
    lwu     a0, 16(t0)                       # get function ptr from table
#else
    lw      t1, 12(t0)                       # get string ptr from table
    lw      a0, 16(t0)                       # get function ptr from table
#endif
    beqz    t1, find_insn_in_table_not_found          # table end, no match found
    # compare strings
    mv      t2, s0                          # iterate with t2 over input string                         
find_insn_in_table_cmp_next_byte:
    beq     t2, s1, find_insn_in_table_done
    lb      t3, 0(t2)
    lb      t4, 0(t1)
    bne     t3, t4, find_insn_in_table_next_entry       # strings not equal
    beqz    t4, find_insn_in_table_next_entry           # string in table ended
    addi    t1, t1, 1
    addi    t2, t2, 1
    j       find_insn_in_table_cmp_next_byte
find_insn_in_table_next_entry:
    addi    t0, t0, 20
    j       find_insn_in_table_next
find_insn_in_table_not_found:
    mv      a0, zero
find_insn_in_table_done:
    ret
.size assemble_DUMMY, .-assemble_DUMMY


# in: input string ptr in a0
assemble_DUMMY:
    li      a1, 0xffffffff
    ret
.size assemble_DUMMY, .-assemble_DUMMY


# in: input string ptr in a0
# out: instruction in a1
assemble_NOP:
    li      a1, 0x00000013
    ret

assemble_RET:
    li      a1, 0x00008067
    ret

assemble_BRANCH:
    ret



.data

.align 4



#endif /* WITH_CMD_A */
