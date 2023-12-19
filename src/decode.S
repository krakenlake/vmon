#include "vmon/config.h"


.global print_instruction
.global decode_opcode
.global decode_B_type
.global decode_I_type
.global decode_J_type
.global decode_R_type
.global decode_S_type
.global decode_U_type
.global decode_JAL
.global decode_JALR
.global decode_CSR
.global decode_CSRI
.global decode_EBREAK
.global decode_ECALL
.global decode_FENCE
.global decode_FENCE_I
.global decode_AMO
.global decode_LRSC
.global decode_EMPTY


.text


insn_get_csr:
    # in: instruction word in a0
    # out: csr value in a0
    # inst[31:20] -> imm[10:0]
    srai    a0, a0, 20
    ret


insn_get_funct3:
    # in: instruction word in a0
    # out: funct3 value in a1
    srli    a1, a0, 12 
    andi    a1, a1, 0b111
    ret


insn_get_funct7:
    # in: instruction word in a0
    # out: funct7 value in a1
    srli    a1, a0, 25 
    ret


insn_get_opcode:
	# in: instruction word in a0
	# out: opcode value in a1
    andi    a1, a0, 0x7f
    ret


insn_get_rd:
	# in: instruction word in a0
	# out: instruction word in a0
	# out: rd register number in a1
    srli    a0, a0, 7
    and     a0, a0, 0b11111
    ret


insn_get_rs1:
	# in: instruction word in a0
	# out: instruction word in a0
	# out: rs1 register number in a1
    srli    a1, a0, 15
    and     a1, a1, 0b11111
    ret


insn_get_rs2:
	# in: instruction word in a0
	# out: instruction word in a0
	# out: rs2 register number in a1
    srli    a1, a0, 20
    and     a1, a1, 0b11111
    ret


#ifdef ENABLE_RVA
insn_get_aqrl:
    # for RVA
	# in: instruction word in a0
	# out: instruction word in a0
	# out: aq/rl bits in bits 0 and 1 of a1
    mv      a1, a0
    li      t0, 0b11 
    slli    t0, t0, 25
    and     a1, t0, a1
    srli    a1, a1, 25
    ret
#endif


decode_U_type:
    # in: instruction word in a0
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)  
    mv      s2, a0
    
    # extract rd
    jal     print_rd_name
    # comma
    la      a0, string_asm_sep3
    jal     print_string  
    # extract imm
    srli    a0, s2, 12 
    jal     print_hex
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
decode_EMPTY:
    ret


decode_JAL:
    # in: instruction word in a0
    # in: current instruction address in s5 (global)
    addi    sp, sp, -(XLEN_BYTES*2)             
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0
    
    # extract rd
    jal     print_rd_name  
    # comma
    la      a0, string_asm_sep3
    jal     print_string 
    # inst[30:21] -> imm[10:1]
    srli    a0, s2, 20
    andi    a0, a0, 0b11111111110    
    # inst[20] -> imm[11]
    srli    t0, s2, 20
    li      t1, 0b100000000000 
    and     t0, t0, t1
    or      a0, a0, t0
    # inst[19:12] -> imm[19:12]
    li      t1, 0b11111111000000000000
    and     t0, s2, t1
    or      a0, a0, t0
    # inst[31] -> imm[63:20]
#if XLEN >=64
    slli    a1, a0, 32                      # sign-extend to 64 bits
    srai    a1, a1, 32+11
#else
    srai    a1, a0, 11
#endif
    # print target address as hex
    li      t1, 0xfffffffffff00000          
    and     a1, a1, t1
    or      a1, a0, a1 
    # add relative immediate to instruction address
    add     a0, s5, a1
    jal     print_hex

    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_JALR:
    # in: instruction word in a0
    # in: current instruction address in s5 (global)
    addi    sp, sp, -(XLEN_BYTES*2)             
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0
    
    # extract rd
    jal     print_rd_name
    # comma
    la      a0, string_asm_sep3
    jal     print_string 
    # print offset
#if XLEN >=64
    slli    a0, s2, 32                      # sign-extend to 64 bits
    srai    a0, a0, 32+20
#else
    srai    a0, s2, 20
#endif
    jal     ra, print_decimal
    # print rs1
    li      t0, '('
    sb      t0, 0(s1)
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1
    jal     print_register_name
    li      t0, ')'
    sb      t0, 0(s1)

    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_R_type:
    # in: instruction word in a0
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp) 
    mv      s2, a0
    
    # extract rd
    jal     print_rd_name
    # comma
    la      a0, string_asm_sep3
    jal     print_string
    # extract rs1 
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1
    jal     print_register_name
    la      a0, string_asm_sep3
    jal     print_string
    # extract rs2 
    mv      a0, s2
    jal     insn_get_rs2
    mv      a0, a1
    jal     print_register_name
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_I_type:
    # in: instruction word in a0
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)   
    mv      s2, a0
    
    # extract rd
    jal     ra, print_rd_name
    # comma
    la      a0, string_asm_sep3
    jal     print_string
    # extract rs1 
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1
    jal     print_register_name
    la      a0, string_asm_sep3
    jal     print_string
    # inst[30:20] -> imm[10:0]
    # inst[31] -> imm[63:11]
#if XLEN >=64
    slli    a0, s2, 32                      # sign-extend to 64 bits
    srai    a0, a0, 32+20
#else
    srai    a0, s2, 20
#endif
    # TODO: print decimal?
    jal     print_hex
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_S_type:
    # in: instruction word in a0
    addi    sp, sp, -(XLEN_BYTES*2)             
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)    
    mv      s2, a0

    # extract rs2 
    jal     ra, insn_get_rs2
    mv      a0, a1
    jal     print_register_name
    la      a0, string_asm_sep3
    jal     print_string
    # inst[11:7] -> imm[4:0]
    srli    a0, s2, 7
    andi    a0, a0, 0b11111 
    # inst[30:25] -> imm[10:5]
    srli    t0, s2, 20
    li      t1, 0b11111100000
    and     t0, t0, t1
    or      a0, a0, t0 
    # inst[31] -> imm[63:12]
#if XLEN >=64
    slli    t0, s2, 32                      # sign-extend to 64 bits
    srai    t0, t0, 32+20
#else
    srai    t0, s2, 20
#endif
    li      t1, 0xfffffffffffff800          
    and     t0, t0, t1
    or      a0, a0, t0 
    # TODO: print nicer
    jal     print_hex
    li      t0, '('
    sb      t0, 0(s1)
    # extract rs1 
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1
    jal     print_register_name
    li      t0, ')'
    sb      t0, 0(s1)
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_B_type:
    # in: instruction word in a0
    # in: current instruction address in s5 (global)
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0
    
    # extract rs1 
    jal     ra, insn_get_rs1
    mv      a0, a1
    jal     print_register_name
    la      a0, string_asm_sep3
    jal     print_string
    # extract rs2 
    mv      a0, s2
    jal     insn_get_rs2
    mv      a0, a1
    jal     print_register_name
    la      a0, string_asm_sep3
    jal     print_string
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
    slli    t0, s2, 32                      # sign-extend to 64 bits
    srai    t0, t0, 32+19
#else
    srai    t0, s2, 19
#endif
    li      t1, 0xfffffffffffff000          
    and     t0, t0, t1
    or      a0, a0, t0 
    # add relative immediate to instruction address
    add     a0, s5, a0
    # print absolute target address
    jal     print_hex
    
    # TODO: show relative value as well in decimal?
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_FENCE:
decode_ECALL:
decode_EBREAK:
decode_FENCE_I:
    # in: instruction word in a0 
    # do nothing
    ret


#ifdef ENABLE_RVA
decode_LRSC:
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)  
    mv      s2, a0

    # print rd
    jal     print_rd_name
    la      a0, string_asm_sep3
    jal     print_string 
    # 
    li      t0, '('
    sb      t0, 0(s1)
    # print addr 
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1
    jal     print_register_name
    #
    li      t0, ')'
    sb      t0, 0(s1)
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_AMO:
    # in: instruction word in a0
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)  
    mv      s2, a0
    
    # print rd
    jal     print_rd_name 
    la      a0, string_asm_sep3
    jal     print_string  
    # print rs2 = src
    mv      a0, s2
    jal     insn_get_rs2
    mv      a0, a1
    jal     print_register_name
    # comma
    la      a0, string_asm_sep3
    jal     print_string  
    #
    li      t0, '('
    sb      t0, 0(s1)
    # print rs1 = addr
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1
    jal     print_register_name
    #
    li      t0, ')'
    sb      t0, 0(s1)

    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret
#endif

decode_CSR:
    # in: instruction word in a0
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp) 
    mv      s2, a0
    
    # extract rd
    jal     print_rd_name
    # comma
    la      a0, string_asm_sep3
    jal     print_string  
    # extract csr
    mv      a0, s2
    jal     insn_get_csr
    # TODO: print decimal
    jal     print_hex
    # comma
    la      a0, string_asm_sep3
    jal     print_string
    # extract rs1
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1 
    jal     print_register_name
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


decode_CSRI:
    # in: instruction word in a0
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    mv      s2, a0

    # extract rd
    jal     print_rd_name
    # comma
    la      a0, string_asm_sep3
    jal     print_string  
    # extract csr
    mv      a0, s2
    jal     insn_get_csr
    # TODO: print decimal
    jal     print_hex
    # comma
    la      a0, string_asm_sep3
    jal     print_string
    # extract uimm[4:0] 
    mv      a0, s2
    jal     insn_get_rs1
    mv      a0, a1
    jal     print_hex
    
    LOAD_X  ra, 0(sp)               
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    addi    sp, sp, (XLEN_BYTES*2)
    ret


print_rd_name:
    addi    sp, sp, -(XLEN_BYTES*1)              
    SAVE_X  ra, 0(sp)
    
    jal     insn_get_rd
    jal     print_register_name
    
    LOAD_X  ra, 0(sp)               
    addi    sp, sp, (XLEN_BYTES*1)
    ret


print_register_name:
    # output the n-th register name from the register name table
    # in: n in a0
    addi    sp, sp, -(XLEN_BYTES*2)              
    SAVE_X  ra, 0(sp)
    SAVE_X  s0, (XLEN_BYTES*1)(sp)
    
    la      s0, register_names
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


decode_opcode:
    # in: instruction word in a0
    # out: instruction word in a0
    # out: type-depending decode function ptr in a1
    # out: opcode string in a2
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


print_instruction:
    # in: instruction word in a0
    # in: type-depending decoder routine to call in a1
    # in: opcode string in a2
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


#ifdef ENABLE_RVA
print_AMO_postfix:
    # in: instruction word in a0
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
#endif

.data

#ifdef ENABLE_RVA
.align 4
string_OP_POSTFIX_AQ:   .string ".aq";
string_OP_POSTFIX_RL:	.string ".rl";
string_OP_POSTFIX_AQRL:	.string ".aqrl";
#endif
