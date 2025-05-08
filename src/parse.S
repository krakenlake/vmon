#include "vmon/config.h"
#include "vmon/ASCII.h"


.global skip_whitespace
.global consume_comma
.global get_hex_addr
.global find_insn_name_end
.global find_register_name_end
.global is_ascii
.global parse_binary
.global	parse_decimal

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


# in: buffer ptr in a0
# out: a0 = buffer ptr after comma or a0 = 0 on error
consume_comma:
	li		t0, ','
	lb		t1, 0(a0)
	beq		t1, t0, consume_comma_done
	li		a0, -1
consume_comma_done:
	addi	a0, a0, 1
	ret


# in: buffer ptr in a0
# out: ptr to end of word in a0
find_insn_name_end:
	lb		t0, 0(a0)
	# accept '.'
	li		t1, '.'
	beq		t0, t1, find_insn_name_end_valid_char
	# accept a-z
	li		t1, 'a'
	blt		t0, t1, find_insn_name_end_done
	li		t1, 'z'
	bgt		t0, t1, find_insn_name_end_done
find_insn_name_end_valid_char:
	addi	a0, a0, 1
	j		find_insn_name_end
find_insn_name_end_done:
	ret
.size find_insn_name_end, .-find_insn_name_end


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
.size find_insn_name_end, .-find_insn_name_end

# in: buffer ptr in a0
# out: buffer ptr in a0
# out: parsed address value in a1
# out: error code in a2 (OK=0)
get_hex_addr:
	li		a1, 0					# reset address value
	li		a2, -1					# set error code
	li		t3, 0					# digit found flag (0=no)
get_hex_addr_next_byte:
	lb		t0, 0(a0)				# get byte from buffer
	li		t4, ' '					# end parsing at next space or return
	beq		t0, t4, get_hex_addr_check
	li		t4, ASCII_RETURN
	beq		t0, t4, get_hex_addr_check

	addi	t1, t0, -'0'
	sltiu	t2, t1, 10				# is it 0-9 ?
	bnez	t2, get_hex_addr_add_nibble

	addi	t1, t0, -'a'
	sltiu	t2, t1, 6				# 0-5 (maps to 'a' - 'f')
	beqz	t2, get_hex_addr_return # found invalid char
	add		t1, t1, 10				# t1 is now 10-15

get_hex_addr_add_nibble:
	li		t3, 1
	slli	a1, a1, 4
	or		a1, a1, t1
	addi	a0, a0, 1
	j		get_hex_addr_next_byte

get_hex_addr_check:
	beqz	t3, get_hex_addr_return # no digits -> err return
	li		a2, 0					# clear error code
get_hex_addr_return:
	ret

.size get_hex_addr, .-get_hex_addr

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
	beqz	t2, parse_decimal_check_term # if not 0-9

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

parse_decimal_check_term:
	# Check terminators (' ' or ASCII_RETURN)
	li		t1, ' '
	beq		t0, t1, parse_decimal_check_flag
	li		t1, ASCII_RETURN
	beq		t0, t1, parse_decimal_check_flag
	# Invalid char: Jump to return (a2 is already -1)
	j		parse_decimal_final_return

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
