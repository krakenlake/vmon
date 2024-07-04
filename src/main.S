/*
    VMON - a RISC-V machine code monitor written in RISC-V assembly code
*/


#include "vmon/config.h"
#include "vmon/drivers/uart/ns16550.h"
#include "vmon/ASCII.h"


.global start
.global main_prompt
.global string_asm_sep1
.global string_asm_sep2
.global string_asm_comment
.global string_OP_UNKNOWN
.global start_data
.global start_bss


.text

/*
    application entry point

    s2 = text input buffer start addr
    s3 = text input buffer ptr to last character
    s5 = address of current instruction being disassembled   
*/
start:

    # I am alive
    # try to output one char in the simplest way possible
    # this will happen on all harts
#ifdef DEBUG
    li      t1, UART_BASE                  
    li      t0, UART_MODE_8N1
    sb      t0, UART_REG_LSR(t1)
    li      t0, '*'
    sb      t0, UART_REG_THR(t1)      
#endif

#ifdef BARE_METAL

    #ifdef HW_QEMU
        # run only on hart 0
        # this works only in M-mode
        csrr    t0, mhartid
        bnez    t0, end
    #endif

    #ifdef HW_VF2
        # TODO: csrr is not allowed when called from U-Boot on VF2 (S-mode)    
    #endif

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
    jal     uart_init

    # startup message
    la      a0, string_startup
    jal     print_string

    # main loop
main_prompt:
    la      a0, string_prompt
    jal     print_string
    # reset text buffer boundaries in s2, s3
    la      s2, buffer              # s2:= buffer start
    mv      s3, s2
    jal     main_clear_buffer
main_get_char:
    jal     uart_wait_get_char
    li      t0, ASCII_DELETE        
    beq     a0, t0, is_delete
    # char is not DELETE
    sb      a0, 0(s3)               # store byte in input buffer
    addi    s3, s3, 1               # inc buffer ptr
    j       continue_not_delete
is_delete:
    # TODO: if the previous key transmitted more than 1 byte, this does 
    # not work properly 
    beq     s3, s2, main_get_char        # ignore at beginning of line
    addi    s3, s3, -1
    # ASCII output
    li      a0, ASCII_BACKSPACE
    jal     print_char
    li      a0, ' '
    jal     print_char
    li      a0, ASCII_BACKSPACE
    jal     print_char
    j       main_get_char  
continue_not_delete:
    # output char in a0
    jal     print_char
    li      t0, ASCII_RETURN        
    beq     a0, t0, get_command
    j       main_get_char      
get_command:
    li      a0, ASCII_NEWLINE
    jal     print_char

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
.size start, .-start

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
    beq     t1, t0, main_prompt

unknown_command:
    la      a0, error_unknown_command
    jal     print_string
    j       main_prompt
    # end of main loop


#ifdef BARE_METAL
    # only if hart !=0
end: 
    wfi
    j       end
#endif /* BARE_METAL */


main_clear_buffer:
    la      t0, buffer
    addi    t1, t0, BUFFER_SIZE
main_clear_buffer_loop:
    sw      zero, 0(t0)
    addi    t0, t0, 4
    ble     t0, t1, main_clear_buffer_loop
    ret
.size main_clear_buffer, .-main_clear_buffer


.data
start_data:

string_startup:     .string "\nVMON - RISC-V machine code monitor";
.size string_startup, .-string_startup
string_prompt:      .string "\n> ";
.size string_prompt, .-string_prompt

string_asm_sep1:    .string ":";
.size string_asm_sep1, .-string_asm_sep1
string_asm_sep2:    .string "\t";
.size string_asm_sep2, .-string_asm_sep2
string_asm_comment: .string "\t# ";
.size string_asm_comment, .-string_asm_comment

.bss
start_bss:
.align 8
.comm last_address, XLEN_BYTES  # last address used in m or d command
.size last_address, XLEN_BYTES
	
.align 8
.comm buffer, BUFFER_SIZE       # for command line input
.size buffer, BUFFER_SIZE
        
.align 8
.comm stack, STACK_SIZE         # our execution stack
.size stack, STACK_SIZE
