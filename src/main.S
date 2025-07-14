/*
VMON - a RISC-V machine code monitor written in RISC-V assembly code
*/
#include "config.h"
#include "vmon/drivers/uart/ns16550.h"
#include "vmon/ASCII.h"
#include "vmon/stack.h"
#include "vmon/register.h"
#include "vmon/trap.h"
#include "vmon/error.h"

#define TIMER_INTERVAL	10000000
#define MTIMECMP 		0x2004000			# QEMU CLINT 0x2000000 + 0x4000 + 8*(hart_id)


.global start
.global breakpoint_entry
.global main_prompt

.global string_asm_sep1
.global string_asm_sep2
.global string_asm_comment
.global string_OP_UNKNOWN
.global start_bss

.text


# application entry point - activate our trap handler
start:

	# do not add anything before this
	#ifdef M_MODE
		#ifdef TARGET_HAS_Zicsr
			# immediately save sp in mscratch
			csrw	mscratch, sp

			# run only on hart 0
			# as sp is already saved, we can use it now
			csrr	sp, mhartid
			bnez	sp, end

			# set up trap vector
			la		sp, trap_handler
			csrw	mtvec, sp

			# set up timer irq
			/*
			# enable all m-mode irqs
			csrsi	mstatus, 0b1000
			# set timer for the first time
			rdtime	t0
			li		t1, TIMER_INTERVAL
			add		t1, t0, t1
			la		t2, MTIMECMP
			sd		t1, 0(t2)
			# enable m-mode timer irq
			li		t1, 0b10000000
			csrs	mie, t1
			*/

			# restore sp as it were on entry
			csrr	sp, mscratch

		#endif /* TARGET_HAS_Zicsr */
	#endif /* M_MODE */

	# intentionally execute ebreak in order to enter trap handler,
	# which then will execute the main loop

	ebreak
	j		end
.size start, .-start

#########################################################################

# this is called every time the trap handler encounters a breakpoint exception
breakpoint_entry:
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
	#ifdef M_MODE
		#ifdef TARGET_HAS_Zicsr
			csrr	t0, mscratch					# read original sp back
			SAVE_X	t0, (STK_OFF_SP)(sp)			# and save it
		#endif /* TARGET_HAS_Zicsr */
	#else
		SAVE_X	sp, (STK_OFF_SP)(sp)
	#endif /* M_MODE */

	# save mepc
	#ifdef M_MODE
		#ifdef TARGET_HAS_Zicsr
			csrr	t0, mepc
			SAVE_X	t0, (STK_OFF_PC)(sp)
		#endif /* TARGET_HAS_Zicsr */
	#endif /* M_MODE */

	#ifdef TARGET_HAS_RVF
		# enable RVF in mstatus of cpu (this is disabled in QEMU per default)
		#ifdef TARGET_HAS_Zicsr
			li		t0, 0b11
			slli	t0, t0, 13
			csrr	t1, mstatus
			or		t1, t0, t1
			csrw	mstatus, t1
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

	#ifdef WITH_CMD_B
		jal		break_deactivate
	#endif /* WITH_CMD_B */

	# init UART 
	jal		uart_init

	# startup message
	la		a0, string_startup
	jal		print_string

	# main loop
main_prompt:
	jal		print_newline

main_prompt_no_newline:
	
	la		a0, string_prompt
	jal		print_string

	jal		uart_getline
	jal		skip_whitespace
	
	lb		t1, 0(a0)
	addi	a0, a0, 1

	#ifdef WITH_CMD_A
		li		t0, 'a'
		beq		t1, t0, cmd_A
	#endif

	#ifdef WITH_CMD_B
		li		t0, 'b'
		beq		t1, t0, cmd_B
	#endif

	#ifdef WITH_CMD_QMARK
		li		t0, '?'
		beq		t1, t0, cmd_QMARK
	#endif

	#ifdef WITH_CMD_C
		li		t0, 'c'
		beq		t1, t0, cmd_C
	#endif

	#ifdef WITH_CMD_D
		li		t0, 'd'
		beq		t1, t0, cmd_D
	#endif

	#ifdef WITH_CMD_F
		li		t0, 'f'
		beq		t1, t0, cmd_F
	#endif

	#ifdef WITH_CMD_G
		li		t0, 'g'
		beq		t1, t0, cmd_G
	#endif

	#ifdef WITH_CMD_H
		li		t0, 'h'
		beq		t1, t0, cmd_H
	#endif

	#ifdef WITH_CMD_I
		li		t0, 'i'
		beq		t1, t0, cmd_I
	#endif

	#ifdef WITH_CMD_M
		li		t0, 'm'
		beq		t1, t0, cmd_M
	#endif

	#ifdef WITH_CMD_P
		li		t0, 'p'
		beq		t1, t0, cmd_P
	#endif

	#ifdef WITH_CMD_R
		li		t0, 'r'
		beq		t1, t0, cmd_R
	#endif

	#ifdef WITH_CMD_S
		li		t0, 's'
		beq		t1, t0, cmd_S
	#endif

	#ifdef WITH_CMD_X
		li		t0, 'x'
		beq		t1, t0, cmd_X
	#endif

	# no command given, user only hit return
	li		t0, ASCII_RETURN
	beq		t1, t0, main_prompt_no_newline

unknown_command:
	la		a0, ERR_CMD_UNKNOWN
	jal		print_error
	j		main_prompt
	# end of main loop

end:
	#ifdef M_MODE
		wfi
		j		end
	#endif /* M_MODE */
.size breakpoint_entry, .-breakpoint_entry


string_startup:		
.ascii "\nVMON "
.ascii VERSION
.asciz " - RISC-V machine code monitor";
.size string_startup, .-string_startup

string_prompt:		.string "> ";
.size string_prompt, .-string_prompt

string_asm_sep1:	.string ":";
.size string_asm_sep1, .-string_asm_sep1
#string_asm_sep2:	 .string "\t";
string_asm_sep2:	.string " ";
.size string_asm_sep2, .-string_asm_sep2


.bss


start_bss:
.align 8
# last address used in m or d command
.comm last_address, XLEN_BYTES	
.size last_address, XLEN_BYTES
