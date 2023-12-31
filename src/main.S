/*
    VMON - a RISC-V machine code monitor written in RISC-V assembly code

    global register use:
    s1 = UART base addr
    s2 = text buffer start addr
    s3 = text buffer ptr to last character
    s5 = address of current instruction being disassembled   
*/


#include "vmon/config.h"
#include "vmon/UART.h"
#include "vmon/ASCII.h"


.global start
.global prompt
.global string_asm_sep1
.global string_asm_sep2
.global string_asm_comment
.global string_OP_UNKNOWN
.global start_data
.global start_bss


.text

start:

#ifdef BARE_METAL
    # run only on hart 0
    csrr    t0, mhartid
    bnez    t0, end
    
    # set up a stack 
    mv      t0, sp                      # save caller sp for later
    la      sp, stack + STACK_SIZE      # point to end of our new stack
#endif /* BARE_METAL */

    # save registers on new stack
    addi    sp, sp, -(XLEN_BYTES*14)         
    SAVE_X  ra, 0(sp)  
    SAVE_X  t0, (XLEN_BYTES*1)(sp)      # the original sp from above
    SAVE_X  s0, (XLEN_BYTES*2)(sp)
    SAVE_X  s1, (XLEN_BYTES*3)(sp)
    SAVE_X  s2, (XLEN_BYTES*4)(sp)
    SAVE_X  s3, (XLEN_BYTES*5)(sp)
    SAVE_X  s4, (XLEN_BYTES*6)(sp)
    SAVE_X  s5, (XLEN_BYTES*7)(sp)
    SAVE_X  s6, (XLEN_BYTES*8)(sp)
    SAVE_X  s7, (XLEN_BYTES*9)(sp)
    SAVE_X  s8, (XLEN_BYTES*10)(sp)
    SAVE_X  s9, (XLEN_BYTES*11)(sp)
    SAVE_X  s10, (XLEN_BYTES*12)(sp)
    SAVE_X  s11, (XLEN_BYTES*13)(sp)

    # init UART 
    li      s1, UART_BASE                  
    li      t0, UART_MODE_8N1
    sb      t0, UART_REG_LSR(s1)      

    # startup message
    la      a0, string_startup
    jal     print_string

    # main loop
prompt:
    la      a0, string_prompt
    jal     print_string
    # reset text buffer boundaries in s2, s3
    la      s2, buffer              # s2:= buffer start
    mv      s3, s2
    jal     clear_buffer

get_char:
    # wait for key pressed
    # TODO: use interrupt instead of polling
    lb      t0, 5(s1)               # read Line Status Register
    and     t0, t0, 0x01
    beqz    t0, get_char            # wait for char input
    lbu     a0, 0(s1)               # get input from UART  
    li      t0, ASCII_DELETE        
    beq     a0, t0, is_delete
    sb      a0, 0(s3)               # store byte in text buffer
    addi    s3, s3, 1               # inc buffer ptr
    j       not_delete
is_delete:
    # TODO: if the previous key transmitted more than 1 byte, this does 
    # not work properly 
    beq     s3, s2, get_char        # ignore at beginning of line
    addi    s3, s3, -1
    li      a0, ASCII_BACKSPACE     
    sb      a0, 0(s1)               # print to UART
    li      a0, ' '     
    sb      a0, 0(s1)               # print to UART
    li      a0, ASCII_BACKSPACE     
    sb      a0, 0(s1)               # print to UART
    j       get_char  
not_delete:
    sb      a0, 0(s1)               # print to UART
    li      t0, ASCII_RETURN        
    beq     a0, t0, get_command
    j       get_char      

get_command:
    # print newline
    li      t0, ASCII_NEWLINE
    sb      t0, 0(s1)               # print to UART
    # buffer start addr is in s2
    # last character is at s3-1
    mv      s4, s2
    # will be incremented in the following loop again
    addi    s4, s4, -1
    # advance to next non-whitespace char in buffer
    # TODO: should be an error if there is not at least 1 space
    mv      a0, s4
    jal     skip_whitespace
    mv      s4, a0
    # take first non-whitespace char in line as command
    lb      t1, 0(s4)               # get byte from buffer

#ifdef WITH_CMD_D
    li      t0, 'd'
    beq     t1, t0, cmd_D
#endif

#ifdef WITH_CMD_G
    li      t0, 'g'
    beq     t1, t0, cmd_G
#endif

#ifdef WITH_CMD_H
    li      t0, 'h'
    beq     t1, t0, cmd_H
    li      t0, '?'
    beq     t1, t0, cmd_H
#endif

#ifdef WITH_CMD_I
    li      t0, 'i'
    beq     t1, t0, cmd_I
#endif

#ifdef WITH_CMD_M
    li      t0, 'm'
    beq     t1, t0, cmd_M
#endif

#ifdef WITH_CMD_X
    li      t0, 'x'
    beq     t1, t0, cmd_X
#endif

    # no command given, user only hit return
    li      t0, ASCII_RETURN
    beq     t1, t0, prompt

unknown_command:
    la      a0, error_unknown_command
    jal     print_string
    j       prompt
    # end of main loop


#ifdef BARE_METAL
    # only if hart !=0
end: 
    wfi
    j       end
#endif /* BARE_METAL */


clear_buffer:
    la      t0, buffer
    addi    t1, t0, BUFFER_SIZE
clear_buffer_loop:
    sw      zero, 0(t0)
    addi    t0, t0, 4
    ble     t0, t1, clear_buffer_loop
    ret


.data
start_data:

string_startup:     .string "\nVMON - RISC-V machine code monitor";
string_prompt:      .string "\n.";

string_asm_sep1:    .string ":";
string_asm_sep2:    .string "\t";
string_asm_comment: .string "\t# ";

.bss
start_bss:
.align 8
.comm last_address, XLEN_BYTES  # last address used in m or d command

.align 8
.comm buffer, BUFFER_SIZE       # for command line input

.align 8
.comm stack, STACK_SIZE         # our execution stack
