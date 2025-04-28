#include "vmon/config.h"
#include "vmon/ASCII.h"


.global skip_whitespace
.global get_hex_addr
.global find_word_end
.global is_ascii

.text

# in: buffer ptr in a0
skip_whitespace:
    li      t0, ' '
    li      t1, '\t'
skip_whitespace_next:
    lb      t2, 0(a0)               # get byte from buffer
    beq     t2, t0, skip_whitespace_advance 
    beq     t2, t1, skip_whitespace_advance
    j       skip_whitespace_done
skip_whitespace_advance:
    addi    a0, a0, 1               # advance buffer pointer
    j       skip_whitespace_next    
skip_whitespace_done:
    ret
.size skip_whitespace, .-skip_whitespace


# in: buffer ptr in a0
# out: ptr to end of word in a0
find_word_end:
    #lb      a0, 0(a0)

    ret
.size find_word_end, .-find_word_end


# in: char in a0
# out: 0 if FALSE, 1 if TRUE
is_ascii:
    mv      t2, a0
    mv      a0, zero
    li      t0, 'a'
    blt     t2, t0, is_ascii_done   # not ASCII
    li      t1, 'z'
    bgt     t2, t1, is_ascii_done   # not ASCII
    li      a0, 1                   # is ASCII
is_ascii_done:
    ret


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
