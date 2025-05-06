/*
VMON - a RISC-V machine code monitor written in RISC-V assembly code
*/


#include "vmon/config.h"
#include "vmon/drivers/uart/ns16550.h"
#include "vmon/ASCII.h"


.global start
.global main_prompt
.global string_asm_sep1
.global string_asm_sep2
.global string_asm_comment
.global string_OP_UNKNOWN
.global start_data
.global start_bss


.text


# application entry point
start:
	# do not add anything before this
	#ifdef M_MODE
		# immediately save sp in mscratch
		csrw	mscratch, sp
		# run only on hart 0
		# as sp is already saved, we can use it now
		csrr	sp, mhartid
		bnez	sp, end
		# set up a stack 
		la		sp, stack + STACK_SIZE		# point to end of our new stack
	#endif /* M_MODE */

	# save registers on stack
	addi	sp, sp, -(XLEN_BYTES*31)
	SAVE_X	ra, 0(sp)  
	# sp intentionally missing here, see below
	SAVE_X	x3, (XLEN_BYTES*2)(sp)
	SAVE_X	x4, (XLEN_BYTES*3)(sp)
	SAVE_X	x5, (XLEN_BYTES*4)(sp)
	SAVE_X	x6, (XLEN_BYTES*5)(sp)
	SAVE_X	x7, (XLEN_BYTES*6)(sp)
	SAVE_X	x8, (XLEN_BYTES*7)(sp)
	SAVE_X	x9, (XLEN_BYTES*8)(sp)
	SAVE_X	x10, (XLEN_BYTES*9)(sp)
	SAVE_X	x11, (XLEN_BYTES*10)(sp)
	SAVE_X	x12, (XLEN_BYTES*11)(sp)
	SAVE_X	x13, (XLEN_BYTES*12)(sp)
	SAVE_X	x14, (XLEN_BYTES*13)(sp)
	SAVE_X	x15, (XLEN_BYTES*14)(sp)
	SAVE_X	x16, (XLEN_BYTES*15)(sp)
	SAVE_X	x17, (XLEN_BYTES*16)(sp)
	SAVE_X	x18, (XLEN_BYTES*17)(sp)
	SAVE_X	x19, (XLEN_BYTES*18)(sp)
	SAVE_X	x20, (XLEN_BYTES*19)(sp)
	SAVE_X	x21, (XLEN_BYTES*20)(sp)
	SAVE_X	x22, (XLEN_BYTES*21)(sp)
	SAVE_X	x23, (XLEN_BYTES*22)(sp)
	SAVE_X	x24, (XLEN_BYTES*23)(sp)
	SAVE_X	x25, (XLEN_BYTES*24)(sp)
	SAVE_X	x26, (XLEN_BYTES*25)(sp)
	SAVE_X	x27, (XLEN_BYTES*26)(sp)
	SAVE_X	x28, (XLEN_BYTES*27)(sp)
	SAVE_X	x29, (XLEN_BYTES*28)(sp)
	SAVE_X	x30, (XLEN_BYTES*29)(sp)
	SAVE_X	x31, (XLEN_BYTES*30)(sp)
	# now we can safely use t0 to get back and save sp
	#ifdef M_MODE
		csrr	t0, mscratch					# read original sp back
		SAVE_X	t0, (XLEN_BYTES*1)(sp)			# and save it
		csrw	mscratch, zero					# do we have to?
	#else
		SAVE_X	sp, (XLEN_BYTES*1)(sp)
	#endif /* M_MODE */

	#ifdef M_MODE
		jal		setup_trap_handler
	#endif /* M_MODE */

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

	#ifdef WITH_CMD_SLASH
		li		t0, '/'
		beq		t1, t0, cmd_SLASH
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

	#ifdef WITH_CMD_X
		li		t0, 'x'
		beq		t1, t0, cmd_X
	#endif

	# no command given, user only hit return
	li		t0, ASCII_RETURN
	beq		t1, t0, main_prompt_no_newline

unknown_command:
	la		a0, error_unknown_command
	jal		print_string
	j		main_prompt
	# end of main loop

end:
	#ifdef M_MODE
		# only if hart !=0 
		wfi
		j		end
	#endif /* M_MODE */
.size start, .-start


.data


start_data:

string_startup:		.string "\nVMON - RISC-V machine code monitor";
.size string_startup, .-string_startup
string_prompt:		.string "> ";
.size string_prompt, .-string_prompt

string_asm_sep1:	.string ":";
.size string_asm_sep1, .-string_asm_sep1
#string_asm_sep2:	 .string "\t";
string_asm_sep2:	.string " ";
.size string_asm_sep2, .-string_asm_sep2
string_asm_comment: .string "\t# ";
.size string_asm_comment, .-string_asm_comment

.bss


start_bss:
.align 8
# last address used in m or d command
.comm last_address, XLEN_BYTES	
.size last_address, XLEN_BYTES
	
.align 8
# our execution stack
.comm stack, STACK_SIZE			
.size stack, STACK_SIZE
