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
    mv      a0, s5                  # print current address
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
#if XLEN >= 64
    lwu     a0, 0(s5)               # load instruction word from addr
#else
    lw      a0, 0(s5)               # load instruction word from addr
#endif
    jal     decode_opcode
    beqz    a1, cmd_D_opcode_unknown
    jal     print_instruction
    j       cmd_D_advance
cmd_D_opcode_unknown:
    la      a0, string_OP_UNKNOWN
    jal     print_string
    j       cmd_D_advance
cmd_D_advance:
    # TODO: advance only 2 bytes if RVC opcode
    addi    s5, s5, 4               # point to next instruction
    bgt     s5, s7, cmd_D_done
    li      a0, ASCII_NEWLINE
    jal     print_char
    j       cmd_D_next_instruction
cmd_D_done:
    la      a0, last_address 
    SAVE_X  s5, 0(a0)
    j       main_prompt
 
 
.data
string_OP_UNKNOWN:      .string "???";
string_line_prefix_D:   .string ",";


#endif /* WITH_CMD_D */
