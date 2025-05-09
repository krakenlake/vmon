#include "vmon/config.h"
#include "vmon/ASCII.h"

#ifdef WITH_CMD_A

.global assemble_instruction

.global assemble_DUMMY

.global assemble_GENERIC
.global ass_rd							# expect int register name and use it for rd
.global ass_rs1							# expect int register name and use it for rs1
.global ass_rs2							# expect int register name and use it for rs2

.global ass_BRA							# expect branch target address in hex
.global ass_I_imm						# expect immediate for I-type AND/ADD/OR/XOR in dec
.global ass_I_shift						# expect immediate for I-type shifts in dec

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
	# table entry ptr in a3
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


# in: a0 = absolute target address 
# in: a1 = instruction word
# in: a2 = absolute origin address of the branch instruction
# out: a1 = modified instruction word (0 on error)
assemble_branch_target:
	sub		a0, a0, a2					# compute relative address
	# range check
	li		t1, 4096
	bge		t0, t1, assemble_branch_target_error
	li		t1, -4096
	blt		t0, t1, assemble_branch_target_error
	# bit 11 of addr -> bit 7 insn
	srli	t0, a0, 4
	li		t1, 0b10000000
	and 	t0, t0, t1
	or		a1, a1, t0
	# bit 4..1 of addr -> bit 11..8 insn
	slli	t0,a0, 7
	li		t1, 0b111100000000
	and		t0, t0, t1
	or		a1, a1, t0
	# bit 5..10 of addr -> bit 25..30 insn
	slli	t0, a0, 20
	li		t1, 0b01111110000000000000000000000000
	and		t0, t0, t1
	or		a1, a1, t0
	# bit 12 of addr -> bit 31 insn
	slli	t0, a0, 19
	li		t1, 0b10000000000000000000000000000000
	and		t0, t0, t1
	or		a1, a1, t0
	j 		assemble_branch_target_done
assemble_branch_target_error:
	mv		a1, zero
assemble_branch_target_done:
	ret
.size assemble_branch_target, .-assemble_branch_target

# in: a0 = imm value
# in: a1 = instruction word
# out: a1 = modified instruction word
assemble_I_imm_bool:
	slli	a0, a0, 20
	or		a1, a1, a0
	ret
.size assemble_I_imm_bool, .-assemble_I_imm_bool


# in: a0 = imm value (accepted values are 0 <= imm <= 31)
# in: a1 = instruction word
# out: a1 = modified instruction word (0 on error)
assemble_I_imm_shift:
	bltz	a0, assemble_I_imm_shift_error
	li		t0, 32
	bge		a0, t0, assemble_I_imm_shift_error
	slli	a0, a0, 20
	or		a1, a1, a0
	j		assemble_I_imm_shift_done
assemble_I_imm_shift_error:
	mv		a1, zero
assemble_I_imm_shift_done:
	ret
.size assemble_I_imm_shift, .-assemble_I_imm_shift


# in: input string ptr in a0
assemble_DUMMY:
	li		a1, 0xffffffff
	ret
.size assemble_DUMMY, .-assemble_DUMMY


# in: a0 = ptr to remaining input string
# in: a2 = origin address
# in: a3 = ptr to encoding table entry
# out: assembled instruction in a1
assemble_GENERIC:
	addi	sp, sp, -(XLEN_BYTES*5)
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s2, (XLEN_BYTES*3)(sp)
	SAVE_X	s3, (XLEN_BYTES*4)(sp)
	mv		s2, a2
	# assemble instruction word in s1, starting with MATCH value from table
	#if XLEN >= 64
		lwu		s1, 4(a3)
	#else
		lw		s1, 4(a3)
	#endif
	# init offset to function pointers into encoding table entry
	add		s3, a3, 20
	# get function ptr for argument
	#if XLEN >= 64
		lwu		s0, 0(s3)
	#else
		lw		s0, 0(s3)
	#endif
	# done if no arguments at all
	beqz	s0, assemble_GENERIC_done
assemble_GENERIC_next_argument:
	# advance string ptr to arg
	jal		skip_whitespace
	# assemble argument
											# ptr to parameter start in a0
	mv		a1, s1							# insn word in a1
	mv		a2, s2							# origin address in a2
	jalr 	s0	
	beqz	a1, assemble_GENERIC_error		# assembling argument failed
	mv		s1, a1							# save insn word
	# get next function ptr
	addi	s3, s3, 4
	# get function ptr for argument
	#if XLEN >= 64
		lwu		s0, 0(s3)
	#else
		lw		s0, 0(s3)
	#endif
	beqz	s0, assemble_GENERIC_done
	# expect commma
	jal		skip_whitespace
	jal		consume_comma
	beqz 	a0, assemble_GENERIC_error
	j 		assemble_GENERIC_next_argument
assemble_GENERIC_error:
	mv		a1, zero
assemble_GENERIC_done:
	LOAD_X	ra, 0(sp)
	LOAD_X	s0, (XLEN_BYTES*1)(sp)
	LOAD_X	s1, (XLEN_BYTES*2)(sp)
	LOAD_X	s1, (XLEN_BYTES*3)(sp)
	LOAD_X	s3, (XLEN_BYTES*4)(sp)
	addi	sp, sp, (XLEN_BYTES*5)
	ret
.size assemble_GENERIC, .-assemble_GENERIC


# add parameter for sll in s3 and call assemble_int_register
ass_rd:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	li		s3, 7						# number of left shifts for rd
	jal		assemble_int_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size ass_rd, .-ass_rd


# add parameter for sll in s3 and call assemble_int_register
ass_rs1:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	li		s3, 15						# number of left shifts for rs1
	jal		assemble_int_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size ass_rs1, .-ass_rs1


# add parameter for sll in s3 and call assemble_int_register
ass_rs2:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	li		s3, 20						# number of left shifts for rs2
	jal		assemble_int_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size ass_rs2, .-ass_rs2


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# in: s3 = number of slli shifts required (7 for rd, 15 for rs1, 20 for rs2)
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
assemble_int_register:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	ra, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s2, (XLEN_BYTES*3)(sp)
	mv		s1, a1								# save insn word
	# parse register name
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		s2, a0								# save string end
	mv		a1, a0								# reg name end
	mv		a0, s0								# reg name start
	jal		get_int_register_index_by_name
	bltz	a0, assemble_int_register_error
	# register number now in a0
	# assemble into a1
	sll		a0, a0, s3
	or		a1, s1, a0
	j		assemble_int_register_done
assemble_int_register_error:
	mv		a1, zero
assemble_int_register_done:
	addi	a0, s2, 1							# return reg name end +1
	LOAD_X	ra, 0(sp)
	LOAD_X	s0, (XLEN_BYTES*1)(sp)
	LOAD_X	s1, (XLEN_BYTES*2)(sp)
	LOAD_X	s2, (XLEN_BYTES*3)(sp)
	addi	sp, sp, (XLEN_BYTES*4)
	ret
.size assemble_int_register, .-assemble_int_register


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_BRA:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	ra, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	SAVE_X	s3, (XLEN_BYTES*3)(sp)
	mv		s1, a1						# save insn word
	mv		s3, a2						# save for later
	jal		get_hex_addr
	# address in a1
	bnez	a2, ass_BRA_error
	mv		s2, a0						# return string ptr later
	# add branch target address to instruction word
	mv		a0, a1						# absolute target address
	mv		a1, s1						# instruction word
	mv		a2, s3						# get saved origin addr back
	jal		assemble_branch_target
	beqz 	a1, ass_BRA_error			# address too far away
	# return a1 and a0
	addi	a0, s2, 1							# string ptr +1
	j		ass_BRA_done
ass_BRA_error:
	mv		a1, zero
ass_BRA_done:
	LOAD_X	ra, 0(sp)
	LOAD_X	s1, (XLEN_BYTES*1)(sp)
	LOAD_X	s2, (XLEN_BYTES*2)(sp)
	LOAD_X	s3, (XLEN_BYTES*3)(sp)
	addi	sp, sp, (XLEN_BYTES*4)
	ret
.size ass_BRA, .-ass_BRA


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_I_imm:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	jal		parse_decimal
	# address in a1
	bnez	a2, ass_I_imm_error
	mv		s2, a0						# return string ptr later
	# add imm value to instruction word
	mv		a0, a1						# imm value
	mv		a1, s1						# instruction word
	# check funct3 of insn  - are assembling a shift insn?
	srli	t0, s1, 12
	andi	t0, t0, 0b111
	li		t1, 1						# slli
	beq		t0, t1, ass_I_imm_its_shift
	li		t1, 5						# srli or srai
	beq		t0, t1, ass_I_imm_its_shift
	# fall through for boolean insns
ass_I_imm_its_bool:
	jal		assemble_I_imm_bool
	beqz 	a1, ass_I_imm_error			# imm too big for boolean op
	j		ass_I_imm_continue
ass_I_imm_its_shift:
	jal		assemble_I_imm_shift
	beqz 	a1, ass_I_imm_error			# imm too big for shift
ass_I_imm_continue:
	# return a1 and a0
	addi	a0, s2, 1					# string ptr +1
	j		ass_I_imm_done
ass_I_imm_error:
	mv		a1, zero
ass_I_imm_done:
	LOAD_X	ra, 0(sp)
	LOAD_X	s1, (XLEN_BYTES*1)(sp)
	LOAD_X	s2, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_I_imm, .-ass_I_imm


#endif /* WITH_CMD_A */
