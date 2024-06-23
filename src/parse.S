#include "vmon/config.h"
#include "vmon/ASCII.h"


.global skip_whitespace
.global get_hex_addr

.text

# in: buffer ptr in a0
skip_whitespace:
    # load only once when called
    li      t0, ' '
    li      t1, '\t'
skip_whitespace_next_byte:
    addi    a0, a0, 1               # advance buffer pointer
    lb      t2, 0(a0)               # get byte from buffer
    # skip whitespace at beginning of line
    beq     t2, t0, skip_whitespace_next_byte 
    beq     t2, t1, skip_whitespace_next_byte 
    ret
.size skip_whitespace, .-skip_whitespace


# in: buffer ptr in a0
# out: buffer ptr in a0
# out: parsed address value in a1
# out: error code in a2 (OK=0)
get_hex_addr:
    li      a1, 0                   # reset address value
    li      a2, -1                  # set error code
get_hex_addr_next_byte:
    lb      t0, 0(a0)               # get byte from buffer
    li      t1, ' '                 # end parsing at next space or return
    beq     t0, t1, get_hex_addr_return      
    li      t1, ASCII_RETURN
    beq     t0, t1, get_hex_addr_return      
    li      t1, '0'                 
    blt     t0, t1, get_hex_addr_return_error
    li      t1, '9'
    bgt     t0, t1, get_hex_addr_check_alpha    
    # got a digit
    li      a2, 0                   # clear error code
    sll     a1, a1, 4   
    addi    t0, t0, -48
    or      a1, a1, t0
    addi    a0, a0 ,1               # advance buffer ptr
    j       get_hex_addr_next_byte
get_hex_addr_check_alpha:
    li      t1, 'a'
    blt     t0, t1, get_hex_addr_return_error
    li      t1, 'f'
    bgt     t0, t1, get_hex_addr_return_error    
    # got a valid alpha
    li      a2, 0                   # clear error code
    sll     a1, a1, 4   
    addi    t0, t0, -87
    or      a1, a1, t0
    addi    a0, a0 ,1               # advance buffer ptr
    j       get_hex_addr_next_byte
 get_hex_addr_return_error:
    li      a2, -1
 get_hex_addr_return:   
    ret	
.size get_hex_addr, .-get_hex_addr
