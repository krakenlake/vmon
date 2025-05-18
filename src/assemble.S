#include "vmon/config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"


#ifdef WITH_CMD_A

.global assemble_instruction

# these are called through function ptrs in the encoding table
.global assemble_GENERIC
.global ass_rd							# expect int register name and use it for rd
.global ass_rs1							# expect int register name and use it for rs1
.global ass_rs2							# expect int register name and use it for rs2
.global ass_BRA							# expect branch target address in hex
.global ass_I_imm						# expect immediate for I-type AND/ADD/OR/XOR in dec
.global ass_I_shift						# expect immediate for I-type shifts in dec
.global ass_MEM							# expect imm(reg) parameter for load/store
.global ass_PRE							# expect iorw predecessor parameter for fence
.global ass_SUC							# expect iorw sucessor parameter for fence
.global ass_J							# expect J-type address
.global ass_U_imm						# expect immediate for U-type (LUI/AUIPC)

#ifdef ENABLE_RVA
	.global ass_aqrl						# expect ".aqrl" extension for RVA
	.global ass_AMEM						# expect (reg) parameter for RVA
#endif /* ENABLE_RVA */

#ifdef ENABLE_RVF
	.global ass_frd							# expect int register name and use it for frd
	.global ass_frs1						# expect int register name and use it for RVF frs1
	.global ass_frs2						# expect int register name and use it for RVF frs2
	.global ass_frs3						# expect int register name and use it for RVF frs3
#endif /* ENABLE_RVF */

.text


# in: a0 = ptr to input text
# in: a2 = current memory address to write (needed for branch calculation)
# out: a0 = insn size (normal 4, 2 for RVC, 0 if error)
# out: a1 = assembled instruction to be written into memory
assemble_instruction:
	addi	sp, sp, -(XLEN_BYTES*5)
	SAVE_X	s3, 0(sp)
	SAVE_X	s2, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s0, (XLEN_BYTES*3)(sp)
	SAVE_X	ra, (XLEN_BYTES*4)(sp)

	mv		s3, zero							# clear RVA aqrl bits
	jal		skip_whitespace
	mv		s0, a0								# insn string start
	jal		parse_insn_string
	mv		s1, a0								# insn string end

#ifdef ENABLE_RVA
	mv		s2, a1								# ptr to second '.' in string (if present)
	beqz	a1, assemble_instruction_not_aqrl
	# RVA insns may end with ".aq", ".rl", or ".aqrl".
	# Those insns are stored in the encoding table without these extensions.
	# So if one of these extensions is present
	# - assemble the aq/rl bits
	# - set up s1 so that only the part without extension will be used for lookup later
	addi	a0, s2, 1							# advance to char after second dot
	jal		parse_aqrl
	mv		s3, a1
	# set s1 so that the string between s0 and s1 is that part
	# of the insn that does not contain the ".aqrl" extension
	mv		a0, s1
	jal		skip_whitespace
	mv		s1, a0
assemble_instruction_not_aqrl:
#endif /* ENABLE_RVA */

	# find string between s0 and s1 in encoding table
	jal		get_data_by_insn_name
	# function ptr now in a0
	# MATCH value now in a1
	# table entry ptr in a3
	beqz	a0, assemble_instruction_done		# not found
	mv		a0, s1								# input  string ptr
	# current memory addr already in a2
	jal		assemble_GENERIC					# handle all insns
	# now a1 = insn code
	# in case insn == 0, 
	beqz	a1, assemble_instruction_error		# error while assembling insn parameters

#ifdef ENABLE_RVA
	# add RVA aqrl bits if there were any from above
	or		a1, a1, s3
#endif /* ENABLE_RVA */

	# now return insn size in a0
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
	j		pop_s3_s2_s1_s0_ra_ret
.size assemble_instruction, .-assemble_instruction


# in: a0 = absolute target address 
# in: a1 = instruction word
# in: a2 = absolute origin address of the branch instruction
# out: a1 = modified instruction word (0 on error)
assemble_branch_target:
	sub		a0, a0, a2					# compute relative address
	# range check
	li		t1, 4094
	bgt		a0, t1, assemble_branch_target_error
	li		t1, -4096
	blt		a0, t1, assemble_branch_target_error
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


# in: a0 = ptr to remaining input string
# in: a2 = origin address
# in: a3 = ptr to encoding table entry
# out: assembled instruction in a1
assemble_GENERIC:
	addi	sp, sp, -(XLEN_BYTES*6)
	SAVE_X	s4, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	SAVE_X	s1, (XLEN_BYTES*3)(sp)
	SAVE_X	s0, (XLEN_BYTES*4)(sp)
	SAVE_X	ra, (XLEN_BYTES*5)(sp)
	li		s4,	-4							# process max. 4 arguments
	mv		s2, a2
	# assemble instruction word in s1, starting with MATCH value from table
	#if XLEN >= 64
		lwu		s1, ENC_OFF_MATCH(a3)
	#else
		lw		s1, ENC_OFF_MATCH(a3)
	#endif
	# init offset to function pointers into encoding table entry
	add		s3, a3, ENC_OFF_FUNC_ARG1
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
	# check if we have processed 4 arguments already
	addi	s4, s4, 1
	beqz	s4, assemble_GENERIC_done
	# get next function ptr
	addi	s3, s3, 4
	# get function ptr for argument
	#if XLEN >= 64
		lwu		s0, 0(s3)
	#else
		lw		s0, 0(s3)
	#endif
	beqz	s0, assemble_GENERIC_done
	jal		skip_whitespace
	jal		consume_comma
	beqz 	a0, assemble_GENERIC_error
	j 		assemble_GENERIC_next_argument
assemble_GENERIC_error:
	mv		a1, zero
assemble_GENERIC_done:
	j		pop_s4_s3_s2_s1_s0_ra_ret
.size assemble_GENERIC, .-assemble_GENERIC


# facade for assemble_register:
# - add parameter for sll in s3
# - add parameter for lookup function in s4
# - call assemble_register 
ass_rd:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	li		s3, 7						# number of left shifts for rd
	la		s4, get_int_register_index_by_name
	jal		assemble_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	LOAD_X	s4, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_rd, .-ass_rd


# facade for assemble_register:
# - add parameter for sll in s3
# - add parameter for lookup function in s4
# - call assemble_register 
ass_rs1:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	li		s3, 15						# number of left shifts for rs1
	la		s4, get_int_register_index_by_name
	jal		assemble_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	LOAD_X	s4, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_rs1, .-ass_rs1


# facade for assemble_register:
# - add parameter for sll in s3
# - add parameter for lookup function in s4
# - call assemble_register 
ass_rs2:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	li		s3, 20						# number of left shifts for rs2
	la		s4, get_int_register_index_by_name
	jal		assemble_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	LOAD_X	s4, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_rs2, .-ass_rs2


#ifdef ENABLE_RVF
# facade for assemble_register:
# - add parameter for sll in s3
# - add parameter for lookup function in s4
# - call assemble_register 
ass_frd:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	li		s3, 7						# number of left shifts for rd
	la		s4, get_float_register_index_by_name
	jal		assemble_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	LOAD_X	s4, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_frd, .-ass_frd
#endif /* ENABLE_RVF */


#ifdef ENABLE_RVF
# facade for assemble_register:
# - add parameter for sll in s3
# - add parameter for lookup function in s4
# - call assemble_register 
ass_frs1:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	li		s3, 15						# number of left shifts for rs1
	la		s4, get_float_register_index_by_name
	jal		assemble_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	LOAD_X	s4, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_frs1, .-ass_frs1
#endif /* ENABLE_RVF */


#ifdef ENABLE_RVF
# facade for assemble_register:
# - add parameter for sll in s3
# - add parameter for lookup function in s4
# - call assemble_register 
ass_frs2:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	li		s3, 20						# number of left shifts for rs2
	la		s4, get_float_register_index_by_name
	jal		assemble_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	LOAD_X	s4, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_frs2, .-ass_frs2
#endif /* ENABLE_RVF */


#ifdef ENABLE_RVF
# facade for assemble_register:
# - add parameter for sll in s3
# - add parameter for lookup function in s4
# - call assemble_register 
ass_frs3:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	li		s3, 27						# number of left shifts for rs3
	la		s4, get_float_register_index_by_name
	jal		assemble_register
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	LOAD_X	s4, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_frs3, .-ass_frs3
#endif /* ENABLE_RVF */


# We use this for int and float registers, as they are the
# same bits in insns - only the name is different.
# This gets called from the ass_r* functions above.
#
# in: a0 = ptr to first char
# in: a1 = insn word to be modifed
# in: a2 = origin address
# in: s3 = number of slli shifts required (7 for rd, 15 for rs1, 20 for rs2)
# in: s4 = register lookup function ptr
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
assemble_register:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	s2, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s0, (XLEN_BYTES*2)(sp)
	SAVE_X	ra, (XLEN_BYTES*3)(sp)
	mv		s1, a1								# save insn word
	# parse register name
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		s2, a0								# save string end
	mv		a1, a0								# reg name end
	mv		a0, s0								# reg name start
	# now look into either int register table or float register table
	# and get the index of the register back (a0 < 0 on error)
	jalr	s4
	bltz	a0, assemble_register_error
	# register number now in a0
	# assemble into a1
	sll		a0, a0, s3
	or		a1, s1, a0
	j		assemble_register_done
assemble_register_error:
	mv		a1, zero
assemble_register_done:
	addi	a0, s2, 1							# return reg name end +1
	j		pop_s2_s1_s0_ra_ret
.size assemble_register, .-assemble_register


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_BRA:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	s2, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s0, (XLEN_BYTES*2)(sp)
	SAVE_X	ra, (XLEN_BYTES*3)(sp)
	mv		s1, a1						# save insn word
	mv		s0, a2						# save for later
	jal		get_numeric
	# address in a1
	bnez	a2, ass_BRA_error
	mv		s2, a0						# return string ptr later
	# add branch target address to instruction word
	mv		a0, a1						# absolute target address
	mv		a1, s1						# instruction word
	mv		a2, s0						# get saved origin addr back
	jal		assemble_branch_target
	beqz 	a1, ass_BRA_error			# address too far away
	# return a1 and a0
	addi	a0, s2, 1							# string ptr +1
	j		ass_BRA_done
ass_BRA_error:
	mv		a1, zero
ass_BRA_done:
	j		pop_s2_s1_s0_ra_ret
.size ass_BRA, .-ass_BRA


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_I_imm:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_I_imm_error
	li		t0, -2048
	blt		a1, t0, ass_I_imm_error		# numeric too small
	li		t0, 2047
	bgt		a1, t0, ass_I_imm_error		# numeric too big
	mv		s0, a0						# return string ptr later
	# add imm value to instruction word
	mv		a0, a1						# imm value
	mv		a1, s1						# instruction word
	# check funct3 of insn  - are we assembling a shift insn?
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
	addi	a0, s0, 1					# string ptr +1
	j		ass_I_imm_done
ass_I_imm_error:
	mv		a1, zero
ass_I_imm_done:
	j		pop_s1_s0_ra_ret
.size ass_I_imm, .-ass_I_imm


# process I-type and S-type memory-relative parameter
# in the same function
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_MEM:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	jal		get_numeric
	bnez	a2, ass_MEM_error
	li		t0, -2048
	blt		a1, t0, ass_MEM_error		# numeric too small
	li		t0, 2047
	bgt		a1, t0, ass_MEM_error		# numeric too big
	mv		s0, a0						# return string ptr later
	# check if we deal with load or store
	mv		a3, s1
	jal		insn_is_LOAD
	bnez	a4, ass_MEM_load
	jal		insn_is_STORE
	bnez	a4, ass_MEM_store
	j		ass_MEM_rs1
ass_MEM_store:
	# add S-type imm value to instruction word
	slli	t0, a1, 7					# imm4:0 -> bit 7-11
	li		t1, 0b111110000000
	and		t0, t0, t1
	or		s1, s1, t0
	slli	t0,	a1, 20					# imm11:5 -> bit 25-31
	li		t1, 0b11111110000000000000000000000000
	and		t0, t0, t1
	or		s1, s1, t0
	j 		ass_MEM_rs1
ass_MEM_load:
	# add I-type imm value to instruction word
	slli	t0, a1, 20
	or		s1, s1, t0
ass_MEM_rs1:
	# TODO put this into a separate function
	# expect (
	jal		skip_whitespace
	jal		consume_open_paren
	beqz	a0, ass_MEM_error
	jal		skip_whitespace
	# process rs1
	mv		a1, s1
	jal		ass_rs1
	beqz	a1, ass_MEM_error
	mv 		s1, a1
	# expect )
	jal		skip_whitespace
	jal		consume_close_paren
	beqz	a0, ass_MEM_error
	# assemble in a1
	mv		a1, s1
ass_MEM_continue:
	# return a1 and a0
	addi	a0, s0, 1					# string ptr +1
	j		ass_MEM_done
ass_MEM_error:
	mv		a1, zero
ass_MEM_done:
	j		pop_s1_s0_ra_ret
.size ass_MEM, .-ass_MEM


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# in: s3 = number of slli shifts (predecessor=24, sucessor=20)
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_iorw:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	jal		parse_iorw
	# iorw bits in bits 0-3 of a1
	bnez	a2, ass_iorw_error
	mv		s2, a0						# return string ptr later
	# add iorw bits to instruction word
	sll		a1, a1, s3
	or		a1, s1, a1						# instruction word
	j		ass_iorw_done
ass_iorw_error:
	mv		a1, zero
ass_iorw_done:
	LOAD_X	ra, 0(sp)
	LOAD_X	s1, (XLEN_BYTES*1)(sp)
	LOAD_X	s2, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_iorw, .-ass_iorw


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_PRE:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	li		s3, 24						# number of left shifts for predecessor
	jal		ass_iorw
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size ass_PRE, .-ass_PRE


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_SUC:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	li		s3, 20						# number of left shifts for successor
	jal		ass_iorw
	LOAD_X	ra, 0(sp)
	LOAD_X	s3, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size ass_SUC, .-ass_SUC


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_J:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	s2, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s0, (XLEN_BYTES*2)(sp)
	SAVE_X	ra, (XLEN_BYTES*3)(sp)
	mv		s1, a1						# save insn word
	mv		s0, a2						# save origin address
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_J_error
	mv		s2, a0						# return string ptr later
	mv		a0, a1						# imm value
	mv		a1, s1						# instruction word
	# compute from origin address
	sub		a0, a0, s0					# calc offset to target addr
	li		t0, 1048574
	bgt		a0, t0, ass_J_error
	li		t0, -1048576
	blt		a0, t0, ass_J_error
	# add imm value to instruction word
	li		t1, 0b11111111000000000000	# imm19:12
	and		t0, a0, t1
	or		a1, a1, t0
	li		t1, 1 << 11					# imm11
	and		t0, a0, t1
	slli	t0, t0, 9
	or		a1, a1, t0
	andi	t0, a0, 0b11111111110		# imm10:1
	slli	t0, t0, 20
	or		a1, a1, t0
	li		t1, 1<< 20					# imm20
	and		t0, a0, t1
	slli	t0, t0, 11
	or		a1, a1, t0
	# return a1 and a0
	addi	a0, s2, 1					# string ptr +1
	j		ass_J_done
ass_J_error:
	mv		a1, zero
ass_J_done:
	j		pop_s2_s1_s0_ra_ret
.size ass_J, .-ass_J


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_U_imm:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_U_imm_error
	li		t0, 1048576
	bge		a1, t0, ass_U_imm_error
	mv		s0, a0						# return string ptr later
	# add imm value to instruction word
	slli	a1, a1, 12
	or		a1, a1, s1					# return insn in a1
	# return a1 and a0
	addi	a0, s0, 1					# string ptr +1
	j		ass_U_imm_done
ass_U_imm_error:
	mv		a1, zero
ass_U_imm_done:
	j		pop_s1_s0_ra_ret
.size ass_U_imm, .-ass_U_imm


#ifdef ENABLE_RVA
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_aqrl:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	li		t1, '.'						# consume '.'
	lb		t0, 0(a0)
	bne 	t0, t1, ass_aqrl_error
	addi	a0, a0, 1
	jal		parse_aqrl
	or		a1 , s1, a1
	j 		ass_aqrl_done
ass_aqrl_error:
	mv		a1, zero
ass_aqrl_done:
	LOAD_X	ra, 0(sp)
	LOAD_X	s1, (XLEN_BYTES*1)(sp)
	LOAD_X	s2, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_aqrl, .-ass_aqrl
#endif /* ENABLE_RVA */


#ifdef ENABLE_RVA
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_AMEM:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	ra, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	mv		s2, a0						# return string ptr later
	# expect (
	jal		skip_whitespace
	jal		consume_open_paren
	beqz	a0, ass_AMEM_error
	jal		skip_whitespace
	# process rs1
	mv		a1, s1
	jal		ass_rs1
	beqz	a1, ass_AMEM_error
	mv 		s1, a1
	# expect )
	jal		skip_whitespace
	jal		consume_close_paren
	beqz	a0, ass_AMEM_error
	# assemble in a1
	mv		a1, s1
ass_AMEM_continue:
	addi	a0, s2, 1					# string ptr +1
	j		ass_AMEM_done
ass_AMEM_error:
	mv		a1, zero
ass_AMEM_done:
	LOAD_X	ra, 0(sp)
	LOAD_X	s1, (XLEN_BYTES*1)(sp)
	LOAD_X	s2, (XLEN_BYTES*2)(sp)
	addi	sp, sp, (XLEN_BYTES*3)
	ret
.size ass_AMEM, .-ass_AMEM
#endif /* ENABLE_RVA */


#endif /* WITH_CMD_A */
