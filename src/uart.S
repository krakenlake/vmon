	#include "vmon/config.h"
	#include "vmon/drivers/uart/ns16550.h"
	#include "vmon/ASCII.h"



	.global uart_init
	.global uart_wait_get_char
	.global uart_output_char
	.global uart_output_string
	.global uart_output_buffer
	.global uart_getline

	.text

uart_init:
	li		t1, UART_BASE				   
	li		t0, UART_MODE_8N1
	sb		t0, UART_REG_LSR(t1)	  
	ret
	.size uart_init, .-uart_init


uart_clear_buffer:
	la		t0, uart_input_buffer
	addi	t1, t0, BUFFER_SIZE
uart_clear_buffer_loop:
	sw		zero, 0(t0)
	addi	t0, t0, 4
	ble		t0, t1, uart_clear_buffer_loop
	ret
	.size uart_clear_buffer, .-uart_clear_buffer


	# wait and get one character from UART 
	# out: char (ASCII) in a0
uart_wait_get_char:
	li		t0, UART_BASE
uart_get_char_wait:
	# busy wait for key pressed
	# TODO: use interrupt instead of polling
	lb		a0, UART_REG_LSR(t0)		# read Line Status Register
	and		a0, a0, 0x01
	beqz	a0, uart_get_char_wait		# wait for char input
	lbu		a0, 0(t0)					# get input from UART  
	ret
	.size uart_wait_get_char, .-uart_wait_get_char


	# output one char 
	# in: char (ASCII) in a0
uart_output_char:
	addi	sp, sp, -(XLEN_BYTES*1)				
	SAVE_X	ra, 0(sp)
	la		t0, out_buf	 
	andi	a0, a0, 0xff				# make sure value is < 256		
	sh		a0, 0(t0)					# write char and zero termination to buffer
	jal		uart_output_buffer
	LOAD_X	ra, 0(sp)			  
	addi	sp, sp, (XLEN_BYTES*1)
	ret
	.size uart_output_char, .-uart_output_char


	# output zero-terminated string	 
	# in: string ptr in a0
uart_output_string:
	addi	sp, sp, -(XLEN_BYTES*1)				
	SAVE_X	ra, 0(sp)
	mv		a1, a0
uart_output_string_loop:
	lb		a0, 0(a1)
	beqz	a0, uart_output_string_done
	#ifdef USE_CRLF
	li		t0, ASCII_NEWLINE
	bne		a0, t0, uart_output_string_char
	li		a0, ASCII_RETURN  # First output CR
	jal		uart_output_char
	li		a0, ASCII_NEWLINE # Put LF back in a0
uart_output_string_char:
	#endif
	jal		uart_output_char
	addi	a1, a1, 1
	j		uart_output_string_loop
uart_output_string_done:
	LOAD_X	ra, 0(sp)			  
	addi	sp, sp, (XLEN_BYTES*1)
	ret
	.size uart_output_string, .-uart_output_string


	# print zero-terminated string in output buffer out_buf to UART
	# buffer will be filled with zeros on return
uart_output_buffer:
	addi	sp, sp, -(XLEN_BYTES*1)				
	SAVE_X	ra, 0(sp)
	la		t1, out_buf	 
	li		t4, UART_BASE
uart_output_buffer_next_byte:
	# TODO: output in blocks of x bytes? use FIFO?
	lbu		t0, 0(t1)					# get next byte from buffer
	sb		zero, 0(t1)					# clear buffer on the go
	beq		t0, zero, uart_output_buffer_done
	# busy wait for UART to become ready
	# TODO: use interrupts 
	li		t2, UART_BASE  
uart_output_buffer_wait_lsr:
	lbu		t3, UART_REG_LSR(t2)
	andi	t3, t3, 0b00100000 
	beqz	t3, uart_output_buffer_wait_lsr
	# UART is now ready to receive data for TX
	sb		t0, UART_REG_THR(t4)				   # print byte to UART
	addi	t1, t1, 1
	j		uart_output_buffer_next_byte
uart_output_buffer_done:
	LOAD_X	ra, 0(sp)			  
	addi	sp, sp, (XLEN_BYTES*1)
	ret
	.size uart_output_buffer, .-uart_output_buffer


	# get a line of input from UART until RETURN is hit
	# out: buffer start in a0
uart_getline:
	addi	sp, sp, -(XLEN_BYTES*3)				
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)

	jal		uart_clear_buffer

	la		s0, uart_input_buffer
	mv		s1, s0					# save a copy in s1 for later
uart_get_char:
	jal		uart_wait_get_char
	# is DELETE?
	li		t0, ASCII_DELETE		
	beq		a0, t0, uart_input_is_delete
	# char is not DELETE
	# check if end of input buffer is reached
	la		t0, uart_input_buffer
	addi	t0, t0, BUFFER_SIZE
	# do not process input further when buffer is full
	# (only possible user action when buffer is full will be to hit DELETE)
	bge		s0, t0, uart_get_char

	sb		a0, 0(s0)				# store byte in input buffer
	addi	s0, s0, 1				# inc buffer ptr
	j		uart_continue_not_delete

uart_input_is_delete:
	# TODO: if the previous key transmitted more than 1 byte, this does 
	# not work properly 
	beq		s0, s1, uart_get_char		 # ignore at beginning of line
	addi	s0, s0, -1
	# ASCII output
	li		a0, ASCII_BACKSPACE
	jal		uart_output_char
	li		a0, ' '
	jal		uart_output_char
	li		a0, ASCII_BACKSPACE
	jal		uart_output_char
	j		uart_get_char  

uart_continue_not_delete:
	# output char in a0
	jal		uart_output_char
	li		t0, ASCII_RETURN		
	beq		a0, t0, uart_getline_done
	j		uart_get_char	   

uart_getline_done:
	# print LF to follow read CR
	li a0, ASCII_NEWLINE
	jal uart_output_char
	# return buffer address
	mv		a0, s1

	LOAD_X	ra, 0(sp)			  
	LOAD_X	s0, (XLEN_BYTES*1)(sp)				 
	LOAD_X	s1, (XLEN_BYTES*2)(sp)				 
	addi	sp, sp, (XLEN_BYTES*3)
	ret
	.size uart_getline, .-uart_getline


	.bss
	
	.align 8
	.comm uart_input_buffer, BUFFER_SIZE
	.size uart_input_buffer, BUFFER_SIZE

