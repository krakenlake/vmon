#include "config.h"
#include "vmon/register.h"
#include "vmon/trap.h"
#include "vmon/stack.h"


.global trap_handler


.text


# trap handler needs to be aligned manually 
# as that is not automatically guaranteed with RVC enabled
.align 4


#if defined(TARGET_HAS_Zicsr)

trap_handler:
	bnez	sp, stack_exists

	# set up stack
	la		sp, _estack					# linker will provide _estack

stack_exists:
	# push stack
	addi	sp, sp, -(XLEN_BYTES*5)
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp)
	SAVE_X	t0, (XLEN_BYTES*2)(sp)
	SAVE_X	t1, (XLEN_BYTES*3)(sp)
	SAVE_X	s0, (XLEN_BYTES*4)(sp)

	# clear irq
	li		t0, 0b10000000
	csrc	MODE_PREFIX(ip), t0

	# irq or exception? check leftmost bit of xcause
	csrr	a0, MODE_PREFIX(cause)
	li		t0, 0b1
	slli	t0, t0, XLEN-1
	and		a0, a0, t0
	bnez	a0, trap_handler_irq

	# we have an exception
	# check if exception was caused by ebreak
	csrr	t0, MODE_PREFIX(cause)
	li		t1, 3						# breakpoint exception?
	bne		t0, t1, handle_exception
	
handle_ebreak:
	# pop registers
	LOAD_X	ra, 0(sp)
	LOAD_X	a0, (XLEN_BYTES*1)(sp)
	LOAD_X	t0, (XLEN_BYTES*2)(sp)
	LOAD_X	t1, (XLEN_BYTES*3)(sp)
	LOAD_X	s0, (XLEN_BYTES*4)(sp)
	addi	sp, sp, (XLEN_BYTES*5)
	# start VMON command line
	j		breakpoint_entry

handle_exception:
	# in case of an exception:
	# 1. print the exception
	# 2. reset the program to a defined state
	# 3. abort the current command and wait for the next command
	la		a0, string_exception_msg
	jal		print_string

	# print xepc
	la		a0, string_epc_msg
	jal		print_string
	csrr	a0, MODE_PREFIX(epc)
	jal		print_hex

	# print xtval
	la		a0, string_tval_msg
	jal		print_string
	csrr	a0, MODE_PREFIX(tval)
	jal		print_hex

	# print xcause
	la		a0, string_cause_msg
	jal		print_string
	csrr	a0, MODE_PREFIX(cause)
	mv		s0, a0								# save for later
	jal		print_hex
	# print CAUSE verbose

#ifdef CAUSE_VERBOSE
	jal		print_space
	li		a0, '('
	jal		print_char
	# each entry in CAUSE string table is 4 bytes
	# TODO: use a loop to go to the n-th entry in the table, would save "cause_verbose_table" and require less space
	slli	a0, s0, 2							# set a0 = xcause * 4
	la		s0, cause_verbose_table				# start of CAUSE string table
	add		a0, a0, s0
	LWU		a0, 0(a0)
	jal		print_string
	li		a0, ')'
	jal		print_char
#endif

	# set return address for leaving trap handler
	la		a0, main_prompt
	csrw	MODE_PREFIX(epc), a0
	j		exit_trap_handler


# trap handler needs to be aligned manually 
# as that is not automatically guaranteed with RVC enabled
.align 4
trap_handler_irq:
/*
	li		a0, '#'
	jal		print_char
	# reset timer
	rdtime	t0
	li		t1, TIMER_INTERVAL
	add		t1, t0, t1
	la		t0, MTIMECMP
	SAVE_X	t1, 0(t0)
*/
	j		exit_trap_handler


exit_trap_handler:
	# pop stack
	LOAD_X	ra, 0(sp)
	LOAD_X	a0, (XLEN_BYTES*1)(sp)
	LOAD_X	t0, (XLEN_BYTES*2)(sp)
	LOAD_X	t1, (XLEN_BYTES*3)(sp)
	LOAD_X	s0, (XLEN_BYTES*4)(sp)
	addi	sp, sp, (XLEN_BYTES*5)
	mret
.size trap_handler, .-trap_handler


.section .rodata


string_exception_msg:		.string "\nexception:"
string_epc_msg:				.string "\n\tepc\t= ";
string_tval_msg:			.string "\n\ttval\t= ";
string_cause_msg:			.string "\n\tcause\t= ";

#ifdef CAUSE_VERBOSE
	string_CAUSE_MISALIGNED_FETCH:		.string "MISALIGNED_FETCH";
	string_CAUSE_FAULT_FETCH:			.string "FAULT_FETCH";
	string_CAUSE_ILLEGAL_INSTRUCTION:	.string "ILLEGAL_INSTRUCTION";
	string_CAUSE_BREAKPOINT:			.string "BREAKPOINT";
	string_CAUSE_MISALIGNED_LOAD:		.string "MISALIGNED_LOAD";
	string_CAUSE_FAULT_LOAD:			.string "FAULT_LOAD";
	string_CAUSE_MISALIGNED_STORE:		.string "MISALIGNED_STORE";
	string_CAUSE_FAULT_STORE:			.string "FAULT_STORE";
	string_CAUSE_USER_ECALL:			.string "USER_ECALL";
	string_CAUSE_SUPERVISOR_ECALL:		.string "SUPERVISOR_ECALL";
	string_CAUSE_HYPERVISOR_ECALL:		.string "HYPERVISOR_ECALL";
	string_CAUSE_MACHINE_ECALL:			.string "MACHINE_ECALL";

.align 4
cause_verbose_table:
	.word string_CAUSE_MISALIGNED_FETCH
	.word string_CAUSE_FAULT_FETCH
	.word string_CAUSE_ILLEGAL_INSTRUCTION
	.word string_CAUSE_BREAKPOINT
	.word string_CAUSE_MISALIGNED_LOAD
	.word string_CAUSE_FAULT_LOAD
	.word string_CAUSE_MISALIGNED_STORE
	.word string_CAUSE_FAULT_STORE
	.word string_CAUSE_USER_ECALL
	.word string_CAUSE_SUPERVISOR_ECALL
	.word string_CAUSE_HYPERVISOR_ECALL
	.word string_CAUSE_MACHINE_ECALL
#endif /* CAUSE_VERBOSE */


#endif /* defined(TARGET_HAS_Zicsr) */
