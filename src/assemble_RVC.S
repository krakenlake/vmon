#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVC)

.global ass_C_rd_nz
.global ass_C_rs2_nz
.global ass_C_rs2
.global ass_C_rs1a
.global ass_C_rs2a
.global ass_rdsp
.global ass_rdasp
.global ass_C_relsp

.global ass_CI_imm
.global ass_CI_4imm
.global ass_CI_8imm
.global ass_CI_16imm

.global ass_CSS_4imm
.global ass_CSS_8imm
.global ass_CSS_16imm

.global ass_CIW_imm

.global ass_CL_LW_4imm
.global ass_CL_LW_8imm
.global ass_CL_LW_16imm

.global ass_CS_imm
.global ass_C_BRA
.global ass_CJ_off
.global ass_CSS_imm
.global ass_CL_rel
.global ass_C_16sp_imm

.text


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


# in: a0 = ptr to first char
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_C_rd_nz:
	PUSH_TP_S1_S0_RA
	mv		s1, a1								# save insn word
	# parse register name
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		tp, a0								# save string end
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
	addi	a0, tp, 1							# return reg name end +1
	POP_TP_S1_S0_RA_RET
.size ass_C_rd_nz, .-ass_C_rd_nz


# in: a0 = ptr to first char
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_C_rs2_nz:
	PUSH_TP_S1_S0_RA
	mv		s1, a1								# save insn word
	# parse register name
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		tp, a0								# save string end
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
	addi	a0, tp, 1							# return reg name end +1
	POP_TP_S1_S0_RA_RET
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
	PUSH_TP_S1_S0_RA
	mv		s1, a1								# save insn word
	# parse register name
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		tp, a0								# save string end
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
	addi	a0, tp, 1							# return reg name end +1
	POP_TP_S1_S0_RA_RET
.size ass_rdasp, .-ass_rdasp


# accept "(sp)" or "(x2)" and nothing else
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_C_relsp:
	PUSH_TP_S1_S0_RA
	mv		s1, a1								# insn word
	jal		expect_open_paren
	beqz	a0, ass_C_relsp_error
	mv		s0, a0								# save string start
	jal		find_register_name_end
	# end in a0
	mv		tp, a0								# save string end
	mv		a1, a0								# reg name end
	mv		a0, s0								# reg name start
	jal		get_int_register_index_by_name
	li		t0, 2
	bne		a0, t0, ass_C_relsp_error
	addi	a0, tp, 1							# string ptr +1
	jal		expect_close_paren
	beqz	a0, ass_C_relsp_error
	# return a1 and a0
	mv		a1, s1								# return insn unchanged
	j		ass_C_relsp_done
ass_C_relsp_error:
	li		a2, -1
ass_C_relsp_done:
	POP_TP_S1_S0_RA_RET
.size ass_C_relsp, .-ass_C_relsp


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


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CI_4imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 252					# max
	li		a5, 0b11					# alignment
	jal		check_a1_value
	bnez	a2, ass_CI_4imm_error
	# assemble imm from numeric
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
ass_CI_4imm_continue:
	# return a1 and a0
	j		ass_CI_4imm_done
ass_CI_4imm_error:
	li		a2, -1
ass_CI_4imm_done:
	POP_S0_RA_RET
.size ass_CI_4imm, .-ass_CI_4imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CI_8imm:
#if XLEN >= 64
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 504					# max
	li		a5, 0b111					# alignment
	jal		check_a1_value
	bnez	a2, ass_CI_8imm_error
	# assemble imm from numeric
	# offset[8:6] -> insn[4:2]
	andi	t0, a1, 0b111000000
	srli	t0, t0, 4
	# offset[5] -> insn[12]
	andi	t1, a1, 0b100000
	slli	t1, t1, 7
	# offset[4:3] -> insn[6:5]
	andi	t2, a1, 0b11000
	slli	t2, t2, 2
	# put everything together
	or		a1, s0, t0
	or		a1, a1, t1
	or		a1, a1, t2
ass_CI_8imm_continue:
	# return a1 and a0
	j		ass_CI_8imm_done
ass_CI_8imm_error:
	li		a2, -1
ass_CI_8imm_done:
	POP_S0_RA_RET
#else
	ret
#endif
.size ass_CI_8imm, .-ass_CI_8imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CI_16imm:
#if XLEN >= 128
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 1008					# max
	li		a5, 0b1111					# alignment
	jal		check_a1_value
	bnez	a2, ass_CI_16imm_error
	# assemble imm from numeric
	# offset[9:6] -> insn[5:2]
	andi	t0, a1, 0b11110000
	srli	t0, t0, 4
	# offset[5] -> insn[12]
	andi	t1, a1, 0b100000
	slli	t1, t1, 7
	# offset[4] -> insn[6]
	andi	t2, a1, 0b10000
	slli	t2, t2, 2
	# put everything together
	or		a1, s0, t0
	or		a1, a1, t1
	or		a1, a1, t2
ass_CI_16imm_continue:
	# return a1 and a0
	j		ass_CI_16imm_done
ass_CI_16imm_error:
	li		a2, -1
ass_CI_16imm_done:
	POP_S0_RA_RET
#else
	ret
#endif
.size ass_CI_16imm, .-ass_CI_16imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CSS_4imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 252						# max
	li		a5, 0b11					# alignment
	jal		check_a1_value
	bnez	a2, ass_CSS_4imm_error
	# assemble imm from numeric
	andi	t0, a1,	0b11000000
	slli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b111100
	slli	t0, t0, 7
	or		a1, s0, t0
	# return a1 and a0
	j		ass_CSS_4imm_done
ass_CSS_4imm_error:
	li		a2, -1
ass_CSS_4imm_done:
	POP_S0_RA_RET
.size ass_CSS_4imm, .-ass_CSS_4imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CSS_8imm:
#if XLEN >= 64	
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 504						# max
	li		a5, 0b111					# alignment
	jal		check_a1_value
	bnez	a2, ass_CSS_8imm_error
	# assemble imm from numeric
	andi	t0, a1,	0b111000000
	slli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b111000
	slli	t0, t0, 7
	or		a1, s0, t0
	# return a1 and a0
	j		ass_CSS_8imm_done
ass_CSS_8imm_error:
	li		a2, -1
ass_CSS_8imm_done:
	POP_S0_RA_RET
#else
	ret
#endif
.size ass_CSS_8imm, .-ass_CSS_8imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CSS_16imm:
#if XLEN >= 128
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 1008					# max
	li		a5, 0b1111					# alignment
	jal		check_a1_value
	bnez	a2, ass_CSS_16imm_error
	# assemble imm from numeric
	andi	t0, a1,	0b1111000000
	slli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b110000
	slli	t0, t0, 7
	or		a1, s0, t0
	# return a1 and a0
	j		ass_CSS_16imm_done
ass_CSS_16imm_error:
	li		a2, -1
ass_CSS_16imm_done:
	POP_S0_RA_RET
#else
	ret
#endif
.size ass_CSS_16imm, .-ass_CSS_16imm


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
	or		s0, s0, t0
	andi	t0, a1, 0b100
	slli	t0, t0, 4
	or		s0, s0, t0
	andi	t0, a1, 0b1111000000
	slli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b110000
	slli	t0, t0, 7
	or		a1, s0, t0
	# return a1 and a0
	j		ass_CIW_imm_done
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
ass_CL_LW_4imm:
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 124						# max
	li		a5, 0b11					# alignment
	jal		check_a1_value
	bnez	a2, ass_CL_LW_4imm_error
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
	# return a1 and a0
	j		ass_CL_LW_4imm_done
ass_CL_LW_4imm_error:
	li		a2, -1
ass_CL_LW_4imm_done:
	POP_S0_RA_RET
.size ass_CL_LW_4imm, .-ass_CL_LW_4imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CL_LW_8imm:
#if XLEN >= 64	
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 248						# max
	li		a5, 0b111					# alignment
	jal		check_a1_value
	bnez	a2, ass_CL_LW_8imm_error
	# assemble imm from numeric
	andi	t0, a1,0b111000
	slli	t0, t0, 7
	andi	t1, a1, 0b11000000
	srli	t1, t1, 1
	or		a1, s0, t0					# from saved insn
	or		a1, a1, t1
	# return a1 and a0
	j		ass_CL_LW_8imm_done
ass_CL_LW_8imm_error:
	li		a2, -1
ass_CL_LW_8imm_done:
	POP_S0_RA_RET
#else
	ret
#endif
.size ass_CL_LW_8imm, .-ass_CL_LW_8imm


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CL_LW_16imm:
#if XLEN >= 128
	PUSH_S0_RA
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	li		a3, 0						# min
	li		a4, 496						# max
	li		a5, 0b1111					# alignment
	jal		check_a1_value
	bnez	a2, ass_CL_LW_16imm_error
	# assemble imm from numeric
	andi	t0, a1,0b110000
	slli	t0, t0, 7
	andi	t1, a1, 0b100000000
	slli	t1, t1, 2
	andi	t2, a1, 0b11000000
	srli	t2, t2, 1
	or		a1, s0, t0					# from saved insn
	or		a1, a1, t1
	or		a1, a1, t2
	# return a1 and a0
	j		ass_CL_LW_16imm_done
ass_CL_LW_16imm_error:
	li		a2, -1
ass_CL_LW_16imm_done:
	POP_S0_RA_RET
#else
	ret
#endif
.size ass_CL_LW_16imm, .-ass_CL_LW_16imm


# process I-type register-relative parameter
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = modified instruction word
# out: a2 = -1 on error
ass_CL_rel:
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
	or		s0, s0, t0
	and		t0, a1, 0b110
	slli	t0, t0, 2
	or		s0, s0, t0
	andi	t0, a1, 0b11000000
	srli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b11000
	slli	t0, t0, 7
	or		s0, s0, t0
	andi	t0, a1, 0b100000000
	slli	t0, t0, 4
	or		a1, s0, t0
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
	or		s0, s0, t0
	andi	t0, a1, 0b1110
	slli	t0, t0, 2
	or		s0, s0, t0
	li		t1, 0b101101000000
	and		t0, a1, t1
	slli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b10000000
	srli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b10000000000
	srli	t0, t0, 2
	or		s0, s0, t0
	andi	t0, a1, 0b10000
	slli	t0, t0, 7
	or		a1, s0, t0
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
	or		s0, s0, t0
	andi	t0, a1, 0b110000000
	srli	t0, t0, 4
	or		s0, s0, t0
	andi	t0, a1, 0b1000000
	srli	t0, t0, 1
	or		s0, s0, t0
	andi	t0, a1, 0b10000
	slli	t0, t0, 2
	or		s0, s0, t0
	andi	t0, a1, 0b1000000000
	slli	t0, t0, 3
	or		a1, s0, t0
	j		ass_C_16sp_imm_done
ass_C_16sp_imm_error:
	li		a2, -1
ass_C_16sp_imm_done:
	POP_S0_RA_RET
.size ass_C_16sp_imm, .-ass_C_16sp_imm


#endif /* defined (WITH_CMD_A) && defined (DISASS_RVD) */
