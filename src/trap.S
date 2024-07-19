#include "vmon/config.h"

#ifdef BARE_METAL

.global setup_trap_handler

#define TIMER_INTERVAL 10000000

#define MTIMECMP 0x2004000			# QEMU CLINT 0x2000000 + 0x4000 + 8*(hart_id)

.text


setup_trap_handler:
	# save the value which the stack ptr has when entering main_prompt
	la		t0, stackptr_reset
	sd		sp, 0(t0)
	# set up trap vector
	la		t0, trap_handler
	csrw	mtvec, t0
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
	li 		t1, 0b10000000
    csrs 	mie, t1
*/
	ret
.size setup_trap_handler, .-setup_trap_handler


# trap handler needs to be aligned manually 
# as that is not automatically guaranteed with RVC enabled
.align 4

trap_handler:
	# push stack
    addi    sp, sp, -(XLEN_BYTES*4)              
    SAVE_X  ra, 0(sp)
    SAVE_X  a0, (XLEN_BYTES*1)(sp)
    SAVE_X  t0, (XLEN_BYTES*2)(sp)
    SAVE_X  t1, (XLEN_BYTES*3)(sp)
	# clear irq
	li 		t0, 0b10000000
	csrc	mip, t0
	# irq or exception? check leftmost bit of mcause
	csrr	a0, mcause
	li		t0, 0b1
	slli	t0, t0, XLEN-1
	and		a0, a0, t0
	bnez	a0, trap_handler_irq
	# was exception
trap_handler_exception:
	# in case of an exception:
	# 1. print the exception
	# 2. reset the program to a defined state
	# 3. abort the current command and wait for the next command
	la		a0, string_exception_msg
	jal		print_string
	csrr	a0, mcause
	jal		print_hex
	# set return address for leaving trap handler
	la		a0, main_prompt
	csrw	mepc, a0
	# reset stack to the value that should have at main_prompt
	la		a0, stackptr_reset
	ld		sp, 0(a0)
	mret
trap_handler_irq:
	li		a0, '#'
	jal		print_char
	# reset timer
	rdtime	t0
	li		t1, TIMER_INTERVAL
	add		t1, t0, t1
	la		t0, MTIMECMP
	sd		t1, 0(t0)
trap_handler_pop:
	# pop stack
	LOAD_X  ra, 0(sp)               
    LOAD_X  a0, (XLEN_BYTES*1)(sp)               
    LOAD_X  t0, (XLEN_BYTES*2)(sp)               
    LOAD_X  t1, (XLEN_BYTES*3)(sp)               
    addi    sp, sp, (XLEN_BYTES*4)
	mret
.size trap_handler, .-trap_handler


.data

.align 4

string_exception_msg:		.string "\nexception: mcause=";

.bss
.align 8
.comm stackptr_reset, XLEN_BYTES


#endif /* BARE_METAL */