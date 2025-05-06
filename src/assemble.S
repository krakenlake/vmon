#include "vmon/config.h"
#include "vmon/ASCII.h"

#ifdef WITH_CMD_A

.global assemble_instruction

.global assemble_DUMMY
.global assemble_VOID
.global assemble_BRANCH
.global assemble_RTYPE


.text

# in: a0 = ptr to input text
# in: a2 = current memory address to write (needed for branch calculation)
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
	# MATCH value now in a1

	mv		s2, a0								# save function ptr in s2
	beqz	s2, assemble_instruction_done		# not found
	mv		a0, s1
	# current memory addr already in a2
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
	j 		assemble_instruction_done
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


# in: a0 = absolute target address 
# in: a1 = instruction word
# in: a2 = absolute origin address of the branch instruction
# out: modified instruction word in a1
assemble_branch_target:
	sub		a0, a0, a2					# compute relative address
	# range check
	li		t1, 4096
	bge		t0, t1, assemble_branch_target_error
	li		t1, -4096
	blt		t0, t1, assemble_branch_target_error
	# bit 11 of addr -> bit 7 insn
	mv		t0, a0
	srli	t0, t0, 4
	li		t1, 0b10000000
	and 	t0, t0, t1
	or		a1, a1, t0
	# bit 4..1 of addr -> bit 11..8 insn
	mv		t0, a0
	slli	t0, t0, 7
	li		t1, 0b111100000000
	and		t0, t0, t1
	or		a1, a1, t0
	# bit 5..10 of addr -> bit 25..30 insn
	mv		t0, a0
	slli	t0, t0, 20
	li		t1, 0b01111110000000000000000000000000
	and		t0, t0, t1
	or		a1, a1, t0
	# bit 12 of addr -> bit 31 insn
	mv		t0, a0
	slli	t0, t0, 19
	li		t1, 0b10000000000000000000000000000000
	and		t0, t0, t1
	or		a1, a1, t0
	j 		assemble_branch_target_done
assemble_branch_target_error:
	mv		a1, zero
assemble_branch_target_done:
	ret
.size assemble_branch_target, .-assemble_branch_target


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


# in: a0 = input string ptr
# in: a1 = MATCH value
# in: a2 = origin address
# out: assembled instruction in a1
assemble_BRANCH:
	addi	sp, sp, -(XLEN_BYTES*5)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s2, (XLEN_BYTES*3)(sp)
	SAVE_X	s3, (XLEN_BYTES*4)(sp)
	mv		s3, a2						# save for later
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
	jal 	assemble_rs1
	mv		s2, a1						# save insn word
	# expect commma
	addi	a0, s1, 1
	jal		skip_whitespace
	jal		consume_comma
	beqz 	a0, assemble_BRANCH_error
	# parse register 2
	jal		skip_whitespace
	mv		s0, a0
	jal		find_register_name_end
	mv		s1, a0
	# parse register 2 from user input
	mv		a0, s0
	mv		a1, s1
	jal		get_int_register_index_by_name
	bltz	a0, assemble_BRANCH_error
	# add rs2 to instruction word
	mv		a1, s2
	jal 	assemble_rs2
	mv		s2, a1						# save insn word
	# expect commma
	addi	a0, s1, 1
	jal		skip_whitespace
	jal		consume_comma
	beqz 	a0, assemble_BRANCH_error
	# parse target address from user input
	jal		skip_whitespace	
	jal		get_hex_addr
	bnez	a2, assemble_BRANCH_error
	# add branch target address to instruction word
	mv		a0, a1						# absolute target address
	mv		a1, s2						# instruction word
	mv		a2, s3						# get saved origin addr back
	jal		assemble_branch_target
	beqz 	a1, assemble_BRANCH_error   # address too far away
	mv		s2, a1						# save insn word
	j 		assemble_BRANCH_OK	
assemble_BRANCH_error:
	mv		a1, zero
	j 		assemble_BRANCH_done
assemble_BRANCH_OK:
	mv		a1, s2
assemble_BRANCH_done:
	LOAD_X	ra, 0(sp)				
	LOAD_X	s0, (XLEN_BYTES*1)(sp)				 
	LOAD_X	s1, (XLEN_BYTES*2)(sp)				 
	LOAD_X	s2, (XLEN_BYTES*3)(sp)				 
	LOAD_X	s3, (XLEN_BYTES*4)(sp)				 
	addi	sp, sp, (XLEN_BYTES*5)
	ret
.size assemble_BRANCH, .-assemble_BRANCH


# in: a0 = input string ptr
# in: a1 = MATCH value
# in: a2 = origin address
# out: assembled instruction in a1
assemble_RTYPE:
	addi	sp, sp, -(XLEN_BYTES*5)				 
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s2, (XLEN_BYTES*3)(sp)
	SAVE_X	s3, (XLEN_BYTES*4)(sp)
	mv		s3, a2						# save for later
	# assemble instruction word in s2, starting with MATCH value
	mv		s2, a1	
	# advance to parameter 1
	jal		skip_whitespace
	mv		s0, a0
	jal		find_register_name_end
	mv		s1, a0
	# parse rd from user input
	mv		a0, s0
	mv		a1, s1
	jal		get_int_register_index_by_name
	bltz	a0, assemble_RTYPE_error
	# add rd to instruction word
	mv		a1, s2
	jal 	assemble_rd
	mv		s2, a1						# save insn word
	# expect commma
	addi	a0, s1, 1
	jal		skip_whitespace
	jal		consume_comma
	beqz 	a0, assemble_RTYPE_error
	# advance to parameter 2
	jal		skip_whitespace
	mv		s0, a0
	jal		find_register_name_end
	mv		s1, a0
	# parse rs1 from user input
	mv		a0, s0
	mv		a1, s1
	jal		get_int_register_index_by_name
	bltz	a0, assemble_RTYPE_error
	# add rs1 to instruction word
	mv		a1, s2
	jal 	assemble_rs1
	mv		s2, a1						# save insn word
	# expect commma
	addi	a0, s1, 1
	jal		skip_whitespace
	jal		consume_comma
	beqz 	a0, assemble_RTYPE_error
	# advance to parameter 3
	jal		skip_whitespace
	mv		s0, a0
	jal		find_register_name_end
	mv		s1, a0
	# parse rs2 from user input
	mv		a0, s0
	mv		a1, s1
	jal		get_int_register_index_by_name
	bltz	a0, assemble_RTYPE_error
	# add rs2 to instruction word
	mv		a1, s2
	jal 	assemble_rs2
	mv		s2, a1						# save insn word
	j 		assemble_RTYPE_OK	
assemble_RTYPE_error:
	mv		a1, zero
	j 		assemble_RTYPE_done
assemble_RTYPE_OK:
	mv		a1, s2
assemble_RTYPE_done:
	LOAD_X	ra, 0(sp)				
	LOAD_X	s0, (XLEN_BYTES*1)(sp)				 
	LOAD_X	s1, (XLEN_BYTES*2)(sp)				 
	LOAD_X	s2, (XLEN_BYTES*3)(sp)				 
	LOAD_X	s3, (XLEN_BYTES*4)(sp)				 
	addi	sp, sp, (XLEN_BYTES*5)
	ret
.size assemble_RTYPE, .-assemble_RTYPE


#endif /* WITH_CMD_A */
