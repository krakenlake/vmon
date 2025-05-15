#include "vmon/config.h"
#include "vmon/ASCII.h"


.global print_saved_registers


.text


#ifdef WITH_CMD_R
# dump registers saved on stack
print_saved_registers:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X  ra, 0(sp)
	SAVE_X  s0, (XLEN_BYTES*1)(sp)
	SAVE_X  s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s2, (XLEN_BYTES*3)(sp)
	#ifdef M_MODE
		la 		s0, stack + STACK_SIZE -(XLEN_BYTES*31)
	#else
		# ???
	#endif
	li		s1, 1						# skip register zero
print_saved_registers_next:
	li		s2, 3
	jal		print_newline
print_saved_registers_skip_newline:
	# print space if not s10 or s11 to align everything nicely
	li		t0, 26						# index of s10
	li		t1, 27						# index of s11
	beq		s1, t0, print_saved_registers_skip_space
	beq		s1, t1, print_saved_registers_skip_space
	li		a0, ' '
	jal		print_char
print_saved_registers_skip_space:
	mv		a0, s1						# index of register
	jal		get_int_register_name_by_index
	jal		print_string				# register name
	li		a0, '='
	jal		print_char
	LOAD_X	a0, 0(s0)					# saved value
	li		a1, XLEN_BYTES
	li		a2, 1
	jal		print_hex_fixed_width
	li		a0, '\t'
	jal		print_char
	addi	s0, s0, XLEN_BYTES			# next register
	addi	s1, s1, 1					# next register name
	# check if all int registers done
	li		t0, 32						
	bge		s1, t0, print_saved_registers_done
	addi	s2, s2, -1
	beqz	s2, print_saved_registers_next
	j		print_saved_registers_skip_newline
print_saved_registers_done:
	LOAD_X  ra, 0(sp)
	LOAD_X  s0, (XLEN_BYTES*1)(sp)
	LOAD_X  s1, (XLEN_BYTES*2)(sp)
	LOAD_X  s2, (XLEN_BYTES*3)(sp)
	addi	sp, sp, (XLEN_BYTES*4)
	ret
#endif /* WITH_CMD_R */

