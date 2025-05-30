#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/breakpoints.h"
#include "vmon/error.h"


.global break_reset
.global break_list
.global break_set
.global break_clear
.global break_activate
.global break_deactivate


.text


#ifdef WITH_CMD_B

# in: a0 = addr
# out: a0 = addr
# out: a1 = 0 if OK, nonzero if not OK
is_valid_insn_addr:
	li		a1, 0
	#ifdef DISASS_RVC
		andi	a1, a0, 0b1
	#else
		andi	a1, a0, 0b11
	#endif
break_check_addr_done:
	ret


break_reset:
	la		t0, bp_table
	li		t2, 0
break_reset_loop:
	# clear table entry
	SAVE_X	zero, 0(t0)
	SWU		zero, XLEN_BYTES(t0)
	# next
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	li		t3, BP_NUM
	bne		t2, t3, break_reset_loop
break_init_all_done:
	ret
.size break_reset, .-break_reset


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
# out: a0 = address if breakpoint set, else error code
# errors: a0 = -1 if no free slots, -2 if addr invalid
break_set:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	jal		is_valid_insn_addr
	beqz	a1, break_set_valid_addr
	li		a0, ERR_INSN_ADDR
	j		break_set_error
break_set_valid_addr:
	la		t0, bp_table
	li		t2, 0
	li		t3, BP_NUM
	# first check if this breakpoint is already in the list
break_set_check_loop:
	LOAD_X	t1, 0(t0)
	beq		t1, a0, break_set_done
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	bne		t2, t3, break_set_check_loop
	# breakpoint does not yet exist, so store it
	la		t0, bp_table
	li		t2, 0
	# find free slot in table to store the breakpoint
break_set_find_loop:
	LOAD_X	t1, 0(t0)
	beqz	t1, break_set_free_slot
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	bne		t2, t3, break_set_find_loop
	li		a0, ERR_BREAK_FULL
break_set_error:
	jal		print_error
	j		break_set_done
break_set_free_slot:
	# store breakpoint data
	SAVE_X	a0, 0(t0)					# save address in table
break_set_done:
	j		pop_ra_ret
.size break_set, .-break_set

# in: a0 = address
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

# activate all breakpoints by inserting ebreaks
break_activate:
	la		t0, bp_table
	li		t2, 0
	li		t3, BP_NUM
break_activate_loop:
	LOAD_X	a0, 0(t0)					# get bp address from table
	beqz	a0, break_activate_skip		# skip this slot if empty
	LWU		t1, 0(a0)					# load insn at breakpoint
	SWU		t1, XLEN_BYTES(t0)			# save insn in table
	# overwrite insn with ebreak
	# todo: check if insn at addr is RVC and use c.ebreak if so
	li		t1, 0x100073				# ebreak
	SWU		t1, 0(a0)
break_activate_skip:
	# next
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	bne		t2, t3, break_activate_loop
break_activate_done:
	ret
.size break_activate, .-break_activate


# deactivate all breakpoints by putting back original insns
break_deactivate:
	la		t0, bp_table
	li		t2, 0
	li		t3, BP_NUM
break_deactivate_loop:
	# restore original insns at all breakpoints
	# todo: check if insn at addr was RVC and write only 2 bytes if so
	LOAD_X	a0, 0(t0)
	beqz	a0, break_deactivate_skip	# skip this slot if empty
	LWU		t1, XLEN_BYTES(t0)			# original insn from table
	SWU		t1, 0(a0)					# to original address
break_deactivate_skip:
	# next
	addi	t0, t0, BP_ENTRY_SIZE
	addi	t2, t2, 1
	bne		t2, t3, break_deactivate_loop
break_deactivate_done:
	ret
.size break_deactivate, .-break_deactivate


.bss

.align 8

# runtime breakpoint table
# format: address, saved original content
.comm bp_table, BP_TABLE_SIZE
.size bp_table, BP_TABLE_SIZE

#endif /* WITH_CMD_B */
