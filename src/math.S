	#include "vmon/config.h"


	.global divrem

	.text

	# Unsigned integer division without using M extension
	# Thanks to Bruce Hoult!
	# in: a0 = dividend
	# in: a1 = divisor
	# out: a0 = quotient 
	# out: a1 = remainder
	# clobbered: a2, a3, a4, a5
divrem:
	# check for division by zero, if so immediately return
	beqz	a1, divrem_zero
	
	mv		a2, a0			# N = dividend
	mv		a3, a1			# D = divisor
	li		a0, 0			# Q = 0 (quotient)
	li		a1, 0			# R = 0 (remainder)
	li		a5, 1			# bit mask: bit = 1
	slli	a5, a5, XLEN-1	# Set bit to the highest bit position

divrem_loop:
	# Shift remainder left by 1
	slli	a1, a1, 1

	# Isolate the highest bit of the dividend (N)
	and		a4, a2, a5
	snez	a4, a4		   # Set tmp to 1 if bit is set, 0 otherwise
	add		a1, a1, a4	   # Add the bit to the remainder

	# Check if remainder (R) is greater than or equal to divisor (D)
	bltu	a1, a3, divrem_continue
	sub		a1, a1, a3	   # Subtract divisor from remainder
	add		a0, a0, a5	   # Add bit to quotient

divrem_continue:
	# Shift the bit mask to the right
	srli	a5, a5, 1
	bnez	a5, divrem_loop

	ret

divrem_zero:
	li		a0, 0			# Return quotient = 0 (or some error code if needed)
	ret

	.size divrem, .-divrem
