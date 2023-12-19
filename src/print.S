#include "vmon/config.h"

.global print_hex_prefix
.global print_hex_addr
.global print_hex_word
.global print_hex_byte
.global print_ascii
.global print_string
.global print_decimal
.global print_star

#define DECBUFFER_SIZE      32

.text

print_hex_prefix:
    # output prefix
    li      t1, '0'
    sb      t1, 0(s1)               # print to UART
    li      t1, 'x'
    sb      t1, 0(s1)               # print to UART
    ret

print_hex_addr:
    # print addr passed in a0 in hex
    addi    sp, sp, -(XLEN_BYTES*2)             
    SAVE_X  ra, 0(sp)
    SAVE_X  a0, (XLEN_BYTES*1)(sp)
    # output prefix
	jal     print_hex_prefix
    # split 64 bit into 32-bit words
    srli    a0, a0, 16
    srli    a0, a0, 16
#if XLEN >= 64
    jal     print_hex_word
#endif
    LOAD_X  a0, (XLEN_BYTES*1)(sp)
    jal     print_hex_word
    LOAD_X  ra, 0(sp)             
    addi    sp, sp, (XLEN_BYTES*2)
    ret


print_hex_word:
    # in: word in a0
    # out: word in a0
    addi    sp, sp, -(XLEN_BYTES*3)           
    SAVE_X  ra, 0(sp)
    SAVE_X  s2, (XLEN_BYTES*1)(sp)
    SAVE_X  a0, (XLEN_BYTES*2)(sp)
    li      t0, 0xffffffff
    and     s2, a0, t0              # save lower 32 bits
    srli    a0, s2, 24
    jal     print_hex_byte
    srli    a0, s2, 16
    andi    a0, a0, 0xff
    jal     print_hex_byte
    srli    a0, s2, 8
    andi    a0, a0, 0xff
    jal     print_hex_byte
    andi    a0, s2, 0xff
    jal     print_hex_byte
    LOAD_X  ra, 0(sp)             
    LOAD_X  s2, (XLEN_BYTES*1)(sp)               
    LOAD_X  a0, (XLEN_BYTES*2)(sp)               
    addi    sp, sp, (XLEN_BYTES*3)
    ret


print_hex_byte:
    # print byte passed in a0 in hex
    mv      a1, a0                  # duplicate a0 for later
    li      a2, 10
    # left nibble
    and     a0, a0, 0x000000f0
    srli    a0, a0, 4
    blt     a0, a2, print_hex_byte_is_digit
    add     a0, a0, 7+32           
print_hex_byte_is_digit:
    add     a0, a0, 0x30           
    sb      a0, 0(s1)               # print to UART
    # right nibble
    and     a0, a1, 0x0000000f
    blt     a0, a2, print_hex_byte_is_digit2
    add     a0, a0, 7+32           
print_hex_byte_is_digit2:
    add     a0, a0, 0x30           
    sb      a0, 0(s1)               # print to UART
    ret


# print char in a0 to terminal
print_ascii:
    mv      t1, a0
    # consider only chars from 0x20-0x7e as printable
    li      t0, 0x20
    blt     t1, t0, print_ascii_substitute
    li      t0, 0x7e
    bgt     t1, t0, print_ascii_substitute
    j       print_ascii_out         # char is printable
print_ascii_substitute:
    li      t1, '.'                 # print dot if char is not printable
print_ascii_out:
    sb      t1, 0(s1)               # print to UART
    ret


# print string starting at addr in a0 to terminal
print_string:
    mv      t1, a0  
print_string_next_byte:
    lbu     t0, 0(t1)
    beq     t0, zero, print_string_done
    sb      t0, 0(s1)               # print to UART
    addi    t1, t1, 1
    j       print_string_next_byte
print_string_done:
    ret


# print 32-bit signed decimal in a0 to terminal
print_decimal:
    addi    sp, sp, -(XLEN_BYTES*1)           
    SAVE_X  ra, 0(sp)

    beqz    a0, print_decimal_zero
    # save a0
    mv      t6, a0
    # terminate buffer at the end
    la      t2, decbuf
    addi    t2, t2, (DECBUFFER_SIZE-1)
    sb      zero, 0(t2)
    # invert if negative
    bgtz    t6, print_decimal_skip_invert
    neg     a0, a0
print_decimal_skip_invert:
    # write ASCII digits to buffer backward starting at the end
    li      t3, 10
print_decimal_loop:
    # dec buffer ptr
    addi    t2, t2, -1
    # t4 = a0 mod 10
    rem     t4, a0, t3
    # a0 = a0 / 10
    div     a0, a0, t3  
    # output digit as ASCII to buffer
    addi    t0, t4, 48
    sb      t0, 0(t2)
    # repeat
    bnez    a0, print_decimal_loop   
    # print minus if negative
    bgtz    t6, print_decimal_skip_minus
    li      t0, '-'
    sb      t0, 0(s1)               # print to UART
print_decimal_skip_minus:
    # output buffer, starting at last written location
    mv      a0, t2
    jal     print_string
    j       print_decimal_done
print_decimal_zero:
    li      t0, '0'
    sb      t0, 0(s1)               # print to UART

print_decimal_done:
    LOAD_X     ra, 0(sp)             
    addi    sp, sp, (XLEN_BYTES*1)
    ret


.data

.align 8

.comm decbuf, DECBUFFER_SIZE

