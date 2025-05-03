	#include "vmon/config.h"

	#ifdef WITH_CMD_D

	#ifdef ENABLE_RVF

	.global decode_FL
	.global decode_FS
	.global decode_FADD
	.global decode_FSQRT
	.global decode_FMA
	.global decode_FCVT_SW
	.global decode_FCVT_WS
	.global decode_FCMP
	.global decode_FCLASS


	.text

	# in: instruction word in a0
print_frd:
	addi	sp, sp, -(XLEN_BYTES*1)				 
	SAVE_X	ra, 0(sp) 
	srli	a0, a0, 7
	andi	a0, a0, 0b11111
	la		a1, float_register_names
	jal		print_register_name
	jal		print_comma
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*1)
	ret
	.size print_frd, .-print_frd


	# in: instruction word in a0
print_frs1:
	addi	sp, sp, -(XLEN_BYTES*1)				 
	SAVE_X	ra, 0(sp) 
	srli	a0, a0, 15
	and		a0, a0, 0b11111
	la		a1, float_register_names
	jal		print_register_name
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*1)
	ret
	.size print_frs1, .-print_frs1


	# in: instruction word in a0
print_frs2:
	# rs2 just needs 5 shifts more than rs1, rest works the same
	srli	a0, a0, 5			
	j		print_frs1	
	.size print_frs2, .-print_frs2


	# in: instruction word in a0
print_frs3:
	# rs2 just needs 5 shifts more than rs1, rest works the same
	srli	a0, a0, 12			 
	j		print_frs1	
	.size print_frs3, .-print_frs3


	# in: instruction word in a0
decode_FL:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		print_frd
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		decode_I_type_imm
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_rs1_as_base
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FL, .-decode_FL


	# TODO: can be joined with decode_S_type
	# in: instruction word in a0
decode_FS:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		print_frs2
	jal		print_comma
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		decode_S_type_imm
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_rs1_as_base
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FS, .-decode_FS


	# in: instruction word in a0
decode_FADD:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		print_frd
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_frs1
	jal		print_comma
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_frs2
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FADD, .-decode_FADD


	# in: instruction word in a0
decode_FMA:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		decode_FADD
	jal		print_comma
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_frs3
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FMA, .-decode_FMA


	# in: instruction word in a0
decode_FSQRT:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		print_frd
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_frs1
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FSQRT, .-decode_FSQRT


	# in: instruction word in a0
decode_FCVT_SW:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		print_frd
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_rs1
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FCVT_SW, .-decode_FCVT_SW


decode_FCVT_WS:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		print_rd
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_frs1
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FCVT_WS, .-decode_FCVT_WS


decode_FCLASS:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		print_rd
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_frs1
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FCLASS, .-decode_FCLASS


decode_FCMP:
	addi	sp, sp, -(XLEN_BYTES*2)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp) 
	jal		decode_FCLASS
	jal		print_comma
	LOAD_X	a0, (XLEN_BYTES*1)(sp)				 
	jal		print_frs2
	LOAD_X	ra, 0(sp)				
	addi	sp, sp, (XLEN_BYTES*2)
	ret
	.size decode_FCMP, .-decode_FCMP


	.data

	#endif /* ENABLE_RVF */

	#endif /* WITH_CMD_D */
