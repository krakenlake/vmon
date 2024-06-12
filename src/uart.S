#include "vmon/config.h"
#include "vmon/drivers/uart/ns16550.h"


.global uart_init
.global uart_wait_get_char
.global uart_output_buffer

.text

uart_init:
    li      s1, UART_BASE                  
    li      t0, UART_MODE_8N1
    sb      t0, UART_REG_LSR(s1)      
    ret

# wait and get one character from UART 
# return: char in a0
uart_wait_get_char:
    li      s1, UART_BASE
uart_get_char_wait:
    # busy wait for key pressed
    # TODO: use interrupt instead of polling
    lb      a0, 5(s1)                   # read Line Status Register
    and     a0, a0, 0x01
    beqz    a0, uart_get_char_wait      # wait for char input
    lbu     a0, 0(s1)               # get input from UART  
    ret

# print zero-terminated string in output buffer out_buf to UART
# buffer will be filled with zeros on return
uart_output_buffer:
    addi    sp, sp, -(XLEN_BYTES*1)             
    SAVE_X  ra, 0(sp)
    la      t1, out_buf  
uart_output_buffer_next_byte:
	# TODO: output in blocks of x bytes? use FIFO?
    lbu     t0, 0(t1)				    # get next byte from buffer
	sb		zero, 0(t1)				    # clear buffer on the go
    beq     t0, zero, uart_output_buffer_done
	# busy wait for UART to become ready
    # TODO: use interrupts 
    li      t2, UART_BASE  
uart_output_buffer_wait_lsr:
    lbu     t3, UART_REG_LSR(t2)
    andi    t3, t3, 0b00100000 
    beqz    t3, uart_output_buffer_wait_lsr
    # UART is now ready to receive data for TX
    sb      t0, 0(s1)                   # print byte to UART
    addi    t1, t1, 1
    j       uart_output_buffer_next_byte
uart_output_buffer_done:
    LOAD_X  ra, 0(sp)             
    addi    sp, sp, (XLEN_BYTES*1)
    ret

