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
.global dis_CI_4imm
.global dis_CSS_imm
.global dis_CL_rel

.text


# in: a0 = instruction word
dis_C_rs2:
	srli	a0, a0, 2
	j		print_int_register_name
.size dis_C_rs2, .-dis_C_rs2


# in: a0 = instruction word
dis_C_rda:
	ret
.size dis_C_rda, .-dis_C_rda


# in: a0 = instruction word
dis_C_rs1a:
	# todo
	ret
.size dis_C_rs1a, .-dis_C_rs1a


# in: a0 = instruction word
dis_C_rs2a:
	# todo
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
.size dis_CI_imm, .-dis_CI_imm


# in: a0 = instruction word
dis_CI_4imm:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	# insn[6:4] -> offset[4:2]
	srli	t0, a0, 2
	andi	t0, t0, 0b11100
	# insn[12] -> offset[5]
	srli	t1, a0, 7
	andi	t1, t1, 0b100000
	# insn[3:2] -> offset[7:6]
	slli	t2, a0, 4
	andi	t2, t2, 0b11000000
	# put everything together
	or		a0, t0, t1
	or		a0, a0, t2
	jal		print_decimal
	j		pop_ra_ret
.size dis_CI_4imm, .-dis_CI_4imm


# in: a0 = instruction word
dis_CSS_imm:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	srli	t0, a0, 7
	andi	t0, t0, 0b111100
	srli	t1, a0, 1
	andi	t1, t1, 0b11000000
	or		a0, t0, t1
	jal		print_decimal
	j		pop_ra_ret
.size dis_CSS_imm, .-dis_CSS_imm


# in: a0 = instruction word
dis_CIW_imm:
	ret
.size dis_CIW_imm, .-dis_CIW_imm


# in: a0 = instruction word
dis_CL_imm:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)

	srli	t0, a0, 3
	andi	t0, a0, 0b1100

	srli	t1, a0, 6
	andi	t1, t1, 0b1110000




	#if XLEN >=64
		sext.w	t0, t0					# sign-extend to 64 bits
	#endif	

	# join everything
	or		a0, t0, t1
	jal		print_decimal
	j		pop_ra_ret
.size dis_CL_imm, .-dis_CL_imm


# in: a0 = instruction word
dis_CB_imm:
	ret
.size dis_CB_imm, .-dis_CB_imm


# in: a0 = instruction word
dis_CJ_off:
	ret
.size dis_CJ_off, .-dis_CJ_off


# in: a0 = instruction word
dis_CA_imm:
	ret
.size dis_CA_imm, .-dis_CA_imm


# in: instruction word in a0
dis_CL_rel:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	a0, (XLEN_BYTES*1)(sp)
	li		a0, '('
	jal		print_char
	LOAD_X	a0, (XLEN_BYTES*1)(sp)
	jal		dis_C_rs1a
	li		a0, ')'
	jal		print_char
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size dis_CL_rel, .-dis_CL_rel


#endif /* (WITH_CMD_D) && defined (DISASS_RVC) */
