#include "vmon/config.h"
#include "vmon/ASCII.h"

#ifdef WITH_CMD_A

.global assemble_instruction

.global assemble_DUMMY
.global assemble_VOID
.global assemble_BRANCH


.text

# in: a0 = ptr to input text
# out: a0 = number of bytes written to memory (normal 4, 2 for RVC, 0 if error)
# out: a1 = assembled instruction to be written into memory
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
    beqz    a0, assemble_instruction_done       # not found
    jalr    a0                                  # call assemble function   
    beqz    a0, assemble_instruction_done       # error while assembling insn parameters
    # now use a0 to return insn size
    mv      a0, a1    
    jal     insn_is_compressed
    bnez    a0, assemble_instruction_is_RVC
    li      a0, 4
    j       assemble_instruction_done
assemble_instruction_is_RVC:
    li      a0, 2
assemble_instruction_done:
	LOAD_X  ra, 0(sp)               
    LOAD_X  s0, (XLEN_BYTES*1)(sp)               
    LOAD_X  s1, (XLEN_BYTES*2)(sp)               
    addi    sp, sp, (XLEN_BYTES*3)
    ret
.size assemble_instruction, .-assemble_instruction


# in: input string ptr start in s0
# in: input string ptr end+1 in s1
# out: ptr to assemble function in a0 (0 if string was not found)
# out: MATCH value for insn in a1 (undefined if string was not found)
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
    lw      a1, 4(t0)                       # store MATCH value from table entry in a1
    ret
.size find_insn_in_table, .-find_insn_in_table


# in: input string ptr in a0
# out: register number in a1 (-1 if error)
assemble_rs1:
    ret
.size assemble_rs1, .-assemble_rs1

    
# in: input string ptr in a0
assemble_DUMMY:
    li      a1, 0xffffffff
    ret
.size assemble_DUMMY, .-assemble_DUMMY


# in: input string ptr in a0
# in: MATCH value in a1
assemble_VOID:
    # nothing to be done, a1 already contains final insn
    ret
.size assemble_VOID, .-assemble_VOID


# in: input string ptr in a0
# in: MATCH value in a1
assemble_BRANCH:
    # read rs1
    # read comma
    # read rs2
    # read comma
    # read address

    ret
.size assemble_BRANCH, .-assemble_BRANCH


#endif /* WITH_CMD_A */
