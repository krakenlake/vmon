#include "vmon/config.h"
#include "vmon/ASCII.h"

#ifdef WITH_CMD_A

.global assemble_instruction

.global assemble_DUMMY
.global assemble_VOID
.global assemble_BRANCH


.text

	# in: a0 = ptr to input text
	# out: a0 = insn size (normal 4, 2 for RVC, 0 if error)
	# out: a1 = assembled instruction to be written into memory
assemble_instruction:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s2, (XLEN_BYTES*3)(sp)
	jal		skip_whitespace
	mv		s0, a0
	jal		find_insn_name_end
	mv		s1, a0
	# find string between s0 and s1 in encoding table
	jal		get_data_by_insn_name
	# function ptr now in a0
	mv		s2, a0								# save function ptr in s2
	beqz	s2, assemble_instruction_done		# not found
	mv		a0, s1
	jalr	s2									# call insn-specific assemble function
	# now a1 = insn code
	# in case insn == 0, 
	beqz	a1, assemble_instruction_error		# error while assembling insn parameters
	# now use a0 to return insn size
#ifdef ENABLE_RVC
	mv		a0, a1
	jal		insn_is_compressed
	bnez	a0, assemble_instruction_is_RVC
	li		a0, 4
	j		assemble_instruction_done
assemble_instruction_is_RVC:
	li		a0, 2
#else
	li		a0, 4
#endif
	j		assemble_instruction_done
assemble_instruction_error:
	mv		a0, zero
assemble_instruction_done:
	LOAD_X	ra, 0(sp)				
	LOAD_X	s0, (XLEN_BYTES*1)(sp)				 
	LOAD_X	s1, (XLEN_BYTES*2)(sp)				 
	LOAD_X	s2, (XLEN_BYTES*3)(sp)				 
	addi	sp, sp, (XLEN_BYTES*4)
	ret
.size assemble_instruction, .-assemble_instruction


	# in: register number in a0
	# in: instruction word in a1
	# out: modified instruction word in a1
assemble_rd:
	slli	a0, a0, 7
	or		a1, a1, a0
	ret
.size assemble_rd, .-assemble_rd


	# in: register number in a0
	# in: instruction word in a1
	# out: modified instruction word in a1
assemble_rs1:
	slli	a0, a0, 15
	or		a1, a1, a0
	ret
.size assemble_rs1, .-assemble_rs1


	# in: register number in a0
	# in: instruction word in a1
	# out: modified instruction word in a1
assemble_rs2:
	slli	a0, a0, 20
	or		a1, a1, a0
	ret
.size assemble_rs2, .-assemble_rs2


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
	# out: assembled instruction in a1
assemble_BRANCH:
	addi	sp, sp, -(XLEN_BYTES*4)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s2, (XLEN_BYTES*3)(sp)

	# assemble instruction word in s2, starting with MATCH value
	mv		s2, a1

	# advance to first user input parameter
	jal		skip_whitespace
	mv		s0, a0
	jal		find_register_name_end
	mv		s1, a0

	# parse register 1 from user input
	mv		a0, s0
	mv		a1, s1
	jal		get_int_register_index_by_name
	bltz	a0, assemble_BRANCH_error

	# add rs1 to instruction word
	mv		a1, s2
	jal	assemble_rs1
	mv		s2, a1

	# assemble register 1
	# expect ,
	# parse register 2
	# assemble register 2
	# expect ,
	# parse address (or label)
	# assemble address

	j		assemble_BRANCH_done	
assemble_BRANCH_error:
	mv		a1, zero
assemble_BRANCH_done:
	mv		a1, s2
	LOAD_X	ra, 0(sp)				
	LOAD_X	s0, (XLEN_BYTES*1)(sp)				 
	LOAD_X	s1, (XLEN_BYTES*2)(sp)				 
	LOAD_X	s2, (XLEN_BYTES*3)(sp)				 
	addi	sp, sp, (XLEN_BYTES*4)
	ret
.size assemble_BRANCH, .-assemble_BRANCH


#endif /* WITH_CMD_A */
