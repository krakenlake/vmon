#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/register.h"
#include "vmon/stack.h"


.global skip_whitespace
.global expect_char
.global expect_open_paren
.global expect_close_paren
.global parse_insn_string
.global find_register_name_end
.global parse_binary
.global	parse_decimal
.global	parse_iorw
.global	parse_aqrl
.global	get_numeric


.text


# in: a0 = buffer ptr
# out: a0 = buffer ptr to next non-whitespace char
# PRESERVE t0
skip_whitespace:
	lb		t1, 0(a0)				# get byte from buffer
	li		t2, ' '
	beq		t1, t2, skip_whitespace_advance
	li		t2, '\t'
	beq		t1, t2, skip_whitespace_advance
	ret
skip_whitespace_advance:
	addi	a0, a0, 1				# advance buffer pointer
	j		skip_whitespace
.size skip_whitespace, .-skip_whitespace


# expect a specific char and advance buffer ptr to next non-whitespace char after that char
# in: a0 = buffer ptr
# in: a4 = char to expect
# out: a0 = buffer ptr after comma (0 on error)
expect_char:
	PUSH_RA
	jal 	skip_whitespace
	lb		t1, 0(a0)
	beq		t1, a4, expect_char_match	# found match
	li		a0, 0
	j		expect_char_done
expect_char_match:
	addi	a0, a0, 1
	jal 	skip_whitespace
expect_char_done:
	POP_RA_RET
.size expect_char, .-expect_char


# in: buffer ptr in a0
# out: a0 = buffer ptr after comma or a0 = 0 on error
expect_open_paren:
	li		a4, '('
	j 		expect_char
.size expect_open_paren, .-expect_open_paren


# in: buffer ptr in a0
# out: a0 = buffer ptr after comma or a0 = 0 on error
expect_close_paren:
	li		a4, ')'
	j 		expect_char
.size expect_close_paren, .-expect_close_paren


# in: buffer ptr in a0
# out: a0 = ptr to end of parsed insn word
# out: a1 = ptr to second '.' if present (otherwise 0)
parse_insn_string:
	PUSH_RA
	li		a1, 0						# clear second dot ptr 
	li		t2, 2						# count dots here for RVA insns
parse_insn_string_loop:
	lb		t0, 0(a0)
	# accept '.'
	li		t1, '.'
	bne		t0, t1, parse_insn_string_no_dot
	# we have a dot
	addi	t2, t2, -1
	bnez	t2, parse_insn_string_valid_char
	# second dot is present
	mv		a1, a0
	j 		parse_insn_string_valid_char
parse_insn_string_no_dot:
	# accept a-z and 0-9 in insn names
	jal		isalnum
	beqz	a2, parse_insn_string_done
parse_insn_string_valid_char:
	addi	a0, a0, 1
	j		parse_insn_string_loop
parse_insn_string_done:
	POP_RA_RET
.size parse_insn_string, .-parse_insn_string


# in: buffer ptr in a0
# out: ptr to end of word in a0
find_register_name_end:
	PUSH_RA
find_register_name_end_loop:
	jal		isalnum
	beqz	a2, find_register_name_end_done
find_register_name_end_valid_char:
	addi	a0, a0, 1
	j		find_register_name_end_loop
find_register_name_end_done:
	addi	a0, a0, -1
	POP_RA_RET
.size find_register_name_end, .-find_register_name_end


# in: buffer ptr in a0
# out: a2 = 1 if yes, else 0
isalnum:
	li		a2, 0					# default no
	lb		t0, 0(a0)
	# accept a-z and 0-9
	li		t1, '0'
	blt		t0, t1, isalnum_done
	li		t1, 'z'
	bgt		t0, t1, isalnum_done
	li		t1, '9'
	ble		t0, t1, isalnum_yes
	li		t1, 'a'
	bge		t0, t1, isalnum_yes
isalnum_yes:
	li		a2, 1
isalnum_done:
	ret
.size isalnum, .-isalnum


# in: buffer ptr in a0
# out: buffer ptr in a0
# out: parsed value in a1
# out: error code in a2 (OK=0)
get_numeric:
	PUSH_S1_S0_RA
	mv		a2, zero						# clear error
	lb		t0, 0(a0)
	li		t1, '0'
	beq		t0, t1, get_numeric_hex_bin
	j		get_numeric_dec
get_numeric_hex_bin:						# first char is '0'
	lb		t0, 1(a0)
	li		t1, 'x'
	beq		t0, t1, get_numeric_hex			# second char is 'x'
	li		t1, 'b'
	beq		t0, t1, get_numeric_bin			# second char is 'b'
	# not hex, not bin, take it as decimal
	j		get_numeric_dec
get_numeric_hex:
	addi	a0, a0, 2
	jal		parse_hex
	j		get_numeric_done
get_numeric_bin:
	addi	a0, a0, 2
	jal		parse_binary
	j		get_numeric_done
get_numeric_dec:
	jal		parse_decimal
	j		get_numeric_done
get_numeric_error:
	li		a2, -1
get_numeric_done:
	POP_S1_S0_RA_RET
.size get_numeric, .-get_numeric


# parse hex value (without "0x" prefix)
# in: buffer ptr in a0
# out: buffer ptr in a0
# out: parsed address value in a1
# out: error code in a2 (OK=0)
parse_hex:
	li		a1, 0					# reset return value
	li		a2, -1					# set error flag
	li		a5, 0					# digit found flag (0=no)
parse_hex_next_byte:
	lb		t0, 0(a0)				# get byte from buffer
	addi	t1, t0, -'0'
	sltiu	t2, t1, 10				# is it 0-9 ?
	bnez	t2, parse_hex_add_nibble
	addi	t1, t0, -'a'
	sltiu	t2, t1, 6				# 0-5 (maps to 'a' - 'f')
	beqz	t2, parse_hex_check		# found invalid char
	add		t1, t1, 10				# t1 is now 10-15
parse_hex_add_nibble:
	li		a5, 1					# set digit found flag
	slli	a1, a1, 4
	or		a1, a1, t1
	addi	a0, a0, 1
	j		parse_hex_next_byte
parse_hex_check:
	beqz	a5, parse_hex_return	# no digits -> err return
	li		a2, 0					# clear error code
parse_hex_return:
	ret
.size parse_hex, .-parse_hex


# in: buffer ptr in a0
# out: buffer ptr in a0
# out: parsed binary number in a1
# out: error code in a2 (OK=0)
parse_binary:
	li		a2, -1
	addi	a1, x0, 0
	li		a5, 0
parse_binary_next_bit:
	lb		t0, 0(a0)
	addi	t1, t0, -'0' 				# valid digits will be 0 or 1
	sltiu	t2, t1, 2	 				# t2 = (t1 < 2U) ? 1 : 0 - check if t1 is 0 or 1
	bnez	t2, parse_binary_bit
	# check for valid terminators
	li		t1, ' '
	beq		t0, t1, parse_binary_return
	li		t1, ASCII_RETURN
	beq		t0, t1, parse_binary_return
	# character is not 0, 1, space, or return - return error
	ret
parse_binary_bit:
	li		a5, 1
	slli	a1, a1, 1
	or		a1, a1, t1
	addi	a0, a0, 1
	j		parse_binary_next_bit
parse_binary_return:
	beqz	a5, parse_binary_return_error
	li		a2, 0
parse_binary_return_error:
	ret
.size parse_binary, .-parse_binary


# signed decimal input
# in: buffer ptr in a0
# out: buffer ptr in a0
# out: parsed binary number in a1
# out: error code in a2 (OK=0)
parse_decimal:
	li		a1, 0							# result
	li		a3, 0							# digit found flag
	li		a2, 0							# negative flag
	# check for negative number
	lb		t0, 0(a0)
	li		t1, '-'
	bne		t0, t1, parse_decimal_plus
	li		a2, 1							# number is negative
	addi	a0, a0, 1
	j		parse_decimal_loop
parse_decimal_plus:
	li		t1, '+'
	bne		t0, t1, parse_decimal_loop		# no leading +, assume positive
	addi	a0, a0, 1
parse_decimal_loop:
	lb		t0, 0(a0)
	addi	t1, t0, -'0'					# potential digit value
	sltiu	t2, t1, 10						# is potential digit 0-9? (t2=1 if yes)
	beqz	t2, parse_decimal_check_flag	# if not 0-9
	# have a valid decimal digit, multiply accumulator by 10
	# and add in the new digit value.
	li		a3, 1
	# a1 = a1 * 10
	slli	a4, a1, 3						# a4 = a1 * 8
	slli	a5, a1, 1						# a5 = a1 * 2
	add		a1, a5, a4						# a1 = a1 * 10
	# a1 = a1 + digit_value
	add		a1, a1, t1
	addi	a0, a0, 1						# ptr++
	j		parse_decimal_loop
parse_decimal_check_flag:
	beqz	a3, parse_decimal_error			# If a3=0, error
	# apply sign, if necessary
	beqz	a2, parse_decimal_set_success
	sub		a1, x0, a1						# 2's complement negation
parse_decimal_set_success:
	li		a2, 0							# clear error code
	j		parse_decimal_done
parse_decimal_error:
	li		a2, -1							# set error code
parse_decimal_done:
	ret
.size parse_decimal, .-parse_decimal


# parse a FENCE iorw parameter
# in: buffer ptr in a0
# out: buffer ptr in a0
# out: iorw bits in bits 0-3 of a1
# out: error code in a2 (OK=0)
parse_iorw:
	mv		a1, zero					# clear return value
	mv		a2, zero					# clear error
parse_iorw_loop:
	lb		t0, 0(a0)					# get next input char
	addi	a0, a0, 1					# advance one char
	# accept 'i', 'o', 'r', 'w' and set bits in a1 accordingly
	li		t2, 'i'
	beq		t0, t2, parse_iorw_add_i
	li		t2, 'o'
	beq		t0, t2, parse_iorw_add_o
	li		t2, 'r'
	beq		t0, t2, parse_iorw_add_r
	li		t2, 'w'
	beq		t0, t2, parse_iorw_add_w		# no further shift of t1 necessary
	addi	a0, a0, -1					# one step back if no match
	j		parse_iorw_done
parse_iorw_add_i:
	ori		a1, a1, 1 << 3
	j		parse_iorw_loop
parse_iorw_add_o:
	ori		a1, a1, 1 << 2
	j		parse_iorw_loop
parse_iorw_add_r:
	ori		a1, a1, 1 << 1
	j		parse_iorw_loop
parse_iorw_add_w:
	ori		a1, a1, 1
	j		parse_iorw_loop
parse_iorw_done:
	ret
.size parse_iorw, .-parse_iorw


# parse aqrl string for RVA insns
# in: buffer ptr in a0
# out: buffer ptr in a0
# out: aqrl bits in bits 25-26 of a1
parse_aqrl:
	mv		a1, zero						# clear assembly bits return value
parse_aqrl_loop:
	lb		t0, 0(a0)						# get next input char
	# accept "aq" or "rl" and set bits in a1 accordingly
	li		t2, 'a'
	beq		t0, t2, parse_aqrl_need_q
	li		t2, 'r'
	beq		t0, t2, parse_aqrl_need_l
	# when we encounter anything other than 'a' or 'r' we are done
	j		parse_aqrl_done
parse_aqrl_need_q:
	lb		t0, 1(a0)						# get char after current
	li		t2, 'q'
	beq		t0, t2, parse_aqrl_add_aq_bit	# we have aq
	j		parse_aqrl_done
parse_aqrl_add_aq_bit:
	ori		a1, a1, 0b10
	j		parse_aqrl_advance
parse_aqrl_need_l:
	lb		t0, 1(a0)						# get char after current
	li		t2, 'l'
	beq		t0, t2, parse_aqrl_add_rl_bit	# we have rl
	j		parse_aqrl_done
parse_aqrl_add_rl_bit:
	ori		a1, a1, 0b1
parse_aqrl_advance:
	addi	a0, a0, 2
	j		parse_aqrl_loop
parse_aqrl_done:
	slli	a1, a1, 25
	ret
.size parse_aqrl, .-parse_aqrl
