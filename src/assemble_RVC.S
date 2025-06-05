#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVC)

.global ass_C_rs2
.global ass_C_rda
.global ass_C_rs1a
.global ass_C_rs2a
.global ass_CI_imm
.global ass_CSS_imm
.global ass_CIW_imm
.global ass_CL_imm
.global ass_CS_imm
.global ass_CB_imm
.global ass_CJ_off
.global ass_CI_4imm
.global ass_CSS_imm
.global ass_CL_rel


.text


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_C_rs2:
	li		t0, 2
	la		t1, get_int_register_index_by_name
	j		assemble_register
.size ass_C_rs2, .-ass_C_rs2


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_C_rs1a:
	li		t0, 7
	la		t1, get_int_register_index_by_name
	j		assemble_C_register					# NOT all registers allowed
.size ass_C_rs1a, .-ass_C_rs1a


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_C_rs2a:
	li		t0, 2
	la		t1, get_int_register_index_by_name
	j		assemble_C_register					# NOT all registers allowed
.size ass_C_rs2a, .-ass_C_rs2a


# We use this for C rd'/rs1'/rs2' registers ONLY.
# This gets called from the ass_C_r* functions above.
#
# in: a0 = ptr to first char
# in: a1 = insn word to be modifed
# in: a2 = origin address
# in: t0 = number of slli shifts required (7 for rd, 15 for rs1, 20 for rs2)
# in: t1 = register lookup function ptr
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
assemble_C_register:
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
	bltz	a0, assemble_C_register_error
	# register number now in a0
	li		t0, 8								# 8 <= rda/rs1a/rs2 <=15
	blt		a0, t0, assemble_C_register_error 
	li		t0, 15
	bgt		a0, t0, assemble_C_register_error
	# assemble into a1
	addi	a0, a0, -8							# convert to RVC register number
	sll		a0, a0, s3							# shift into place
	or		a1, s1, a0							# join with a1
	j		assemble_C_register_done
assemble_C_register_error:
	mv		a1, zero
assemble_C_register_done:
	addi	a0, s2, 1							# return reg name end +1
	j		pop_s4_s3_s2_s1_s0_ra_ret
.size assemble_C_register, .-assemble_C_register


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CI_imm:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_CI_imm_error
	li		t0, -32
	blt		a1, t0, ass_CI_imm_error	# numeric too small
	li		t0, 31
	bgt		a1, t0, ass_CI_imm_error	# numeric too big	
	# assemble imm from numeric
	slli	t0, a1, 2
	andi	t0, t0, 0b1111100	
	li		t1, 1
	slli	t1, t1, 12
	and		t1, t1, a1
	# add imm to insn
	or		a1, s0, t0
	or		a1, a1, t1
ass_CI_imm_continue:
	# return a1 and a0
	j		ass_CI_imm_done
ass_CI_imm_error:
	mv		a1, zero
ass_CI_imm_done:
	j		pop_s0_ra_ret
.size ass_CI_imm, .-ass_CI_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CI_4imm:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_CI_4imm_error
	bltz	a1, ass_CI_4imm_error		# numeric too small
	li		t0, 252
	bgt		a1, t0, ass_CI_4imm_error	# numeric too big	
	andi	t0, a1, 0b11
	bnez	t0, ass_CI_4imm_error		# numeric not 4-byte aligned	
	# assemble imm from numeric
	andi	t0, a1, 0b1111100	
	slli	t1, a1, 5
	li		t2, 1
	slli	t2, t2, 12
	and		t1, t1, t2
	# add imm to insn
	or		a1, s0, t0
	or		a1, a1, t1
ass_CI_4imm_continue:
	# return a1 and a0
	j		ass_CI_4imm_done
ass_CI_4imm_error:
	mv		a1, zero
ass_CI_4imm_done:
	j		pop_s0_ra_ret
.size ass_CI_4imm, .-ass_CI_4imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CSS_imm:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_CSS_imm_error
	bltz	a1, ass_CSS_imm_error		# numeric too small
	li		t0, 252
	bgt		a1, t0, ass_CSS_imm_error	# numeric too big	
	andi	t0, a1, 0b11
	bnez	t0, ass_CSS_imm_error		# numeric not 4-byte aligned	
	# assemble imm from numeric
	andi	t0, a1,	0b11000000			# offset[7:6]
	slli	t0, t0, 1					# -> imm[7:8]
	or		s0, s0, t0
	andi	t0, a1, 0b111100			# offset[5:2] 
	slli	t0, t0, 7					# -> imm[12:9]
	or		a1, s0, t0
ass_CSS_imm_continue:
	# return a1 and a0
	j		ass_CSS_imm_done
ass_CSS_imm_error:
	mv		a1, zero
ass_CSS_imm_done:
	j		pop_s0_ra_ret
.size ass_CSS_imm, .-ass_CSS_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CIW_imm:
	# accept only x8-15
	ret
.size ass_CIW_imm, .-ass_CIW_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CL_imm:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_CL_imm_error
	li		t0, -64
	blt		a1, t0, ass_CL_imm_error	# numeric too small
	li		t0, 60
	bgt		a1, t0, ass_CL_imm_error	# numeric too big	
	# assemble imm from numeric
	andi	t0, a1, 0b11
	slli	t0, t0, 5
	or		s0, s0, t0
	andi	t0, a1, 0b11100
	slli	t0,t0, 7
	or		a1, s0, t0
ass_CL_imm_continue:
	# return a1 and a0
	j		ass_CL_imm_done
ass_CL_imm_error:
	mv		a1, zero
ass_CL_imm_done:
	j		pop_s0_ra_ret
.size ass_CL_imm, .-ass_CL_imm


# process I-type register-relative parameter
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CL_rel:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	mv		s0, a0						# return string ptr later
	mv		s1, a1						# insn word
	jal		expect_open_paren
	beqz	a0, ass_CL_rel_error
	# process rs1
	mv		a1, s1
	jal		ass_C_rs1a
	beqz	a1, ass_CL_rel_error
	mv 		s1, a1
	jal		expect_close_paren
	beqz	a0, ass_CL_rel_error
	# assemble in a1
	mv		a1, s1
ass_CL_rel_continue:
	# return a1 and a0
	addi	a0, s0, 1					# string ptr +1
	j		ass_CL_rel_done
ass_CL_rel_error:
	mv		a1, zero
ass_CL_rel_done:
	j		pop_s1_s0_ra_ret
.size ass_CL_rel, .-ass_CL_rel


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CB_imm:
	# accept only x8-15
	ret
.size ass_CB_imm, .-ass_CB_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CJ_off:
	ret
.size ass_CJ_off, .-ass_CJ_off


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_CA_imm:
	# accept only x8-15
	ret
.size ass_CA_imm, .-ass_CA_imm


#endif /* defined (WITH_CMD_A) && defined (DISASS_RVD) */
