#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVC)

.global ass_C_rd_nz
.global ass_C_rs2
.global ass_C_rs2_nz
.global ass_C_rda
.global ass_C_rs1a
.global ass_C_rs2a
.global ass_CI_imm
.global ass_CSS_imm
.global ass_CIW_imm
.global ass_CL_LW_imm
.global ass_CS_imm
.global ass_CB_imm
.global ass_C_BRA
.global ass_CJ_off
.global ass_CI_4imm
.global ass_CI_8imm
.global ass_CI_16imm
.global ass_CSS_imm
.global ass_CL_rel
.global ass_rdsp
.global ass_rdasp
.global ass_C_16sp_imm

.text


# in: a0 = ptr to first char
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_C_rd_nz:
	PUSH_S2_S1_S0_RA
	mv		s1, a1								# save insn word
	# parse register name
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		s2, a0								# save string end
	mv		a1, a0								# reg name end
	mv		a0, s0								# reg name start
	# now look into int register table
	# and get the index of the register back (a0 < 0 on error)
	jal		get_int_register_index_by_name
	blez	a0, ass_C_rd_nz_error			# register zero also not allowed
	# register number now in a0
	# assemble into a1
	sll		a0, a0, 7
	or		a1, s1, a0
	j		ass_C_rd_nz_done
ass_C_rd_nz_error:
	li		a2, -1
ass_C_rd_nz_done:
	addi	a0, s2, 1							# return reg name end +1
	POP_S2_S1_S0_RA_RET
.size ass_C_rd_nz, .-ass_C_rd_nz


# in: a0 = ptr to first char
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_C_rs2_nz:
	PUSH_S2_S1_S0_RA
	mv		s1, a1								# save insn word
	# parse register name
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		s2, a0								# save string end
	mv		a1, a0								# reg name end
	mv		a0, s0								# reg name start
	# now look into int register table
	# and get the index of the register back (a0 < 0 on error)
	jal		get_int_register_index_by_name
	blez	a0, ass_C_rs2_nz_error			# register zero also not allowed
	# register number now in a0
	# assemble into a1
	sll		a0, a0, 7
	or		a1, s1, a0
	j		ass_C_rs2_nz_done
ass_C_rs2_nz_error:
	li		a2, -1
ass_C_rs2_nz_done:
	addi	a0, s2, 1							# return reg name end +1
	POP_S2_S1_S0_RA_RET
.size ass_C_rs2_nz, .-ass_C_rs2_nz


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
ass_C_rs2:
	li		t0, 2
	la		t1, get_int_register_index_by_name
	j		assemble_register
.size ass_C_rs2, .-ass_C_rs2


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
ass_C_rs1a:
	li		t0, 7
	la		t1, get_int_register_index_by_name
	j		assemble_C_register					# NOT all registers allowed
.size ass_C_rs1a, .-ass_C_rs1a


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
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
# out: a1 = modified instruction word
# out: a2 = -1 on error
assemble_C_register:
	PUSH_S4_S3_S2_S1_S0_RA
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
	li		t0, 8								# 8 <= rda/rs1a/rs2a <=15
	blt		a0, t0, assemble_C_register_error 
	li		t0, 15
	bgt		a0, t0, assemble_C_register_error
	# assemble into a1
	addi	a0, a0, -8							# convert to RVC register number
	sll		a0, a0, s3							# shift into place
	or		a1, s1, a0							# join with a1
	j		assemble_C_register_done
assemble_C_register_error:
	li		a2, -1
assemble_C_register_done:
	addi	a0, s2, 1							# return reg name end +1
	POP_S4_S3_S2_S1_S0_RA_RET
.size assemble_C_register, .-assemble_C_register


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CI_imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, -32						# min
	li		a4, 31						# max
	li		a5, 0						# alignment
	jal		check_a1_value
	bnez	a2, ass_CI_imm_error
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
	li		a2, -1
ass_CI_imm_done:
	POP_S0_RA_RET
.size ass_CI_imm, .-ass_CI_imm


# c.lwsp facade for ass_CI_lXsp
ass_CI_4imm:
	li		t0, 0
	li		t1, 0b11
	j		ass_CI_lXsp
.size ass_CI_4imm, .-ass_CI_4imm
ass_CI_8imm:
	li		t0, 1
	li		t1, 0b111
	j		ass_CI_lXsp
.size ass_CI_8imm, .-ass_CI_8imm
ass_CI_16imm:
	li		t0, 2
	li		t1, 0b1111
	j		ass_CI_lXsp
.size ass_CI_16imm, .-ass_CI_16imm
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# in: t0 = shift value (0 for LWSP, 1 for LDSP, 2 for LQSP)
# in: t1 = alignment bitmask (0b11 for LWSP, 0b111 for LDSP, 0b1111 for LQSP)
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CI_lXsp:
	PUSH_S2_S1_S0_RA
	mv		s2, t1						# save shift value
	mv		s1, t0						# save shift value
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_CI_lXsp_error
	bltz	a1, ass_CI_lXsp_error		# numeric too small
	li		t0, 252
	sll		t0, t0, s1					# c.lwsp/c.ldsp/c.lqsp adjustment shift
	bgt		a1, t0, ass_CI_lXsp_error	# numeric too big	
	# check for numberic for proper alignment
	and		t0, a1, s2					# bitmask for 16imm alignment
	bnez	t0, ass_CI_lXsp_error		# numeric not 4/8/16 byte aligned, depending on s1
	# assemble imm from numeric
	srl		a1, a1, s1					# c.lwsp/c.ldsp/c.lqsp adjustment shift
	# offset[7:6] -> insn[3:2]
	andi	t0, a1, 0b11000000
	srli	t0, t0, 4
	# offset[5] -> insn[12]
	andi	t1, a1, 0b100000
	slli	t1, t1, 7
	# offset[4:2] -> insn[6:4]
	andi	t2, a1, 0b11100
	slli	t2, t2, 2
	# put everything together
	or		a1, s0, t0
	or		a1, a1, t1
	or		a1, a1, t2
ass_CI_lXsp_continue:
	# return a1 and a0
	j		ass_CI_lXsp_done
ass_CI_lXsp_error:
	li		a2, -1
ass_CI_lXsp_done:
	POP_S2_S1_S0_RA_RET
.size ass_CI_lXsp, .-ass_CI_lXsp



# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CSS_imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 252						# max
	li		a5, 0b11					# alignment
	jal		check_a1_value
	bnez	a2, ass_CSS_imm_error
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
	li		a2, -1
ass_CSS_imm_done:
	POP_S0_RA_RET
.size ass_CSS_imm, .-ass_CSS_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CIW_imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 4						# min
	li		a4, 512						# max
	li		a5, 0b11					# alignment
	jal		check_a1_value
	bnez	a2, ass_CIW_imm_error
	# assemble imm from numeric
	andi	t0, a1,	0b1000
	slli	t0, t0, 2
	andi	t1, a1, 0b100
	slli	t1, t1, 4
	andi	t2, a1, 0b1111000000
	slli	t2, t2, 1
	andi	t3, a1, 0b110000
	slli	t3, t3, 7
	or		a1, s0, t0					# from saved insn
	or		a1, a1, t1
	or		a1, a1, t2
	or		a1, a1, t3
ass_CIW_imm_continue:
	# return a1 and a0
	j		ass_CSS_imm_done
ass_CIW_imm_error:
	li		a2, -1
ass_CIW_imm_done:
	POP_S0_RA_RET
.size ass_CIW_imm, .-ass_CIW_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CL_LW_imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 124						# max
	li		a5, 0b11					# alignment
	jal		check_a1_value
	bnez	a2, ass_CL_LW_imm_error
	# assemble imm from numeric
	andi	t0, a1,0b111000
	slli	t0, t0, 7
	andi	t1, a1, 0b1000000
	srli	t1, t1, 1
	andi	t2, a1, 0b100
	slli	t2, t2, 4
	or		a1, s0, t0					# from saved insn
	or		a1, a1, t1
	or		a1, a1, t2
ass_CL_LW_imm_continue:
	# return a1 and a0
	j		ass_CL_LW_imm_done
ass_CL_LW_imm_error:
	li		a2, -1
ass_CL_LW_imm_done:
	POP_S0_RA_RET
.size ass_CL_LW_imm, .-ass_CL_LW_imm


# process I-type register-relative parameter
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CL_rel:
ass_CS_rel:
	PUSH_S1_S0_RA
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
	li		a2, -1
ass_CL_rel_done:
	POP_S1_S0_RA_RET
.size ass_CL_rel, .-ass_CL_rel


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CB_imm:
	# accept only x8-15
	ret
.size ass_CB_imm, .-ass_CB_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_C_BRA:
	PUSH_S1_S0_RA
	mv		s0, a1						# save insn word
	mv		s1, a2						# save insn word
	jal		get_numeric
	# subtract origin address
	sub		a1, a1, s1
	# imm  value in a1
	li		a3, -256					# min
	li		a4, 254						# max
	li		a5, 0b1						# alignment
	jal		check_a1_value
	bnez	a2, ass_C_BRA_error
	# assemble bits
	andi	t0, a1, 0b100000
	srli	t0, t0, 3
	and		t1, a1, 0b110
	slli	t1, t1, 2
	andi	t2, a1, 0b11000000
	srli	t2, t2, 1
	andi	t3, a1, 0b11000
	slli	t3, t3, 7
	andi	t4, a1, 0b100000000
	slli	t4, t4, 4
	or		a1, s0, t0
	or		a1, a1, t1
	or		a1, a1, t2
	or		a1, a1, t3
	or		a1, a1, t4
	j		ass_C_BRA_done
ass_C_BRA_error:
	li		a2, -1
ass_C_BRA_done:
	POP_S1_S0_RA_RET
.size ass_C_BRA, .-ass_C_BRA


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CJ_off:
	PUSH_S1_S0_RA
	mv		s0, a1						# save insn word
	mv		s1, a2						# save origin address
	jal		get_numeric
	# subtract origin address
	sub		a1, a1, s1
	# imm  value in a1
	li		a3, -2048					# min
	li		a4, 2046					# max
	li		a5, 0b1						# alignment
	jal		check_a1_value
	bnez	a2, ass_CJ_off_error
	# assemble bits
	andi	t0, a1, 0b100000
	srli	t0, t0, 3
	andi	t1, a1, 0b1110
	slli	t1, t1, 2
	li		t3, 0b101101000000
	and		t2, a1, t3
	slli	t2, t2, 1
	andi	t3, a1, 0b10000000
	srli	t3, t3, 1
	andi	t4, a1, 0b10000000000
	srli	t4, t4, 2
	andi	t5, a1, 0b10000
	slli	t5, t5, 7
	or		a1, s0, t0
	or		a1, a1, t1
	or		a1, a1, t2
	or		a1, a1, t3
	or		a1, a1, t4
	or		a1, a1, t5
	# return a1 and a0
	j		ass_CJ_off_done
ass_CJ_off_error:
	li		a2, -1
ass_CJ_off_done:
	POP_S1_S0_RA_RET
.size ass_CJ_off, .-ass_CJ_off


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CA_imm:
	# accept only x8-15
	ret
.size ass_CA_imm, .-ass_CA_imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_rdsp:
	PUSH_RA
	jal		ass_C_rd_nz
	# check if rd==2 now in insn word
	srli	t0, a1, 7					
	andi	t0, t0, 0b11111
	li		t1, 2
	beq		t0, t1, ass_rdsp_done
ass_rdsp_eror:
	li		a2, -1
ass_rdsp_done:
	POP_RA_RET
.size ass_rdsp, .-ass_rdsp


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_rdasp:
	PUSH_S2_S1_S0_RA
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
	jal		get_int_register_index_by_name
	li		t0, 2								# accept only sp as register name
	bne		a0, t0, ass_rdasp_error
	# assemble nothing (this function is only used for c.addi4spn)
	mv		a1, s1
	j		ass_rdasp_done
ass_rdasp_error:
	li		a2, -1
ass_rdasp_done:
	addi	a0, s2, 1							# return reg name end +1
	POP_S2_S1_S0_RA_RET
.size ass_rdasp, .-ass_rdasp


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_C_16sp_imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, -512					# min
	li		a4, 496						# max
	li		a5, 0b1111					# alignment
	jal		check_a1_value
	bnez	a2, ass_C_16sp_imm_error
	andi	t0, a1, 0b100000
	srli	t0, t0, 3
	andi	t1, a1, 0b110000000
	srli	t1, t1, 4
	andi	t2, a1, 0b1000000
	srli	t2, t2, 1
	andi	t3, a1, 0b10000
	slli	t3, t3, 2
	andi	t4, a1, 0b1000000000
	slli	t4, t4, 3
	or		a1, s0, t0
	or		a1, a1, t1
	or		a1, a1, t2
	or		a1, a1, t3
	or		a1, a1, t4
	j		ass_C_16sp_imm_done
ass_C_16sp_imm_error:
	li		a2, -1
ass_C_16sp_imm_done:
	POP_S0_RA_RET
.size ass_C_16sp_imm, .-ass_C_16sp_imm


#endif /* defined (WITH_CMD_A) && defined (DISASS_RVD) */
