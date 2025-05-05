#include "vmon/config.h"
#include "vmon/ASCII.h"


.global skip_whitespace
.global consume_comma
.global get_hex_addr
.global find_insn_name_end
.global find_register_name_end
.global is_ascii
.global parse_binary

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
get_hex_addr_next_byte:
	lb		t0, 0(a0)				# get byte from buffer
	li		t1, ' '					# end parsing at next space or return
	beq		t0, t1, get_hex_addr_return		 
	li		t1, ASCII_RETURN
	beq		t0, t1, get_hex_addr_return		 
	li		t1, '0'					
	blt		t0, t1, get_hex_addr_return_error
	li		t1, '9'
	bgt		t0, t1, get_hex_addr_check_alpha	
	# got a digit
	li		a2, 0					# clear error code
	sll		a1, a1, 4	
	addi	t0, t0, -48
	or		a1, a1, t0
	addi	a0, a0 ,1				# advance buffer ptr
	j		get_hex_addr_next_byte
get_hex_addr_check_alpha:
	li		t1, 'a'
	blt		t0, t1, get_hex_addr_return_error
	li		t1, 'f'
	bgt		t0, t1, get_hex_addr_return_error	 
	# got a valid alpha
	li		a2, 0					# clear error code
	sll		a1, a1, 4	
	addi	t0, t0, -87
	or		a1, a1, t0
	addi	a0, a0 ,1				# advance buffer ptr
	j		get_hex_addr_next_byte
get_hex_addr_return_error:
	li		a2, -1
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
