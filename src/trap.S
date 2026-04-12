#include "config.h"
#include "vmon/register.h"
#include "vmon/trap.h"
#include "vmon/stack.h"


.global trap_handler
.global exit_trap_handler



.text


# trap handler needs to be aligned manually 
# as that is not automatically guaranteed with RVC enabled
.align 4


#if defined(TARGET_HAS_Zicsr)

trap_handler:
	# save caller sp
	csrw	MODE_PREFIX(scratch), sp

	# set up vmon stack with _estack from linker
	la		sp, _estack

stack_exists:
	# save int registers on stack
	addi	sp, sp, -(STK_FRAME_SIZE_INT)
	SAVE_X	ra, (STK_OFF_RA)(sp)
	# sp intentionally missing here, see below
	SAVE_X	x3, (STK_OFF_X3)(sp)
	SAVE_X	x4, (STK_OFF_X4)(sp)
	SAVE_X	x5, (STK_OFF_X5)(sp)
	SAVE_X	x6, (STK_OFF_X6)(sp)
	SAVE_X	x7, (STK_OFF_X7)(sp)
	SAVE_X	x8, (STK_OFF_X8)(sp)
	SAVE_X	x9, (STK_OFF_X9)(sp)
	SAVE_X	x10, (STK_OFF_X10)(sp)
	SAVE_X	x11, (STK_OFF_X11)(sp)
	SAVE_X	x12, (STK_OFF_X12)(sp)
	SAVE_X	x13, (STK_OFF_X13)(sp)
	SAVE_X	x14, (STK_OFF_X14)(sp)
	SAVE_X	x15, (STK_OFF_X15)(sp)
	#ifndef TARGET_RVE
		SAVE_X	x16, (STK_OFF_X16)(sp)
		SAVE_X	x17, (STK_OFF_X17)(sp)
		SAVE_X	x18, (STK_OFF_X18)(sp)
		SAVE_X	x19, (STK_OFF_X19)(sp)
		SAVE_X	x20, (STK_OFF_X20)(sp)
		SAVE_X	x21, (STK_OFF_X21)(sp)
		SAVE_X	x22, (STK_OFF_X22)(sp)
		SAVE_X	x23, (STK_OFF_X23)(sp)
		SAVE_X	x24, (STK_OFF_X24)(sp)
		SAVE_X	x25, (STK_OFF_X25)(sp)
		SAVE_X	x26, (STK_OFF_X26)(sp)
		SAVE_X	x27, (STK_OFF_X27)(sp)
		SAVE_X	x28, (STK_OFF_X28)(sp)
		SAVE_X	x29, (STK_OFF_X29)(sp)
		SAVE_X	x30, (STK_OFF_X30)(sp)
		SAVE_X	x31, (STK_OFF_X31)(sp)
	#endif /* TARGET_RVE */
	
	# now we can safely use t0 to get back and save sp in that same stack frame above
	#if defined(M_MODE) || defined(S_MODE)
		#ifdef TARGET_HAS_Zicsr
			csrr	t0, MODE_PREFIX(scratch)		# read original sp back
			SAVE_X	t0, (STK_OFF_SP)(sp)			# and save it
		#endif /* TARGET_HAS_Zicsr */
	#else
		SAVE_X	sp, (STK_OFF_SP)(sp)
	#endif /* M_MODE || S_MODE */

	# save xepc
	#ifdef TARGET_HAS_Zicsr
		csrr	t0, MODE_PREFIX(epc)
		SAVE_X	t0, (STK_OFF_PC)(sp)
	#endif /* TARGET_HAS_Zicsr */
	
	#ifdef TARGET_HAS_RVF
		# enable RVF in mstatus of cpu (this is disabled in QEMU per default)
		#ifdef TARGET_HAS_Zicsr
			li		t0, 0b11
			slli	t0, t0, 13
			#if defined(M_MODE) || defined(S_MODE)
				csrr	t1, MODE_PREFIX(status)
				or		t1, t0, t1
				csrw	MODE_PREFIX(status), t1
			#endif /* M_MODE || S_MODE */
		#endif /* TARGET_HAS_Zicsr */
	
		# save f0-f31 registers on stack
		addi	sp, sp, -(STK_FRAME_SIZE_FLOAT)
		SAVE_F	f0, (STK_OFF_F0)(sp)
		SAVE_F	f1, (STK_OFF_F1)(sp)
		SAVE_F	f2, (STK_OFF_F2)(sp)
		SAVE_F	f3, (STK_OFF_F3)(sp)
		SAVE_F	f4, (STK_OFF_F4)(sp)
		SAVE_F	f5, (STK_OFF_F5)(sp)
		SAVE_F	f6, (STK_OFF_F6)(sp)
		SAVE_F	f7, (STK_OFF_F7)(sp)
		SAVE_F	f8, (STK_OFF_F8)(sp)
		SAVE_F	f9, (STK_OFF_F9)(sp)
		SAVE_F	f10, (STK_OFF_F10)(sp)
		SAVE_F	f11, (STK_OFF_F11)(sp)
		SAVE_F	f12, (STK_OFF_F12)(sp)
		SAVE_F	f13, (STK_OFF_F13)(sp)
		SAVE_F	f14, (STK_OFF_F14)(sp)
		SAVE_F	f15, (STK_OFF_F15)(sp)
		SAVE_F	f16, (STK_OFF_F16)(sp)
		SAVE_F	f17, (STK_OFF_F17)(sp)
		SAVE_F	f18, (STK_OFF_F18)(sp)
		SAVE_F	f19, (STK_OFF_F19)(sp)
		SAVE_F	f20, (STK_OFF_F20)(sp)
		SAVE_F	f21, (STK_OFF_F21)(sp)
		SAVE_F	f22, (STK_OFF_F22)(sp)
		SAVE_F	f23, (STK_OFF_F23)(sp)
		SAVE_F	f24, (STK_OFF_F24)(sp)
		SAVE_F	f25, (STK_OFF_F25)(sp)
		SAVE_F	f26, (STK_OFF_F26)(sp)
		SAVE_F	f27, (STK_OFF_F27)(sp)
		SAVE_F	f28, (STK_OFF_F28)(sp)
		SAVE_F	f29, (STK_OFF_F29)(sp)
		SAVE_F	f30, (STK_OFF_F30)(sp)
		SAVE_F	f31, (STK_OFF_F31)(sp)
	#endif /* TARGET_HAS_RVF */



	# clear irq
	li		t0, 0b10000000
	csrc	MODE_PREFIX(ip), t0

	# irq or exception? check leftmost bit of xcause
	csrr	a0, MODE_PREFIX(cause)
	li		t0, 0b1
	slli	t0, t0, XLEN-1
	and		a0, a0, t0
	bnez	a0, handle_irq

	# we have an exception
	# check if exception was caused by ebreak
	csrr	t0, MODE_PREFIX(cause)
	li		t1, 3						# breakpoint exception?
	bne		t0, t1, handle_exception
	
handle_ebreak:
	# start VMON command line
	j		vmon_entry

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
	addi	t0, s0, -20							# highest known cause +1		
	blt		t0, zero, known_cause
	# cause not in table
	LWU		a0, string_CAUSE_RESERVED
	j		output_cause
known_cause:
	slli	a0, s0, 2							# set a0 = xcause * 4
	la		s0, cause_verbose_table				# start of CAUSE string table
	add		a0, a0, s0
	LWU		a0, 0(a0)
output_cause:
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
handle_irq:
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
	#ifdef TARGET_HAS_RVF
		# restore float registers
		LOAD_F	f0, (STK_OFF_F0)(sp)
		LOAD_F	f1, (STK_OFF_F1)(sp)
		LOAD_F	f2, (STK_OFF_F2)(sp)
		LOAD_F	f3, (STK_OFF_F3)(sp)
		LOAD_F	f4, (STK_OFF_F4)(sp)
		LOAD_F	f5, (STK_OFF_F5)(sp)
		LOAD_F	f6, (STK_OFF_F6)(sp)
		LOAD_F	f7, (STK_OFF_F7)(sp)
		LOAD_F	f8, (STK_OFF_F8)(sp)
		LOAD_F	f9, (STK_OFF_F9)(sp)
		LOAD_F	f10, (STK_OFF_F10)(sp)
		LOAD_F	f11, (STK_OFF_F11)(sp)
		LOAD_F	f12, (STK_OFF_F12)(sp)
		LOAD_F	f13, (STK_OFF_F13)(sp)
		LOAD_F	f14, (STK_OFF_F14)(sp)
		LOAD_F	f15, (STK_OFF_F15)(sp)
		LOAD_F	f16, (STK_OFF_F16)(sp)
		LOAD_F	f17, (STK_OFF_F17)(sp)
		LOAD_F	f18, (STK_OFF_F18)(sp)
		LOAD_F	f19, (STK_OFF_F19)(sp)
		LOAD_F	f20, (STK_OFF_F20)(sp)
		LOAD_F	f21, (STK_OFF_F21)(sp)
		LOAD_F	f22, (STK_OFF_F22)(sp)
		LOAD_F	f23, (STK_OFF_F23)(sp)
		LOAD_F	f24, (STK_OFF_F24)(sp)
		LOAD_F	f25, (STK_OFF_F25)(sp)
		LOAD_F	f26, (STK_OFF_F26)(sp)
		LOAD_F	f27, (STK_OFF_F27)(sp)
		LOAD_F	f28, (STK_OFF_F28)(sp)
		LOAD_F	f29, (STK_OFF_F29)(sp)
		LOAD_F	f30, (STK_OFF_F30)(sp)
		LOAD_F	f31, (STK_OFF_F31)(sp)
		addi	sp, sp, (STK_FRAME_SIZE_FLOAT)
	#endif /* TARGET_HAS_RVF */

	# restore xepc
	#ifdef TARGET_HAS_Zicsr
		LOAD_X	t0, STK_OFF_PC(sp)
		# advance one instruction
		# todo: check for RVC
#			addi	t0, t0, 4
		csrw	MODE_PREFIX(epc), t0
	#endif /* TARGET_HAS_Zicsr */
	
	# restore int registers
	LOAD_X	ra, (STK_OFF_RA)(sp)
	# sp intentionally left out here, do below
	LOAD_X	x3, (STK_OFF_X3)(sp)
	LOAD_X	x4, (STK_OFF_X4)(sp)
	LOAD_X	x5, (STK_OFF_X5)(sp)
	LOAD_X	x6, (STK_OFF_X6)(sp)
	LOAD_X	x7, (STK_OFF_X7)(sp)
	LOAD_X	x8, (STK_OFF_X8)(sp)
	LOAD_X	x9, (STK_OFF_X9)(sp)
	LOAD_X	x10, (STK_OFF_X10)(sp)
	LOAD_X	x11, (STK_OFF_X11)(sp)
	LOAD_X	x12, (STK_OFF_X12)(sp)
	LOAD_X	x13, (STK_OFF_X13)(sp)
	LOAD_X	x14, (STK_OFF_X14)(sp)
	LOAD_X	x15, (STK_OFF_X15)(sp)
	#ifndef TARGET_RVE
		LOAD_X	x16, (STK_OFF_X16)(sp)
		LOAD_X	x17, (STK_OFF_X17)(sp)
		LOAD_X	x18, (STK_OFF_X18)(sp)
		LOAD_X	x19, (STK_OFF_X19)(sp)
		LOAD_X	x20, (STK_OFF_X20)(sp)
		LOAD_X	x21, (STK_OFF_X21)(sp)
		LOAD_X	x22, (STK_OFF_X22)(sp)
		LOAD_X	x23, (STK_OFF_X23)(sp)
		LOAD_X	x24, (STK_OFF_X24)(sp)
		LOAD_X	x25, (STK_OFF_X25)(sp)
		LOAD_X	x26, (STK_OFF_X26)(sp)
		LOAD_X	x27, (STK_OFF_X27)(sp)
		LOAD_X	x28, (STK_OFF_X28)(sp)
		LOAD_X	x29, (STK_OFF_X29)(sp)
		LOAD_X	x30, (STK_OFF_X30)(sp)
		LOAD_X	x31, (STK_OFF_X31)(sp)
	#endif /* TARGET_RVE */

	# restore original sp saved from caller on entry
	LOAD_X	sp, (STK_OFF_SP)(sp)

	# bye bye - jump to address in xepc (while staying in current mode, see above)
	MODE_PREFIX(ret)
.size trap_handler, .-trap_handler


.section .rodata


string_exception_msg:
	.string "\nexception:"
string_epc_msg:				
	.ascii "\n\t"; 
	.ascii MODE_PREFIX_CHAR; 
	.asciz "epc\t= ";
string_tval_msg:			
	.ascii "\n\t";
	.ascii MODE_PREFIX_CHAR; 
	.asciz "tval\t= ";
string_cause_msg:
	.ascii "\n\t"; 
	.ascii MODE_PREFIX_CHAR; 
	.asciz "cause\t= ";


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
	string_CAUSE_FETCH_PAGE_FAULT:		.string "FETCH_PAGE_FAULT";
	string_CAUSE_LOAD_PAGE_FAULT:		.string "LOAD_PAGE_FAULT";
	string_CAUSE_STORE_PAGE_FAULT:		.string "STORE_PAGE_FAULT";
	string_CAUSE_SOFTWARE_CHECK:		.string "SOFTWARE_CHECK";
	string_CAUSE_HARDWARE_ERROR:		.string "HARDWARE_ERROR";
	string_CAUSE_RESERVED:				.string "RESERVED_OR_CUSTOM";

.align 4
cause_verbose_table:
	.word string_CAUSE_MISALIGNED_FETCH			#  0
	.word string_CAUSE_FAULT_FETCH				#  1
	.word string_CAUSE_ILLEGAL_INSTRUCTION		#  2
	.word string_CAUSE_BREAKPOINT				#  3
	.word string_CAUSE_MISALIGNED_LOAD			#  4
	.word string_CAUSE_FAULT_LOAD				#  5
	.word string_CAUSE_MISALIGNED_STORE			#  6
	.word string_CAUSE_FAULT_STORE				#  7
	.word string_CAUSE_USER_ECALL				#  8
	.word string_CAUSE_SUPERVISOR_ECALL			#  9
	.word string_CAUSE_HYPERVISOR_ECALL			# 10
	.word string_CAUSE_MACHINE_ECALL			# 11
	.word string_CAUSE_FETCH_PAGE_FAULT			# 12
	.word string_CAUSE_LOAD_PAGE_FAULT			# 13
	.word string_CAUSE_RESERVED					# 14
	.word string_CAUSE_STORE_PAGE_FAULT			# 15
	.word string_CAUSE_RESERVED					# 16
	.word string_CAUSE_RESERVED					# 17
	.word string_CAUSE_SOFTWARE_CHECK			# 18
	.word string_CAUSE_HARDWARE_ERROR			# 19
#endif /* CAUSE_VERBOSE */


#endif /* defined(TARGET_HAS_Zicsr) */
