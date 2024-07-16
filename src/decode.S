#include "vmon/config.h"

#ifdef WITH_CMD_D


.global insn_is_compressed

.global print_instruction
.global print_register_name
.global print_rs1
.global print_rs1_as_base
.global print_rs2
.global print_rd

.global decode_opcode

.global decode_B_type
.global decode_I_type
.global decode_I_type_imm
.global decode_I_type_LOAD
.global decode_I_type_SHIFT
.global decode_R_type
.global decode_S_type
.global decode_S_type_imm
.global decode_U_type

.global decode_JAL
.global decode_JALR
.global decode_CSR
.global decode_CSRI
.global decode_EBREAK
.global decode_ECALL
.global decode_FENCE
.global decode_FENCE_I
.global decode_FENCE_TSO
.global decode_AMO
.global decode_LRSC
.global decode_EMPTY

#ifdef ENABLE_RVC
.global decode_C_LWSP
.global decode_C_EBREAK
#endif

.text


# evaluate if an instruction is an RVC instruction
# in: instruction word in a0
# out: 0 if not, nonzero if yes
insn_is_compressed:
    andi    a0, a0, 0b11                 # look at bit 0 and 1
    # uncompressed instructions have 0b11 in the end
    li      t1, 0b11                
    bne     a0, t1, insn_is_compressed_yes  # it is a compressed instruction
insn_is_compressed_no:
    li      a0, 0
    ret
insn_is_compressed_yes:
    li      a0, 1
    ret


#ifdef ENABLE_RVA
# for RVA
# in: instruction word in a0
# out: instruction word in a0
# out: aq/rl bits in bits 0 and 1 of a1
insn_get_aqrl:
    mv      a1, a0
    li      t0, 0b11 
    slli    t0, t0, 25
    and     a1, t0, a1
    srli    a1, a1, 25
    ret
.size insn_get_aqrl, .-insn_get_aqrl
#endif


# in: instruction word in a0
# in: current instruction address in s5 (global)
decode_B_type:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0   
    jal     print_rs1
    jal     print_comma
    mv      a0, s2
    jal     print_rs2
    jal     print_comma
    # imm[0] := 0
    # inst[11:8] -> imm[4:1] 
    srli    a0, s2, 7
    andi    a0, a0, 0b11110
    # inst[30:25] -> imm[10:5]
    srli    t0, s2, 20
    li      t1, 0b11111100000
    and     t0, t0, t1
    or      a0, a0, t0 
    # inst[7] -> imm[11]
    and     t0, s2, 0b10000000
    slli    t0, t0, 4
    or      a0, a0, t0 
    # inst[31] -> imm[63:12]
#if XLEN >=64
    sext.w  s2, s2              # sign-extend to 64 bits
#endif
    srai    t0, s2, 19
    li      t1, 0xfffffffffffff000          
    and     t0, t0, t1
    or      a0, a0, t0 
    # add relative immediate to instruction address
    add     a0, s5, a0
    # print absolute target address
    jal     print_hex  
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_B_type, .-decode_B_type


# in: instruction word in a0
decode_I_type:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)   
    mv      s2, a0   
    jal     print_rd
    mv      a0, s2
    jal     print_rs1
    jal     print_comma
    mv      a0, s2
    jal     decode_I_type_imm
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_I_type, .-decode_I_type


# in: instruction word in a0
decode_I_type_imm:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)      
    # inst[31:20] -> imm[11:0]
#if XLEN >=64
    sext.w  a0, a0              # sign-extend to 64 bits
#endif
    srai    a0, a0, 20
    jal     print_decimal
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_I_type_imm, .-decode_I_type_imm


# in: instruction word in a0
decode_I_type_LOAD:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)      
    mv      s2, a0
    jal     print_rd
    # inst[24:20] -> imm[5:0]
#if XLEN >=64
    sext.w  s2, s2              # sign-extend to 64 bits
#endif
    srai    a0, s2, 20
    jal     print_decimal
    mv      a0, s2
    jal     print_rs1_as_base
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_I_type_LOAD, .-decode_I_type_LOAD


# in: instruction word in a0
decode_I_type_SHIFT:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)   
    mv      s2, a0
    jal     print_rd
    mv      a0, s2
    jal     print_rs1
    jal     print_comma
    # inst[24:20] -> imm[5:0]
#if XLEN >=64
    sext.w  s2, s2              # sign-extend to 64 bits
#endif
    srli    a0, s2, 20+6
    jal     print_hex
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_I_type_SHIFT, .-decode_I_type_SHIFT


# in: instruction word in a0
decode_R_type:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp) 
    mv      s2, a0   
    jal     print_rd
    mv      a0, s2
    jal     print_rs1
    jal     print_comma
    mv      a0, s2
    jal     print_rs2
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_R_type, .-decode_R_type


# in: instruction word in a0
decode_S_type:
    addi    sp, sp, -(XLEN_BYTES*2)             
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)    
    mv      s2, a0
    jal     ra, print_rs2
    jal     print_comma
    mv      a0, s2
    jal     decode_S_type_imm
    mv      a0, s2
    jal     print_rs1_as_base
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_S_type, .-decode_S_type


# in: instruction word in a0
decode_S_type_imm:
    addi    sp, sp, -(XLEN_BYTES*1)             
    SAVE_X  ra, 0(sp)
    mv      t2, a0
    # inst[11:7] -> imm[4:0]
    srli    a0, t2, 7
    andi    a0, a0, 0b11111 
    # inst[30:25] -> imm[10:5]
    srli    t0, t2, 20
    li      t1, 0b11111100000
    and     t0, t0, t1
    or      a0, a0, t0 
    # inst[31] -> imm[63:12]
#if XLEN >=64
    sext.w  t0, t2                          # sign-extend to 64 bits
#endif
    srai    t0, t0, 20
    li      t1, 0xfffffffffffff800          
    and     t0, t0, t1
    or      a0, a0, t0 
    jal     print_decimal
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size decode_S_type_imm, .-decode_S_type_imm


# in: instruction word in a0
decode_U_type:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)  
    mv      s2, a0    
    jal     print_rd
    # extract imm
    srli    a0, s2, 12 
    jal     print_hex
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_U_type, .-decode_U_type


# in: instruction word in a0
# in: current instruction address in s5 (global)
decode_JAL:
    addi    sp, sp, -(XLEN_BYTES*2)             
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0
    jal     print_rd  
    # inst[30:21] -> imm[10:1]
    srli    a0, s2, 20
    andi    a0, a0, 0b11111111110    
    # inst[20] -> imm[11]
    srli    t0, s2, 9
    li      t1, 0b100000000000 
    and     t0, t0, t1
    or      a0, a0, t0
    # inst[19:12] -> imm[19:12]
    li      t1, 0b11111111000000000000
    and     t0, s2, t1
    or      a0, a0, t0
#if XLEN >=64
    sext.w  s2, s2                          # sign-extend to 64 bits
#endif
    srai    t0, s2, 11
    li      t1, 0xfffffffffff80000
    and     t0, t0, t1
    or      a0, a0, t0
decode_JAL_add_offset:
    add     a0, s5, a0
    jal     print_hex
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_JAL, .-decode_JAL

# in: a0: instruction word
# in: a1: number of start bit (27 for pre, 23 for sucessor)
decode_FENCE_bits:
    addi    sp, sp, -(XLEN_BYTES*5)             
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    SAVE_X  s3, (XLEN_BYTES*2)(sp)
    SAVE_X  s4, (XLEN_BYTES*3)(sp)
    SAVE_X  s5, (XLEN_BYTES*4)(sp)
    mv      s2, a0
    li      s3, 1
    sll     s3, s3, a1                      # set up initial bit mask
    la      s4, string_FENCE_bits
    li      s5, 4                           # 4 bits
decode_FENCE_bits_loop:
    and     t0, s2, s3
    beqz    t0, decode_FENCE_bits_skip
    lb      a0, 0(s4)
    jal     print_char
decode_FENCE_bits_skip:
    srli    s3, s3, 1
    addi    s4, s4, 1
    addi    s5, s5, -1
    bnez    s5, decode_FENCE_bits_loop
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    LOAD_X  s3, (XLEN_BYTES*2)(sp)               
    LOAD_X  s4, (XLEN_BYTES*3)(sp)               
    LOAD_X  s5, (XLEN_BYTES*4)(sp)               
    addi    sp, sp, (XLEN_BYTES*5)
    ret
.size decode_FENCE_bits, .-decode_FENCE_bits


decode_FENCE:
    addi    sp, sp, -(XLEN_BYTES*2)             
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0
    li      a1, 27
    jal     decode_FENCE_bits
    jal     print_comma
    mv      a0, s2
    li      a1, 23
    jal     decode_FENCE_bits
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_FENCE, .-decode_FENCE


decode_FENCE_I:
decode_FENCE_TSO:
decode_ECALL:
decode_EBREAK:
decode_EMPTY:
    # do nothing
    ret
.size decode_FENCE_I, .-decode_FENCE_I
.size decode_FENCE_TSO, .-decode_FENCE_TSO
.size decode_ECALL, .-decode_ECALL
.size decode_EBREAK, .-decode_EBREAK
.size decode_EMPTY, .-decode_EMPTY


#ifdef ENABLE_RVA
decode_LRSC:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)  
    mv      s2, a0
    jal     print_rd
    mv      a0, s2
    jal     print_rs2
    jal     print_comma  
    mv      a0, s2
    jal     print_rs1_as_base
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_LRSC, .-decode_LRSC


# in: instruction word in a0
decode_AMO:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)  
    mv      s2, a0   
    jal     print_rd
    mv      a0, s2
    jal     print_rs2
    jal     print_comma  
    # print rs1 = addr
    mv      a0, s2
    jal     print_rs1_as_base
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_AMO, .-decode_AMO
#endif


#ifdef ENABLE_RVC
decode_C_EBREAK:
    # do nothing
    ret
.size decode_C_EBREAK, .-decode_C_EBREAK


# in: instruction word in a0
decode_CR_type:
    ret
.size decode_CR_type, .-decode_CR_type


# in: instruction word in a0
decode_C_LWSP:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)  
    mv      s2, a0   
    jal     print_rd
    mv      a0, s2
    li      a0, '('
    jal     print_char
    # TODO
    li      a0, ')'
    jal     print_char
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_C_LWSP, .-decode_C_LWSP
#endif /* ENABLE_RVC */

# in: instruction word in a0
decode_CSR:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)     
    mv      s2, a0
    jal     print_rd
    mv      a0, s2
    jal     print_csr
    mv      a0, s2
    jal     print_rs1    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_CSR, .-decode_CSR


# in: instruction word in a0
decode_CSRI:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0
    jal     print_rd
    mv      a0, s2
    jal     print_csr
    # extract uimm[4:0] 
    mv      a0, s2
    srli    a0, a0, 15
    and     a0, a0, 0b11111
    jal     print_decimal    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size decode_CSRI, .-decode_CSRI


# in: instruction word in a0
print_rd:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp) 
    # isolate rd from a0
    srli    a0, a0, 7
    andi    a0, a0, 0b11111
    la      a1, int_register_names
    jal     print_register_name
    jal     print_comma
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size print_rd, .-print_rd


# in: instruction word in a0
print_rs1:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp) 
    srli    a0, a0, 15
    and     a0, a0, 0b11111
    la      a1, int_register_names
    jal     print_register_name
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size print_rs1, .-print_rs1


# in: instruction word in a0
print_rs1_as_base:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)   
    mv      s2, a0
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
.size print_rs1, .-print_rs1


# in: instruction word in a0
print_rs2:
    # rs2 just needs 5 shifts more than rs1, rest works the same
    srli    a0, a0, 5           
    j       print_rs1  
.size print_rs2, .-print_rs2


# in: instruction word in a0
print_csr:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp) 
    srai    a0, a0, 20
    jal     print_hex
    jal     print_comma
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size print_csr, .-print_csr


# output the n-th register name from the register name table
# in: n in a0
print_register_name:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s0, (XLEN_BYTES*1)(sp)
    mv      s0, a1
print_register_search:
    beqz    a0, print_register_found
    addi    s0, s0, 1
print_register_skip_next_zero:    
    lb      t1, 0(s0)
    beqz    t1, print_register_next_zero
    addi    s0, s0, 1
    j       print_register_skip_next_zero
print_register_next_zero:
    addi    a0, a0, -1
    addi    s0, s0, 1
    j       print_register_search
 print_register_found:
    mv      a0, s0
    jal     print_string
    LOAD_X  ra, 0(sp)               
    LOAD_X  s0, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
.size print_register_name, .-print_register_name


# in: instruction word in a0
# out: instruction word in a0
# out: type-depending decode function ptr in a1
# out: opcode string in a2
decode_opcode:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp)
    # search for a match in encoding table
    la      t0, encoding_table
    # clear return values
    mv      a1, zero
    mv      a2, zero
decode_opcode_search_next:
#if XLEN >= 64
    lwu     t2, 0(t0)                       # get mask word from table
#else
    lw      t2, 0(t0)                       # get mask word from table
#endif
    beqz    t0, decode_opcode_done          # table end, no match found
    and     t2, a0, t2                      # apply mask
#if XLEN >= 64
    lwu     t3, 4(t0)                       # get match word from table
#else
    lw      t3, 4(t0)                       # get match word from table
#endif
    bne     t2, t3, decode_opcode_continue
    # found a match
#if XLEN >=64
    lwu     a1, 8(t0)                       # get function ptr from table
    lwu     a2, 12(t0)                      # get string ptr from table
#else
    lw      a1, 8(t0)                       # get function ptr from table
    lw      a2, 12(t0)                      # get string ptr from table
#endif
    j       decode_opcode_done
decode_opcode_continue:
    addi    t0, t0, 16                      # point to next table entry
    j       decode_opcode_search_next       # repeat
decode_opcode_done:
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size decode_opcode, .-decode_opcode


# in: instruction word in a0
# in: type-depending decoder routine to call in a1
# in: opcode string in a2
print_instruction:
    addi    sp, sp, -(XLEN_BYTES*3)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    SAVE_X  s3, (XLEN_BYTES*2)(sp)    
    mv      s2, a1                  # save for later
    mv      s3, a0                  # save for later    
    mv      a0, a2
    jal     print_string            # print opcode
#ifdef ENABLE_RVA
    mv      a0, s3
    jal     print_AMO_postfix       # prints aq/lr postfix for RVA opcodes
#endif
    la      a0, string_asm_sep2
    jal     print_string
    # call decoder routine (only if address is non-zero)
    beqz    s2, print_instruction_done  
    mv      a0, s3
    jalr    s2                      # execute call
print_instruction_done:
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)   
    LOAD_X  s3, (XLEN_BYTES*2)(sp)     
    addi    sp, sp, (XLEN_BYTES*3)
    ret
.size print_instruction, .-print_instruction


#ifdef ENABLE_RVA

# in: instruction word in a0
print_AMO_postfix:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp)
    # check if bits 0-6 are an AMO opcode, return if not
    li      t0, 0x7f            # MASK
    and     t1, a0, t0
    li      t2, 0x2f            # MATCH
    bne     t1, t2, print_AMO_postfix_done
    # decode ac/rl bits and print fitting postfix
    jal     insn_get_aqrl
    beqz    a1, print_AMO_postfix_done
    li      t0, 1
    bne     a1, t0, print_AMO_postfix_case2
    la      a0, string_OP_POSTFIX_RL
    jal     print_string
    j       print_AMO_postfix_done
print_AMO_postfix_case2:
    li      t0, 2
    bne     a1, t0, print_AMO_postfix_case3
    la      a0, string_OP_POSTFIX_AQ
    jal     print_string
    j       print_AMO_postfix_done
print_AMO_postfix_case3:
    la      a0, string_OP_POSTFIX_AQRL
    jal     print_string
print_AMO_postfix_done:    
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret
.size print_AMO_postfix, .-print_AMO_postfix

#endif


.data

string_FENCE_bits:      .string "iorw";

#ifdef ENABLE_RVA
.align 4
string_OP_POSTFIX_AQ:   .string ".aq";
.size string_OP_POSTFIX_AQ, .-string_OP_POSTFIX_AQ
string_OP_POSTFIX_RL:	.string ".rl";
.size string_OP_POSTFIX_RL, .-string_OP_POSTFIX_RL
string_OP_POSTFIX_AQRL:	.string ".aqrl";
.size string_OP_POSTFIX_AQRL, .-string_OP_POSTFIX_AQRL
#endif


#endif /* WITH_CMD_D */
