#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#ifdef WITH_CMD_A

.global assemble_register

# these are called via assemble_GENERIC
.global ass_rd							# expect int register name and use it for rd
.global ass_rs1							# expect int register name and use it for rs1
.global ass_rs2							# expect int register name and use it for rs2
.global ass_BRA							# expect branch target address in hex
.global ass_I_imm						# expect immediate for I-type AND/ADD/OR/XOR in dec
.global ass_I_shift						# expect immediate for I-type shifts in dec
.global ass_PRE							# expect iorw predecessor parameter for fence
.global ass_SUC							# expect iorw sucessor parameter for fence
.global ass_J							# expect J-type address
.global ass_I_rel						# expect I-type offset for JALR
.global ass_S_imm						# expect S-type offset for store
.global ass_U_imm						# expect immediate for U-type (LUI/AUIPC)

.text


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


# process I-type register-relative parameter
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_I_rel:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	mv		s0, a0						# return string ptr later
	mv		s1, a1						# insn word
	jal		expect_open_paren
	beqz	a0, ass_I_rel_error
	# process rs1
	mv		a1, s1
	jal		ass_rs1
	beqz	a1, ass_I_rel_error
	mv 		s1, a1
	jal		expect_close_paren
	beqz	a0, ass_I_rel_error
	# assemble in a1
	mv		a1, s1
ass_I_rel_continue:
	# return a1 and a0
	addi	a0, s0, 1					# string ptr +1
	j		ass_I_rel_done
ass_I_rel_error:
	mv		a1, zero
ass_I_rel_done:
	j		pop_s1_s0_ra_ret
.size ass_I_rel, .-ass_I_rel


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_rd:
	li		t0, 7
	la		t1, get_int_register_index_by_name
	j		assemble_register
.size ass_rd, .-ass_rd


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_rs1:
	li		t0, 15
	la		t1, get_int_register_index_by_name
	j		assemble_register
.size ass_rs1, .-ass_rs1


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_rs2:
	li		t0, 20
	la		t1, get_int_register_index_by_name
	j		assemble_register
.size ass_rs2, .-ass_rs2


# We use this for int and float registers, as they are the
# same bits in insns - only the name is different.
# This gets called from the ass_r* functions above.
#
# in: a0 = ptr to first char
# in: a1 = insn word to be modifed
# in: a2 = origin address
# in: t0 = number of slli shifts required (7 for rd, 15 for rs1, 20 for rs2)
# in: t1 = register lookup function ptr
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
assemble_register:
	addi	sp, sp, -(XLEN_BYTES*6)
	SAVE_X	s4, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	SAVE_X	s1, (XLEN_BYTES*3)(sp)
	SAVE_X	s0, (XLEN_BYTES*4)(sp)
	SAVE_X	ra, (XLEN_BYTES*5)(sp)
	mv		s3, t0
	mv		s4, t1
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
	j		pop_s4_s3_s2_s1_s0_ra_ret
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
	mv		a0, s0
	j		ass_I_imm_done
ass_I_imm_error:
	mv		a1, zero
ass_I_imm_done:
	j		pop_s1_s0_ra_ret
.size ass_I_imm, .-ass_I_imm


# process S-type offset parameter
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_S_imm:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	jal		get_numeric
	bnez	a2, ass_S_rel_error
	li		t0, -2048
	blt		a1, t0, ass_S_rel_error		# numeric too small
	li		t0, 2047
	bgt		a1, t0, ass_S_rel_error		# numeric too big
	# add S-type imm value to instruction word
	slli	t0, a1, 7					# imm4:0 -> bit 7-11
	li		t1, 0b111110000000
	and		t0, t0, t1
	or		s0, s0, t0
	slli	t0,	a1, 20					# imm11:5 -> bit 25-31
	li		t1, 0b11111110000000000000000000000000
	and		t0, t0, t1
	or		s0, s0, t0
	# assemble in a1
	mv		a1, s0
ass_S_rel_continue:
	# return a1 and a0
	j		ass_S_rel_done
ass_S_rel_error:
	mv		a1, zero
ass_S_rel_done:
	j		pop_s0_ra_ret
.size ass_S_imm, .-ass_S_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# in: t0 = number of slli shifts (predecessor=24, sucessor=20)
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_iorw:
	addi	sp, sp, -(XLEN_BYTES*4)
	SAVE_X	s2, 0(sp)
	SAVE_X	s1, (XLEN_BYTES*1)(sp)
	SAVE_X	s0, (XLEN_BYTES*2)(sp)
	SAVE_X	ra, (XLEN_BYTES*3)(sp)
	mv		s0, t0						# shift value from ass_PRE or ass_SUC
	mv		s1, a1						# save insn word
	jal		parse_iorw
	# iorw bits in bits 0-3 of a1
	bnez	a2, ass_iorw_error
	mv		s2, a0						# return string ptr later
	# add iorw bits to instruction word
	sll		a1, a1, s0
	or		a1, s1, a1						# instruction word
	j		ass_iorw_done
ass_iorw_error:
	mv		a1, zero
ass_iorw_done:
	j		pop_s2_s1_s0_ra_ret
.size ass_iorw, .-ass_iorw


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_PRE:
	li		t0, 24
	j		ass_iorw
.size ass_PRE, .-ass_PRE


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_SUC:
	li		t0, 20
	j		ass_iorw
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


#endif /* WITH_CMD_A */
