#include "vmon/config.h"
#include "vmon/drivers/uart/ns16550.h"


.global uart_output_buffer

.text

# print output buffer to UART
# buffer will be filled with zeros on return
uart_output_buffer:
    addi    sp, sp, -(XLEN_BYTES*1)             
    SAVE_X  ra, 0(sp)
    la      t1, out_buf  

uart_output_buffer_next_byte:
	# TODO: output in blocks of x bytes? use FIFO?
    lbu     t0, 0(t1)				# get next byte from buffer
	sb		zero, 0(t1)				# clear buffer on the go
    beq     t0, zero, uart_output_buffer_done


	# busy wait for UART to become ready
    # TODO: use interrupts 
    li      t2, UART_BASE  
uart_output_buffer_wait_lsr:
    lbu     t3, UART_REG_LSR(t2)
    andi    t3, t3, 0b00100000 
    beqz    t3, uart_output_buffer_wait_lsr


    # UART is now ready to receive data for TX
    sb      t0, 0(s1)               # print byte to UART
    addi    t1, t1, 1
    j       uart_output_buffer_next_byte

uart_output_buffer_done:
    LOAD_X  ra, 0(sp)             
    addi    sp, sp, (XLEN_BYTES*1)
    ret

