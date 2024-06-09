#include "vmon/config.h"
#include "vmon/drivers/uart/ns16550.h"

.text


trap_enable_UART_IRQ:
    # IRQ setup
    la      t0, traphandler
    csrrw   zero, mtvec, t0             # set vector
    # enable mstatus
    li      t0, 0b1000					# bit 3
    csrrs   zero, mstatus, t0           # enable in mstatus
    # enable mie
    li      t1, 0b100000000000			# set bit 0
    slli    t1, t1, 11					# make it bit 11
    csrrs   zero, mie, t1               # enable in mie
    # enable UART interrupt
    #li      t0, UART_IRQ_ON
    #sb      t0, UART_REG_IER(s1)
    li      s1, UART_BASE                  
    li      t0, 1
    sb      t0, 0x20(s1)      
	ret


traphandler:
    csrrc   t0, mcause, zero
/*
    bgez    t0, traphandler_done
    slli    t0, t0, 1      # shift off high bit
    srli    t0, t0, 1
    li      t1, 7          # check this is an m_timer interrupt
    bne     t0, t1, traphandler_done
*/
    # check interrupt type
    csrr    t0, mip
	#mv		a0, t0
	#jal		ra, print_hex_word

    li      t1, 1
    slli    t1, t1, 11
    and     t0, t0, t1
    beqz    t0, traphandler_done
traphandler_keypress:

    # read byte from UART
    lbu     a0, 0(s1)               # get input from UART  
    li      s1, UART_BASE                  
    # clear UART interrupt
    lb      t0, 0x14(s1)
    sb      t0, 0x14(s1)      


traphandler_done:
    #jal     print_star
    mret

