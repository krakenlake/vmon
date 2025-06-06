#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/register.h"
#include "vmon/stack.h"


.global skip_whitespace
.global expect_comma
.global expect_open_paren
.global expect_close_paren
.global parse_insn_string
.global find_register_name_end
.global is_ascii
.global parse_binary
.global	parse_decimal
.global	parse_iorw
.global	parse_aqrl
.global	get_numeric

.text


# in: buffer ptr in a0
skip_whitespace:
	li		t0, ' '
	li		t1, '\t'
skip_whitespace_next:
	lb		t2, 0(a0)				# get byte from buffer
	beq		t2, t0, skip_whitespace_advance
	beq		t2, t1, skip_whitespace_advance
	j		skip_whitespace_done
skip_whitespace_advance:
	addi	a0, a0, 1				# advance buffer pointer
	j		skip_whitespace_next
skip_whitespace_done:
	ret
.size skip_whitespace, .-skip_whitespace


# expect a specific char and advance buffer ptr to next non-whitespace char after that char
# in: a0 = buffer ptr
# in: t0 = char to expect
# out: a0 = buffer ptr after comma (0 on error)
expect_char:
	li		t2, ' '
	li		t3, '\t'
	mv		t4, zero					# found flag
expect_char_loop:
	lb		t1, 0(a0)
	beq		t1, t0, expect_char_match	# found match
	beqz	t1, expect_char_check_flag	# string ended
	beq		t1, t2, expect_char_ws
	beq		t1, t3, expect_char_ws
	# anything else
expect_char_check_flag:
	bnez	t4, expect_char_ret
	li		a0, 0
	ret
expect_char_match:
	bnez	t4, expect_char_ret
	li		t4, 1						# set found flag
expect_char_ws:
	addi	a0, a0, 1
	j		expect_char_loop
expect_char_done:
	addi	a0, a0, 1
expect_char_ret:
	ret
.size expect_char, .-expect_char


# in: buffer ptr in a0
# out: a0 = buffer ptr after comma or a0 = 0 on error
expect_comma:
	li		t0, ','
	j 		expect_char
.size expect_comma, .-expect_comma


# in: buffer ptr in a0
# out: a0 = buffer ptr after comma or a0 = 0 on error
expect_open_paren:
	li		t0, '('
	j 		expect_char
.size expect_open_paren, .-expect_open_paren


# in: buffer ptr in a0
# out: a0 = buffer ptr after comma or a0 = 0 on error
expect_close_paren:
	li		t0, ')'
	j 		expect_char
.size expect_close_paren, .-expect_close_paren


# in: buffer ptr in a0
# out: a0 = ptr to end of parsed insn word
# out: a1 = ptr to second '.' if present (otherwise 0)
parse_insn_string:
	mv		a1, zero					# clear second dot ptr 
	li		t1, '.'						# pre-load relevant chars to compare
	li		t2, 'a'
	li		t3, 'z'
	li		t4, 2						# count dots here for RVA insns
parse_insn_string_loop:
	lb		t0, 0(a0)
	# accept '.'
	bne		t0, t1, parse_insn_string_no_dot
	# we have a dot
	addi	t4, t4, -1
	bnez	t4, parse_insn_string_valid_char
	# second dot is present
	mv		a1, a0
	j 		parse_insn_string_valid_char
parse_insn_string_no_dot:
	# accept a-z
	blt		t0, t2, parse_insn_string_done
	bgt		t0, t3, parse_insn_string_done
parse_insn_string_valid_char:
	addi	a0, a0, 1
	j		parse_insn_string_loop
parse_insn_string_done:
	ret
.size parse_insn_string, .-parse_insn_string


# in: buffer ptr in a0
# out: ptr to end of word in a0
find_register_name_end:
	lb		t0, 0(a0)
	# accept a-z and 0-9
	li		t1, '0'
	blt		t0, t1, find_register_name_end_done
	li		t1, 'z'
	bgt		t0, t1, find_register_name_end_done
	li		t1, '9'
	ble		t0, t1, find_register_name_end_valid_char
	li		t1, 'a'
	bge		t0, t1, find_register_name_end_valid_char
find_register_name_end_valid_char:
	addi	a0, a0, 1
	j		find_register_name_end
find_register_name_end_done:
	addi	a0, a0, -1
	ret
.size find_register_name_end, .-find_register_name_end


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
	li		t3, 0					# digit found flag (0=no)
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
	li		t3, 1					# set digit found flag
	slli	a1, a1, 4
	or		a1, a1, t1
	addi	a0, a0, 1
	j		parse_hex_next_byte
parse_hex_check:
	beqz	t3, parse_hex_return	# no digits -> err return
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
	li		t3, 0
parse_binary_next_bit:
	lb		t0, 0(a0)
	addi	t1, t0, -'0' # valid digits will be 0 or 1
	sltiu	t2, t1, 2	 # t2 = (t1 < 2U) ? 1 : 0 - check if t1 is 0 or 1
	bnez	t2, parse_binary_bit
	# check for valid terminators
	li		t1, ' '
	beq		t0, t1, parse_binary_return
	li		t1, ASCII_RETURN
	beq		t0, t1, parse_binary_return
	# character is not 0, 1, space, or return - return error
	ret
parse_binary_bit:
	li		t3, 1
	slli	a1, a1, 1
	or		a1, a1, t1
	addi	a0, a0, 1
	j		parse_binary_next_bit
parse_binary_return:
	beqz	t3, parse_binary_return_error
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
	li		a2, -1 # error code
	li		a1, 0  # result
	li		t3, 0  # digit found flag
	li		t6, 0  # negative flag
	# check for negative number
	lb		t0, 0(a0)
	li		t1, '-'
	bne		t0, t1, parse_decimal_plus
	li		t6, 1  # number is negative
	addi	a0, a0, 1
	j		parse_decimal_loop
parse_decimal_plus:
	li		t1, '+'
	bne		t0, t1, parse_decimal_loop # no leading +, assume positive
	addi	a0, a0, 1
parse_decimal_loop:
	lb		t0, 0(a0)
	addi	t1, t0, -'0'  # potential digit value
	sltiu	t2, t1, 10	  # is potential digit 0-9? (t2=1 if yes)
	beqz	t2, parse_decimal_check_flag # if not 0-9
	# have a valid decimal digit, multiply accumulator by 10
	# and add in the new digit value.
	li		t3, 1
	# a1 = a1 * 10
	slli	t4, a1, 3	   # t4 = a1 * 8
	slli	t5, a1, 1	   # t5 = a1 * 2
	add		a1, t5, t4	   # a1 = a1 * 10
	# a1 = a1 + digit_value
	add		a1, a1, t1
	addi	a0, a0, 1	   # ptr++
	j		parse_decimal_loop
parse_decimal_check_flag:
	beqz	t3, parse_decimal_final_return # If t3=0, error (a2 is -1)
	# apply sign, if necessary
	beqz	t6, parse_decimal_set_success
	sub		a1, x0, a1 # 2's complement negation
parse_decimal_set_success:
	li		a2, 0
parse_decimal_final_return:
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
	mv		t1, zero					# init value to be or'd in each step
	li		t2, 'i'
	li		t3, 'o'
	li		t4, 'r'
	li		t5, 'w'
parse_iorw_loop:
	or		a1, a1, t1					# first time this is empty
	li		t1, 1						# init for bit shifting
	lb		t0, 0(a0)					# get next input char
	addi	a0, a0, 1					# advance one char
	# accept 'i', 'o', 'r', 'w' and set bits in a1 accordingly
	beq		t0, t2, parse_iorw_add_i
	beq		t0, t3, parse_iorw_add_o
	beq		t0, t4, parse_iorw_add_r
	beq		t0, t5, parse_iorw_loop		# no further shift of t1 necessary
	addi	a0, a0, -1					# one step back if no match
	j		parse_iorw_done
parse_iorw_add_i:
	slli	t1, t1, 3
	j		parse_iorw_loop
parse_iorw_add_o:
	slli	t1, t1, 2
	or		a1, a1, t1
	j		parse_iorw_loop
parse_iorw_add_r:
	slli	t1, t1, 1
	j		parse_iorw_loop
parse_iorw_done:
	ret
.size parse_iorw, .-parse_iorw


# parse aqrl string for RVA insns
# in: buffer ptr in a0
# out: buffer ptr in a0
# out: aqrl bits in bits 25-26 of a1
# out: error code in a2 (OK=0)
parse_aqrl:
	mv		a1, zero						# clear assembly bits return value
	mv		a2, zero						# clear error
	li		t2, 'a'
	li		t3, 'q'
	li		t4, 'r'
	li		t5, 'l'
	li		t6, 1
parse_aqrl_loop:
	lb		t0, 0(a0)						# get next input char
	addi	a0, a0, 1						# advance one char
	# accept "aq" or "rl" and set bits in a1 accordingly
	beq		t0, t2, parse_aqrl_need_q
	beq		t0, t4, parse_aqrl_need_r
	# when we encounter anything other than 'a' or 'r' we are done
	j		parse_aqrl_done
parse_aqrl_need_q:
	lb		t0, 0(a0)						# get char after current
	beq		t0, t3, parse_aqrl_add_aq_bit	# we have aq
	j		parse_aqrl_done
parse_aqrl_add_aq_bit:
	slli	t0, t6, 1
	or		a1, a1, t0
	addi	a0, a0, 1
	j		parse_aqrl_loop
parse_aqrl_need_r:
	lb		t0, 0(a0)						# get char after current
	beq		t0, t5, parse_aqrl_add_rl_bit	# we have rl
	j		parse_aqrl_done
parse_aqrl_add_rl_bit:
	or		a1, a1, t6
	addi	a0, a0, 1
	j		parse_aqrl_loop
parse_aqrl_done:
	slli	a1, a1, 25
	ret
.size parse_aqrl, .-parse_aqrl

