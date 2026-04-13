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
.global vmon_entry
.global main_prompt

.global string_asm_sep1
.global string_asm_sep2
.global string_asm_comment
.global string_OP_UNKNOWN
.global start_bss


.section .init


# application entry point - activate our trap handler
start:

	# do not add anything before this

	#ifdef TARGET_HAS_Zicsr
		# immediately save t0 in mscratch
		csrw	MODE_PREFIX(scratch), t0

		#ifdef M_MODE
			# in M-Mode we need to make sure that we run only on one hart
			# as t0 is already saved, we can use it now
			csrr	t0, mhartid
			# hart 0 only
			bnez	t0, vmon_wait_hart
		#endif /* M_MODE */

		#ifdef TARGET_HAS_RVF
			# enable RVF in mstatus of cpu (this is disabled in QEMU per default)
			li		t0, 0b11
			slli	t0, t0, 13
			#if defined(M_MODE) || defined(S_MODE)
				csrs	MODE_PREFIX(status), t0
			#endif /* M_MODE || S_MODE */
		#endif /* TARGET_HAS_RVF */

		# set up trap vector
		la		t0, trap_handler
		csrw	MODE_PREFIX(tvec), t0

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

		# restore t0 as it were on entry
		csrr	t0, MODE_PREFIX(scratch)
	#endif /* TARGET_HAS_Zicsr */

	# intentionally execute ebreak in order to enter trap handler,
	# which then will execute the main loop

vmon_loop:
	ebreak
	ret
.size start, .-start

#########################################################################

# this is called every time the trap handler encounters a breakpoint exception
vmon_entry:

	#ifdef WITH_CMD_B
		jal		break_deactivate
	#endif /* WITH_CMD_B */

	# init UART 
	#ifdef M_MODE
		jal		uart_init
	#endif

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
.size vmon_entry, .-vmon_entry

vmon_wait_hart:
	wfi
	j	vmon_wait_hart
.size vmon_wait_hart, .-vmon_wait_hart


.section .rodata


string_startup:
	.ascii "\nVMON "
	.ascii VMON_VERSION
	.asciz " - RISC-V machine code monitor";
.size string_startup, .-string_startup

string_prompt:
	.string "> ";
.size string_prompt, .-string_prompt

string_asm_sep1:
	.string ":";
.size string_asm_sep1, .-string_asm_sep1

string_asm_sep2:
#	.string "\t";
	.string " ";
.size string_asm_sep2, .-string_asm_sep2


.bss


start_bss:
.align 8
# last address used in m or d command
.comm last_address, XLEN_BYTES	
.size last_address, XLEN_BYTES
