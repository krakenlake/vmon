#include "vmon/config.h"


.global print_hex
.global print_hex_raw
.global print_hex_byte
.global print_ascii
.global print_string
.global print_decimal
.global print_star

#define OUTBUFFER_SIZE      32

.text


print_hex:
    # in: print value in a0 in hex with "0x" prefix
    li      t1, '0'
    sb      t1, 0(s1)               # print to UART
    li      t1, 'x'
    sb      t1, 0(s1)               # print to UART
print_hex_raw:
    # in: print value in a0 in hex
    # no trailing zeroes, no prefix
    addi    sp, sp, -(XLEN_BYTES*1)             
    SAVE_X  ra, 0(sp)

    # terminate buffer at the end
    # TODO: do buffer termination only once
    la      t2, outbuf
    addi    t2, t2, (OUTBUFFER_SIZE-1)
    sb      zero, 0(t2)
    # print to output buffer backwards
    li      t3, 9
print_hex_new_next_nibble:
    addi    t2, t2, -1
    andi    t0, a0, 0x0f
    # digit < 10?
    ble     t0, t3, print_hex_new_decimal
    addi    t0, t0, 39
print_hex_new_decimal:    
    addi    t0, t0, 48
    sb      t0, 0(t2)                       # to buffer
    srli    a0, a0, 4                       # next nibble
    bnez    a0, print_hex_new_next_nibble   # only if more to come
    # print buffer
    mv      a0, t2
    jal     print_string

    LOAD_X  ra, 0(sp)             
    addi    sp, sp, (XLEN_BYTES*1)
    ret


print_hex_byte:
    # print a 2-digit hex value (with leading zero for 1-digit values)
    # in: byte value in a0
    addi    sp, sp, -(XLEN_BYTES*1)             
    SAVE_X  ra, 0(sp)
    li      t0, 15
    bgt     a0, t0, print_hex_byte_two_digits
    # print a leading zero if necessary
    li      t0, '0'
    sb      t0, 0(s1)               # print to UART 
print_hex_byte_two_digits:
    jal     print_hex_raw
    LOAD_X  ra, 0(sp)             
    addi    sp, sp, (XLEN_BYTES*1)
    ret


# print char in a0 to terminal (if printable, else '.')
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

#ifdef WITH_CMD_D

# print 32-bit signed decimal in a0 to terminal
print_decimal:
    addi    sp, sp, -(XLEN_BYTES*1)           
    SAVE_X  ra, 0(sp)

    beqz    a0, print_decimal_zero
    # save a0
    mv      t6, a0
    # terminate buffer at the end
    la      t2, outbuf
    addi    t2, t2, (OUTBUFFER_SIZE-1)
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

#endif /* WITH_CMD_D */

.data

.align 8

.comm outbuf, OUTBUFFER_SIZE

