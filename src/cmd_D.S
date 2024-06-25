#include "vmon/config.h"
#include "vmon/ASCII.h"


#ifdef WITH_CMD_D

.global cmd_D

.text


cmd_D:
    mv      a0, s4
    jal     skip_whitespace
    jal     get_hex_addr            # read start addr from text buffer
    bnez    a2, cmd_D_from_last     # none given? continue from last saved addr
    mv      s5, a1                  # save start addr of dump
    jal     skip_whitespace
    jal     get_hex_addr            # read start addr from text buffer
    mv      s7, a1                  # save end addr of dump
    beqz    a2, cmd_D_next_instruction
    j       cmd_D_add_default 
cmd_D_from_last:
    # continue from last address used
    la      a1, last_address
    LOAD_X  s5, 0(a1)
cmd_D_add_default:
    # no end addr? use default 
    addi    s7, s5, DEFAULT_D_LINES*4-1          
    # start addr now in s5, end addr now in s7
cmd_D_next_instruction:
    # print line prefix
    la      a0, string_line_prefix_D
    jal     print_string
    # print memory address
    mv      a0, s5                      # print current address
    jal     print_hex
    la      a0, string_asm_sep1
    jal     print_string
    # print word at this memory address
    lbu     a0, 3(s5)
    jal     print_hex_byte
    lbu     a0, 2(s5)
    jal     print_hex_byte
    lbu     a0, 1(s5)
    jal     print_hex_byte
    lbu     a0, 0(s5)
    jal     print_hex_byte
    la      a0, string_asm_sep2     
    jal     print_string
    # disassemble this word
    lw      a0, 0(s5)                   # load instruction word from addr
    jal     decode_opcode
    beqz    a1, cmd_D_opcode_unknown
    jal     print_instruction
    j       cmd_D_advance
cmd_D_opcode_unknown:
    la      a0, string_OP_UNKNOWN
    jal     print_string
    j       cmd_D_advance
cmd_D_advance:
    lw      t0, 0(s5)                   # load instruction word again
    addi    s5, s5, 2                   # advance 2 bytes in any case
    andi    t0,t0, 0b11                 # look at bit 0 and 1
    # compressed instructions either end in 0b01 or 0b10
    li      t1, 0b01                
    beq     t0, t1, cmd_D_advance_done  # it is a compressed instruction
    li      t1, 0b10
    beq     t0, t1, cmd_D_advance_done  # it is a compressed instruction
    # it was not a compressed instruction
    addi    s5, s5, 2                   # add 2 more bytes if not compressed
cmd_D_advance_done:
    bgt     s5, s7, cmd_D_done          # check if end address reached
    li      a0, ASCII_NEWLINE
    jal     print_char
    j       cmd_D_next_instruction
cmd_D_done:
    la      a0, last_address 
    SAVE_X  s5, 0(a0)
    j       main_prompt
.size cmd_D, .-cmd_D
 
 
.data
string_OP_UNKNOWN:      .string "???";
.size string_OP_UNKNOWN, .-string_OP_UNKNOWN
	
string_line_prefix_D:   .string ",";
.size string_line_prefix_D, .-string_line_prefix_D


#endif /* WITH_CMD_D */
