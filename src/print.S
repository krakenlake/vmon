#include "vmon/config.h"
#include "vmon/ASCII.h"


.global print_hex
.global print_hex_raw
.global print_hex_byte
.global print_ascii
.global print_char
.global print_string
.global print_decimal
.global print_binary
.global print_comma
.global print_newline
.global out_buf


#define OUT_BUFFER_SIZE		32

.text


print_comma:
	addi	sp, sp, -(XLEN_BYTES*1)	
	SAVE_X	ra, 0(sp)
	li		a0, ','
	jal		print_char
	#ifdef SPACE_AFTER_COMMA
	li		a0, ' '
	jal		print_char
	#endif
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	ret
.size print_comma, .-print_comma


print_newline:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	#ifdef USE_CRLF
	li		a0, ASCII_RETURN
	jal		print_char
	#endif
	li		a0, ASCII_NEWLINE
	jal		print_char
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	ret
.size print_newline, .-print_newline


# in: print value in a0 in hex with "0x" prefix
print_hex:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	# print "0x"
	mv		s1, a0						# save a0 for later
	li		a0, '0'
	jal		print_char
	li		a0, 'x'
	jal		print_char
	mv		a0, s1						# restore a0
	# print value
	jal		print_hex_raw
	LOAD_X	ra, 0(sp)
	LOAD_X	s1, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size print_hex, .-print_hex


# in: print value in a0 in hex
# no trailing zeroes, no prefix
print_hex_raw:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	# terminate buffer at the end
	# TODO: do buffer termination only once
	la		t2, out_buf
	addi	t2, t2, (OUT_BUFFER_SIZE-1)
	sb		zero, 0(t2)
	# print to output buffer backwards
print_hex_new_next_nibble:
	addi	t2, t2, -1 
	andi	t0, a0, 0x0f
	# digit < 10?
	sltiu	t3, t0, 10
	bnez	t3, print_hex_new_decimal
	addi	t0, t0, 39
print_hex_new_decimal:
	addi	t0, t0, 48
	sb		t0, 0(t2)						# to buffer
	srli	a0, a0, 4						# next nibble
	bnez	a0, print_hex_new_next_nibble	# only if more to come
	# print buffer
	mv		a0, t2
	jal		print_string
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	ret
.size print_hex_raw, .-print_hex_raw


# print a 2-digit hex value (with leading zero for 1-digit values)
# in: byte value in a0
print_hex_byte:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	li		t0, 15
	bgt		a0, t0, print_hex_byte_two_digits
	# print a leading zero if necessary
	mv		s1, a0					# save a0 for later
	li		a0, '0'
	jal		print_char
	mv		a0, s1					# restore a0
print_hex_byte_two_digits:
	jal		print_hex_raw
	LOAD_X	ra, 0(sp)
	LOAD_X	s1, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size print_hex_byte, .-print_hex_byte


# print char in a0 to terminal (if printable, else '.')
print_ascii:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	# consider only chars from 0x20-0x7e as printable
	li		t0, 0x20
	blt		a0, t0, print_ascii_substitute
	li		t0, 0x7e
	bgt		a0, t0, print_ascii_substitute
	j		print_ascii_out			# char is printable
print_ascii_substitute:
	li		a0, '.'					# print dot if char is not printable
print_ascii_out:
	jal		print_char
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	ret
.size print_ascii, .-print_ascii


# print ASCII char in a0
print_char:
	j		uart_output_char
.size print_char, .-print_char


# print string starting at addr in a0
print_string:
	j		uart_output_string
.size print_string, .-print_string


#if defined(WITH_CMD_D) || defined(WITH_CMD_SLASH)

# print 32/64-bit signed decimal in a0 to terminal
print_decimal:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s2, (XLEN_BYTES*1)(sp)
	beqz	a0, print_decimal_zero
	# save a0
	mv		t6, a0
	# terminate buffer at the end
	la		s2, out_buf
	addi	s2, s2, (OUT_BUFFER_SIZE-1)
	sb		zero, 0(s2)
	# invert if negative
	bgtz	t6, print_decimal_skip_invert
	neg		a0, a0
print_decimal_skip_invert:
	# write ASCII digits to buffer backward starting at the end
print_decimal_loop:
	# dec buffer ptr
	addi	s2, s2, -1
	li		a1, 10
	# a0 = quotient, a1 = divisor
	jal		divrem
	# output digit as ASCII to buffer
	addi	t0, a1, 48
	sb		t0, 0(s2)
	# repeat
	bnez	a0, print_decimal_loop
	# print minus if negative
	bgtz	t6, print_decimal_skip_minus
	li		a0, '-'
	jal		print_char
print_decimal_skip_minus:
	# output buffer, starting at last written location
	mv		a0, s2
	jal		print_string
	j		print_decimal_done
print_decimal_zero:
	li		a0, '0'
	jal		print_char
print_decimal_done:
	LOAD_X	ra, 0(sp)
	LOAD_X	s2, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size print_decimal, .-print_decimal
#endif /* defined(WITH_CMD_D) || defined(WITH_CMD_SLASH) */


#ifdef WITH_CMD_SLASH

# print a0 in binary (64 or 32 bits)
print_binary:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X  s1, 0(sp)
	SAVE_X  s0, (XLEN_BYTES*1)(sp)
	SAVE_X  ra, (XLEN_BYTES*2)(sp)
	mv		s0, a0	       # Use s0 to store the number being processed
	li		s1, XLEN       # Use s1 for the loop counter (32/64 down to 0)
print_binary_loop:
	beqz	s1, print_binary_end # If loop counter is 0, we are done.
	srai	t2, s0, XLEN-1 # Arithmetically shift s0 right by 31/63. t2 = 0 or -1.
	andi	t2, t2, 1      # Isolate the least significant bit. t2 is now 0 or 1.
	addi	a0, t2, '0'    # Calculate ASCII char: '0' or '1'. a0 has the char.
	call	print_char
	slli	s0, s0, 1      # Shift the number left by 1 bit.
	addi	s1, s1, -1     # Decrement loop counter
	# Print a space every 8 bits for readability
	beqz	s1, print_binary_skip_space # If loop counter is 0, we are finished
	andi	t3, s1, 7		    # t3 = s1 & 0b111 (s1 mod 8).
	bnez	t3, print_binary_skip_space # If loop counter is not a multiple of 8, skip space.
	li		a0, ' '	       # Load ASCII space character into a0
	call	print_char
print_binary_skip_space:
	j		print_binary_loop
print_binary_end:
	LOAD_X  s1, 0(sp)
	LOAD_X  s0, (XLEN_BYTES*1)(sp)
	LOAD_X  ra, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size print_binary, .-print_binary

#endif /* WITH_CMD_SLASH */


.data


.align 8
.comm out_buf, OUT_BUFFER_SIZE
.size out_buf, OUT_BUFFER_SIZE

