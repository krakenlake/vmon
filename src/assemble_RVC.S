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
ass_C_rda:
	ret
.size ass_C_rda, .-ass_C_rda


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_C_rs1a:
	ret
.size ass_C_rs1a, .-ass_C_rs1a


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_C_rs2a:
	ret
.size ass_C_rs2a, .-ass_C_rs2a


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
	ret
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
ass_CS_imm:
	# accept only x8-15
	ret
.size ass_CL_imm, .-ass_CL_imm


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
