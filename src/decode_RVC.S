#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_D) && defined (DISASS_RVC)

.global dis_C_rs2
.global dis_C_rda
.global dis_C_rs1a
.global dis_C_rs2a
.global dis_CI_imm
.global dis_CSS_imm
.global dis_CIW_imm
.global dis_CL_imm
.global dis_CS_imm
.global dis_CB_imm
.global dis_CJ_off

.text


/*
# c.add, c.ebreak and c.jalr cannot be correctly identified by MATCH/MASK alone
# so this routine fixes that after calling get_data_by_insn_word
#
# in: instruction word in a0
# in: type-depending decoder routine to call in a1
# in: opcode string in a2
# out: instruction word in a0
# out: type-depending decoder routine to call in a1
# out: opcode string in a2

adjust_RVC_add_jal_ebreak:
	li		t0, 0x9002
	bne		a0, t0, adjust_RVC_add_jal_ebreak_not_ebreak
	# c.ebreak
	la		a1, decode_EMPTY
	la		a2, string_OP_C_EBREAK
	ret
adjust_RVC_add_jal_ebreak_not_ebreak:
	# TODO c.add
	ret
adjust_RVC_add_jal_ebreak_not_add:
	# TODO c.jalr
	ret
adjust_RVC_add_jal_ebreak_done:
	ret
.size adjust_RVC_add_jal_ebreak, .-adjust_RVC_add_jal_ebreak
*/


# in: a0 = instruction word
dis_C_rs2:
	ret
.size dis_C_rs2, .-dis_C_rs2


# in: a0 = instruction word
dis_C_rda:
	ret
.size dis_C_rda, .-dis_C_rda


# in: a0 = instruction word
dis_C_rs1a:
	ret
.size dis_C_rs1a, .-dis_C_rs1a


# in: a0 = instruction word
dis_C_rs2a:
	ret
.size dis_C_rs2a, .-dis_C_rs2a


# in: a0 = instruction word
dis_CI_imm:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	# inst[12] is sign bit
	slli	t0, a0, 19					# shift to bit 31
	#if XLEN >=64
		sext.w	t0, t0					# sign-extend to 64 bits
	#endif	
	# clear all bits to the right of sign bit
	srai	t0, t0, 31					# shift to bit 0
	slli	t0, t0, 5					# shift to final destination
	# inst[6:2] -> imm[4:0]
	srli	t1, a0, 2
	andi	t1, t1, 0b11111
	# join everything
	or		a0, t0, t1
	jal		print_decimal
	j		pop_ra_ret
	ret
.size dis_CI_imm, .-dis_CI_imm


# in: a0 = instruction word
dis_CSS_imm:
	ret
.size dis_CSS_imm, .-dis_CSS_imm


# in: a0 = instruction word
dis_CIW_imm:
	ret
.size dis_CIW_imm, .-dis_CIW_imm


# in: a0 = instruction word
dis_CL_imm:
	ret
.size dis_CL_imm, .-dis_CL_imm


# in: a0 = instruction word
dis_CS_imm:
	ret
.size dis_CS_imm, .-dis_CS_imm


# in: a0 = instruction word
dis_CB_imm:
	ret
.size dis_CB_imm, .-dis_CB_imm


# in: a0 = instruction word
dis_CJ_off:
	ret
.size dis_CJ_off, .-dis_CJ_off


#endif /* (WITH_CMD_D) && defined (DISASS_RVC) */
