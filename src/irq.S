#include "vmon/config.h"

.global irq_setup

#define TIMER_INTERVAL 10000000

#define MTIMECMP 0x2004000			# QEMU CLINT 0x2000000 + 0x4000 + 8*(hart_id)

.text

irq_setup:
	# enable all m-mode irqs
	la		t0, irq_handler
	csrw	mtvec, t0
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
	ret


irq_handler:
	# push
    addi    sp, sp, -(XLEN_BYTES*4)              
    SAVE_X  ra, 0(sp)
    SAVE_X  a0, (XLEN_BYTES*1)(sp)
    SAVE_X  t0, (XLEN_BYTES*2)(sp)
    SAVE_X  t1, (XLEN_BYTES*3)(sp)
	# clear irq
	li 		t0, 0b10000000
	csrc	mip, t0
	# do something
	li		a0, '#'
	jal		print_char
	# reset timer
	rdtime	t0
	li		t1, TIMER_INTERVAL
	add		t1, t0, t1
	la		t0, MTIMECMP
	sd		t1, 0(t0)
	# pop
	LOAD_X  ra, 0(sp)               
    LOAD_X  a0, (XLEN_BYTES*1)(sp)               
    LOAD_X  t0, (XLEN_BYTES*2)(sp)               
    LOAD_X  t1, (XLEN_BYTES*3)(sp)               
    addi    sp, sp, (XLEN_BYTES*4)
	mret


