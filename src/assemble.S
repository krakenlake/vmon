	#include "vmon/config.h"
	#include "vmon/ASCII.h"

	#ifdef WITH_CMD_A

	.global assemble_instruction

	.global assemble_DUMMY
	.global assemble_VOID
	.global assemble_BRANCH


	.text

	# in: a0 = ptr to input text
	# out: a0 = number of bytes written to memory (normal 4, 2 for RVC, 0 if error)
	# out: a1 = assembled instruction to be written into memory
assemble_instruction:  
	addi	sp, sp, -(XLEN_BYTES*3)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	jal		skip_whitespace
	mv		s0, a0
	jal		find_insn_name_end
	mv		s1, a0
	# find string between s0 and s1 in encoding table
	jal		get_data_by_insn_name
	# function ptr now in a0
	beqz	a0, assemble_instruction_done		# not found
	jalr	a0									# call assemble function   
	beqz	a0, assemble_instruction_done		# error while assembling insn parameters
	# now use a0 to return insn size
	mv		a0, a1	  
	#ifdef ENABLE_RVC
	jal		insn_is_compressed
	bnez	a0, assemble_instruction_is_RVC
	li		a0, 4
	j		assemble_instruction_done
assemble_instruction_is_RVC:
	li		a0, 2
	#else
	li		a0, 4
	#endif
assemble_instruction_done:
	LOAD_X	ra, 0(sp)				
	LOAD_X	s0, (XLEN_BYTES*1)(sp)				 
	LOAD_X	s1, (XLEN_BYTES*2)(sp)				 
	addi	sp, sp, (XLEN_BYTES*3)
	ret
	.size assemble_instruction, .-assemble_instruction


	# in: input string ptr in a0
	# out: register number in a1 (-1 if error)
assemble_rs1:
	ret
	.size assemble_rs1, .-assemble_rs1

	
	# in: input string ptr in a0
assemble_DUMMY:
	li		a1, 0xffffffff
	ret
	.size assemble_DUMMY, .-assemble_DUMMY


	# in: input string ptr in a0
	# in: MATCH value in a1
assemble_VOID:
	# nothing to be done, a1 already contains final insn
	ret
	.size assemble_VOID, .-assemble_VOID


	# in: input string ptr in a0
	# in: MATCH value in a1
assemble_BRANCH:
	# read rs1
	jal		skip_whitespace

	# read comma
	jal		skip_whitespace

	# read rs2
	jal		skip_whitespace

	# read comma
	jal		skip_whitespace

	# read address
	jal		skip_whitespace

	ret
	.size assemble_BRANCH, .-assemble_BRANCH


	#endif /* WITH_CMD_A */
