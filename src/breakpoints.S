#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/breakpoints.h"

.global break_init
.global break_list
.global break_set
.global break_clear
.global break_restore_all


.text


#ifdef WITH_CMD_B

break_init:
	la		t0, bp_table
	li		t2, 0
break_init_all_loop:
	# clear table entry
	SAVE_X	zero, 0(t0)
	SWU		zero, XLEN_BYTES(t0)
	# next
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	li		t3, BP_NUM
	bne		t2, t3, break_restore_all_loop
break_init_all_done:
	ret
.size break_init, .-break_init


break_list:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	la		s0, bp_table
	mv		s1, zero
break_list_loop:
	LOAD_X	a0, 0(s0)
	beqz	a0, break_list_skip_empty
	li		a1, XLEN_BYTES
	li		a2, 1
	jal		print_hex_fixed_width
	#ifdef DEBUG
		jal		print_space
		LOAD_X	a0, XLEN_BYTES(s0)
		li		a1, 4						# insn size in bytes
		li		a2, 1
		jal		print_hex_fixed_width
	#endif
	jal		print_newline
break_list_skip_empty:
	addi	s0, s0, BP_ENTRY_SIZE
	addi	s1, s1, 1
	li		t0, BP_NUM
	bne		s1, t0, break_list_loop
break_list_done:
	j		pop_s1_s0_ra_ret
.size break_list, .-break_list


# in: a0 = address
break_set:
	la		t0, bp_table
	li		t2, 0
	# first check if this breakpoint is already in the list
break_set_check_loop:
	LOAD_X	t1, 0(t0)
	beq		t1, a0, break_set_done
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	li		t3, BP_NUM
	bne		t2, t3, break_set_check_loop
	# breakpoint does not yet exist, so store it
	la		t0, bp_table
	# find free slot in table to store the breakpoint
break_set_find_loop:
	LOAD_X	t1, 0(t0)
	beqz	t1, break_set_free_slot
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	li		t3, BP_NUM
	bne		t2, t3, break_set_find_loop
	j		break_set_done				# no free slot in table, stop
break_set_free_slot:
	# store breakpoint data
	SAVE_X	a0, 0(t0)					# save address in table
	LWU		t1, 0(a0)					# load insn at breakpoint
	SWU		t1, XLEN_BYTES(t0)			# save insn in table
	# modify code
	li		t2, 0x100073				# ebreak
	SWU		t2, 0(a0)
break_set_done:
	ret
.size break_set, .-break_set


break_clear:
	la		t0, bp_table
	li		t2, 0
break_clear_find_loop:
	LOAD_X	t1, 0(t0)
	beq		t1, a0, break_clear_do		# match?
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	li		t3, BP_NUM
	bne		t2, t3, break_clear_find_loop
	j		break_clear_done	
break_clear_do:
	# restore original insn
	LOAD_X	a0, 0(t0)					# get address
	LWU		t1, XLEN_BYTES(t0)			# get insn
	SWU		t1, 0(a0)					# reset original insn
	# clear table entry
	SAVE_X	zero, 0(t0)
	SWU		zero, XLEN_BYTES(t0)
break_clear_done:
	ret
.size break_clear, .-break_clear


break_restore_all:
	la		t0, bp_table
	li		t2, 0
break_restore_all_loop:
	# restore original insn
	LOAD_X	a0, 0(t0)
	beqz	a0, break_restore_all_skip	# skip this slot if empty
	LWU		t1, XLEN_BYTES(t0)
	SWU		t1, 0(a0)
	# clear table entry
	SAVE_X	zero, 0(t0)
	SWU		zero, XLEN_BYTES(t0)
break_restore_all_skip:
	# next
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	li		t3, BP_NUM
	bne		t2, t3, break_restore_all_loop
break_restore_all_done:
	ret
.size break_clear, .-break_clear


.bss

.align 8

# runtime breakpoint table
# format: address, saved original content
.comm bp_table, BP_TABLE_SIZE
.size bp_table, BP_TABLE_SIZE

#endif /* WITH_CMD_B */
