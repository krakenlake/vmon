#include "config.h"
#include "vmon/register.h"
#include "vmon/trap.h"
#include "vmon/stack.h"


#if defined(M_MODE) && defined(TARGET_HAS_Zicsr)


.global trap_handler


.text


# trap handler needs to be aligned manually 
# as that is not automatically guaranteed with RVC enabled
.align 4
trap_handler:
	bnez	sp, stack_exists

	# set up stack
	la		sp, stack + STACK_SIZE

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
	csrc	mip, t0

	# irq or exception? check leftmost bit of mcause
	csrr	a0, mcause
	li		t0, 0b1
	slli	t0, t0, XLEN-1
	and		a0, a0, t0
	bnez	a0, trap_handler_irq

	# we have an exception
	# check if exception was caused by ebreak
	csrr	t0, mcause
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

	# print mepc
	la		a0, string_mepc_msg
	jal		print_string
	csrr	a0, mepc
	jal		print_hex

	# print mtval
	la		a0, string_mtval_msg
	jal		print_string
	csrr	a0, mtval
	jal		print_hex

	# print mcause
	la		a0, string_mcause_msg
	jal		print_string
	csrr	a0, mcause
	mv		s0, a0								# save for later
	jal		print_hex
	# print MCAUSE verbose

#ifdef MCAUSE_VERBOSE
	jal		print_space
	li		a0, '('
	jal		print_char
	# each entry in MCAUSE string table is 4 bytes
	slli	a0, s0, 2							# set a0 = mcause * 4
	la		s0, mcause_verbose_table			# start of MCAUSE string table
	add		a0, a0, s0
	LWU		a0, 0(a0)
	jal		print_string
	li		a0, ')'
	jal		print_char
#endif

	# set return address for leaving trap handler
	la		a0, main_prompt
	csrw	mepc, a0
	j		exit_trap_handler


# trap handler needs to be aligned manually 
# as that is not automatically guaranteed with RVC enabled
.align 4
trap_handler_irq:
	li		a0, '#'
	jal		print_char
	# reset timer
	rdtime	t0
	li		t1, TIMER_INTERVAL
	add		t1, t0, t1
	la		t0, MTIMECMP
	SAVE_X	t1, 0(t0)
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



string_exception_msg:		.string "\nexception:"
string_mepc_msg:			.string "\n\tmepc\t= ";
string_mtval_msg:			.string "\n\tmtval\t= ";
string_mcause_msg:			.string "\n\tmcause\t= ";

#ifdef MCAUSE_VERBOSE
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
mcause_verbose_table:
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
#endif /* MCAUSE_VERBOSE */


#endif /* defined(M_MODE) && defined(TARGET_HAS_Zicsr) */
