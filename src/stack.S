#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/stack.h"
#include "vmon/register.h"


# PUSH
.global push_ra
.global push_s0_ra
.global push_s1_s0_ra
.global push_tp_s1_s0_ra						# use tp like another s register 

# POP
.global pop_ra_ret
.global pop_s0_ra_ret
.global pop_s1_s0_ra_ret
.global pop_tp_s1_s0_ra_ret						# use tp like another s register

.global print_pc
.global print_int_registers
.global print_float_registers
.global patch_pc
.global patch_int_register
.global patch_float_register


.text


# for function prologue optimisation (shorter code in total)
push_ra:
	addi	sp, sp, -(XLEN_BYTES*1)	
	SAVE_X	ra, 0(sp)
	jr		gp

push_s0_ra:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	jr		gp

push_s1_s0_ra:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	jr		gp

push_tp_s1_s0_ra:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	tp, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s0, (XLEN_BYTES*2)(sp)
	SAVE_X	ra, (XLEN_BYTES*3)(sp)
	jr		gp


# for function epilogue optimisation (shorter code in total)
pop_tp_s1_s0_ra_ret:
	LOAD_X	tp, 0(sp)
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


#if defined (WITH_CMD_X) || defined (WITH_CMD_G)

	print_pc:
		PUSH_RA
		#ifdef TARGET_HAS_RVF
			LOAD_X	a0, (XLEN_BYTES + STK_FRAME_SIZE_FLOAT + STK_OFF_PC)(sp)
		#else
			LOAD_X	a0, (XLEN_BYTES + STK_OFF_PC)(sp)
		#endif
		jal		print_hex
		POP_RA_RET

#endif /* defined (WITH_CMD_X) || defined (WITH_CMD_G) */


#ifdef WITH_CMD_G

	# patch pc that was saved on the stack on entry, exit routine will load it later
	# in: a0 = new value
	patch_pc:
		#ifdef TARGET_HAS_RVF
			SAVE_X	a0, (STK_FRAME_SIZE_FLOAT + STK_OFF_PC)(sp)
		#else
			SAVE_X	a0, (STK_OFF_PC)(sp)
		#endif
		ret

#endif /* WITH_CMD_G */


#ifdef WITH_CMD_S

	# in: a0 = index of register
	# in: a1 = new value to write
	patch_int_register:
	#ifdef TARGET_HAS_RVF
		li		t1, STK_FRAME_SIZE_FLOAT
		add		t0, sp, t1
	#else
		mv		t0, sp
	#endif
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
		
		#ifndef TARGET_RVE
			li		a2, 31
		#else
			li		a2, 15
		#endif
		
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
	print_saved_registers:
		PUSH_TP_S1_S0_RA
		addi	sp, sp, -(XLEN_BYTES*3)		# 3 extra local vars
		SAVE_X 	a0, 0(sp)					# register name lookup func ptr
		SAVE_X 	zero, (XLEN_BYTES*1)(sp)	# counting regs per line
		SAVE_X	zero, (XLEN_BYTES*2)(sp)	# name string ptr

		mv		s1, a1						# first register index
		mv		tp, a2						# last register index
		mv		s0, a3						# stack frame base addr
	print_saved_registers_next:
		li		t0, 3
		SAVE_X	t0, (XLEN_BYTES*1)(sp)
		jal		print_newline
	print_saved_registers_skip_newline:
		mv		a0, s1						# index of register
		LOAD_X	t0, 0(sp)					# register name lookup func ptr
		jalr	t0
		SAVE_X	a0, (XLEN_BYTES*2)(sp)
		# determine length of found name
		li		t1, 0						# len counter
	print_saved_registers_len_loop:
		lb		t0, 0(a0)
		beqz	t0, print_saved_registers_len_done
		addi	a0, a0, 1
		addi	t1, t1, 1
		j		print_saved_registers_len_loop
	print_saved_registers_len_done:
		# length now in t1, print spaces if register name is shorter than 6
		li		t2, 6						
		sub 	a5, t2, t1
	print_saved_registers_space_loop:
		beqz	a5, print_saved_registers_skip_space
		jal		print_space
		addi	a5, a5, -1
		j 		print_saved_registers_space_loop
	print_saved_registers_skip_space:
		LOAD_X	a0, (XLEN_BYTES*2)(sp)
		jal		print_string				# register name
		li		a0, '='
		jal		print_char
		LOAD_X	a0, 0(s0)					# saved value
		jal		print_hex_addr
		# check if all registers done
		li		t0, 31						# last valid index in any case
		bge		s1, t0, print_saved_registers_done
		# stop also if register specified in tp reached
		beq		s1, tp, print_saved_registers_done
		addi	s0, s0, XLEN_BYTES			# next register
		addi	s1, s1, 1					# next register name
		LOAD_X	t0, (XLEN_BYTES*1)(sp)
		addi	t0, t0, -1					# count number of printed registers
		SAVE_X	t0, (XLEN_BYTES*1)(sp)
		beqz	t0, print_saved_registers_next
		j		print_saved_registers_skip_newline
	print_saved_registers_done:
		jal		print_newline
		addi	sp, sp, (XLEN_BYTES*3)		# discard 5 extra local vars
		POP_TP_S1_S0_RA_RET
	.size print_saved_registers, .-print_saved_registers

#endif /* WITH_CMD_R */

.bss

.align 8

.comm stack, STACK_SIZE
.size stack, STACK_SIZE
