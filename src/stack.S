#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/stack.h"
#include "vmon/register.h"


.global push_ra
.global push_s0_ra
.global push_s1_s0_ra
.global push_s2_s1_s0_ra
# push_s3_s2_s1_s0_ra left out on purpose, just use push/pop_s4_s3_s1_s0_ra instead
.global push_s4_s3_s2_s1_s0_ra

.global pop_ra_ret
.global pop_s0_ra_ret
.global pop_s1_s0_ra_ret
.global pop_s2_s1_s0_ra_ret
# left out intentionally, see above
.global pop_s4_s3_s2_s1_s0_ra_ret
.global pop_s5_s4_s3_s2_s1_s0_ra_ret
.global pop_s6_s5_s4_s3_s2_s1_s0_ra_ret
.global pop_s7_s6_s5_s4_s3_s2_s1_s0_ra_ret

.global patch_int_register
.global patch_float_register

.global print_int_registers
.global print_float_registers

.text


# for function prologue optimisation (shorter code in total)

push_ra:
	addi	sp, sp, -(XLEN_BYTES*1)	
	SAVE_X	ra, 0(sp)
	jr		t6

push_s0_ra:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	jr		t6

push_s1_s0_ra:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	jr		t6

push_s2_s1_s0_ra:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	s2, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s0, (XLEN_BYTES*2)(sp)
	SAVE_X	ra, (XLEN_BYTES*3)(sp)
	jr		t6

# push_s3_s2_s1_s0_ra left out on purpose, just use push/pop_s4_s3_s1_s0_ra instead

push_s4_s3_s2_s1_s0_ra:
	addi	sp, sp, -(XLEN_BYTES*6)
	SAVE_X	s4, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	SAVE_X	s1, (XLEN_BYTES*3)(sp)
	SAVE_X	s0, (XLEN_BYTES*4)(sp)
	SAVE_X	ra, (XLEN_BYTES*5)(sp)
	jr		t6


# for function epilogue optimisation (shorter code in total)

pop_s7_s6_s5_s4_s3_s2_s1_s0_ra_ret:
	LOAD_X	s7, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_s6_s5_s4_s3_s2_s1_s0_ra_ret:
	LOAD_X	s6, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_s5_s4_s3_s2_s1_s0_ra_ret:
	LOAD_X	s5, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_s4_s3_s2_s1_s0_ra_ret:
	LOAD_X	s4, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_s3_s2_s1_s0_ra_ret:
	LOAD_X	s3, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_s2_s1_s0_ra_ret:
	LOAD_X	s2, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_s1_s0_ra_ret:
	LOAD_X	s1, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_s0_ra_ret:
	LOAD_X	s0, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
pop_ra_ret:
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	ret


#ifdef WITH_CMD_S

# in: a0 = index of register
# in: a1 = new value to write
patch_int_register:
	li		t1, STK_FRAME_SIZE_FLOAT
	add		t0, sp, t1
patch_int_register_loop:
	addi	t0, t0, (XLEN_BYTES*1)
	addi 	a0, a0, -1
	bnez	a0, patch_int_register_loop
	SAVE_X	a1, 0(t0)
	ret

# in: a0 = index of register
# in: a1 = new representation value to write
#ifdef TARGET_HAS_RVF
patch_float_register:
	# put int hex value on stack
	addi	sp, sp, -(FLEN_BYTES)
	SAVE_X	a1, 0(sp)
	# read it into float register back
	LOAD_F	f0, 0(sp)
	addi 	sp, sp, (FLEN_BYTES)
	mv		t0, sp
patch_float_register_loop:
	beqz	a0, patch_float_register_do
	addi	t0, t0, (FLEN_BYTES*1)
	addi 	a0, a0, -1
	j		patch_float_register_loop
patch_float_register_do:
	SAVE_F	f0, 0(t0)
	ret
#endif /* TARGET_HAS_RVF */


#endif /* WITH_CMD_S */


#ifdef WITH_CMD_R

print_int_registers:
	PUSH_RA
	la		a0, get_int_register_name_by_index
	li		a1, 1
	li		a2, 31
	#ifdef M_MODE
		# set a3 to the address of ra in the current stack frame
		# (XLEN_BYTES are also added to compensate for the pushing ra on entry here)
		#ifdef TARGET_HAS_RVF
			addi		a3, sp, XLEN_BYTES + STK_FRAME_SIZE_FLOAT + STK_OFF_RA
		#else
			addi		a3, sp, XLEN_BYTES + STK_OFF_RA
		#endif
	#else
		# todo: ???
	#endif
	li		a4, XLEN_BYTES
	jal		print_saved_registers
	POP_RA_RET
.size print_int_registers, .-print_int_registers


#ifdef TARGET_HAS_RVF
	print_float_registers:
		PUSH_RA
		la		a0, get_float_register_name_by_index
		li		a1, 0
		li		a2, 31 
		addi	a3, sp,  XLEN_BYTES						# compensate for ra pushed on entry
		li		a4, FLEN_BYTES
		jal		print_saved_registers
		POP_RA_RET
	.size print_float_registers, .-print_float_registers
#endif /* DISASS_RVF */


# dump registers saved on stack
# in: a0 = register name lookup func ptr
# in: a1 = first register index
# in: a2 = last register index
# in: a3 = stack frame base addr
# in: a4 = size of one register in bytes
print_saved_registers:
	addi	sp, sp, -(XLEN_BYTES*9)
	SAVE_X  s7, 0(sp)
	SAVE_X  s6, (XLEN_BYTES*1)(sp)
	SAVE_X  s5, (XLEN_BYTES*2)(sp)
	SAVE_X	s4, (XLEN_BYTES*3)(sp)
	SAVE_X	s3, (XLEN_BYTES*4)(sp)
	SAVE_X	s2, (XLEN_BYTES*5)(sp)
	SAVE_X	s1, (XLEN_BYTES*6)(sp)
	SAVE_X	s0, (XLEN_BYTES*7)(sp)
	SAVE_X	ra, (XLEN_BYTES*8)(sp)
	mv		s5, a0						# register name lookup func ptr
	mv		s1, a1						# first register index
	mv		s2, a2						# last register index
	mv		s0, a3						# stack frame base addr
	mv		s4, a4						# register size
print_saved_registers_next:
	li		s3, 3						# print newline after every 3 registers
	jal		print_newline
print_saved_registers_skip_newline:
	mv		a0, s1						# index of register
	jalr	s5
	mv		s7, a0						# name string ptr
	# determine length of found name
	mv		t0, s7						# string ptr
	li		t1, 0						# len counter
print_saved_registers_len_loop:
	lb		t3, 0(t0)
	beqz	t3, print_saved_registers_len_done
	addi	t0, t0, 1
	addi	t1, t1, 1
	j		print_saved_registers_len_loop
print_saved_registers_len_done:
	# length now in t1, print spaces if register name is shorter than 6
	li		t2, 6						
	sub 	s6, t2, t1
print_saved_registers_space_loop:
	beqz	s6, print_saved_registers_skip_space
	jal		print_space
	addi	s6, s6, -1
	j 		print_saved_registers_space_loop
print_saved_registers_skip_space:
	mv		a0, s7
	jal		print_string				# register name
	li		a0, '='
	jal		print_char
	LOAD_X	a0, 0(s0)					# saved value
	jal		print_hex_addr
	# check if all registers done
	li		t0, 31						# last valid index in any case
	bge		s1, t0, print_saved_registers_done
	# stop also if register specified in s2 reached
	beq		s1, s2, print_saved_registers_done
	add		s0, s0, s4					# next register
	addi	s1, s1, 1					# next register name
	addi	s3, s3, -1					# count number of printed registers
	beqz	s3, print_saved_registers_next
	j		print_saved_registers_skip_newline
print_saved_registers_done:
	jal		print_newline
	j		pop_s7_s6_s5_s4_s3_s2_s1_s0_ra_ret
.size print_saved_registers, .-print_saved_registers

#endif /* WITH_CMD_R */

.bss

.align 8

.comm stack, STACK_SIZE
.size stack, STACK_SIZE
