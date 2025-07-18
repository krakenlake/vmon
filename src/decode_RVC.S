#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#if defined (WITH_CMD_D) && defined (DISASS_RVC)

.global dis_C_rs2
.global dis_C_rda
.global dis_C_rs1a
.global dis_C_rs2a
.global dis_C_rdasp
.global dis_C_relsp

.global dis_CI_imm
.global dis_CI_4imm
.global dis_CI_8imm
.global dis_CI_16imm

.global dis_CSS_4imm
.global dis_CSS_8imm
.global dis_CSS_16imm

.global dis_CIW_imm

.global dis_CL_LW_4imm
.global dis_CL_LW_8imm
.global dis_CL_LW_16imm

.global dis_CS_imm
.global dis_C_BRA
.global dis_CJ_off
.global dis_CSS_imm
.global dis_CL_rel
.global dis_C_16sp_imm

.text


# in: a0 = instruction word
dis_C_rs1a:
dis_C_rda:
	srli	a0, a0, 7
	j		dis_C_rega
.size dis_C_rs1a, .-dis_C_rs1a


# in: a0 = instruction word
dis_C_rs2:
	srli	a0, a0, 2
	j		print_int_register_name
.size dis_C_rs2, .-dis_C_rs2


# in: a0 = instruction word
dis_C_rs2a:
	srli	a0, a0, 2
	j		dis_C_rega
.size dis_C_rs2a, .-dis_C_rs2a


# in: a0 = instruction word
dis_C_rega:
	andi	a0, a0, 0b111				# reg' bits
	addi	a0, a0, 8					# reg' registers start from x8
	j		print_int_register_name
.size dis_C_rega, .-dis_C_rega


# in: a0 = instruction word
dis_C_rdasp:
	PUSH_RA
	li		a0, 2
	jal		get_int_register_name_by_index
	jal		print_string
	POP_RA_RET
.size dis_C_rs2, .-dis_C_rs2


# in: a0 = instruction word
dis_C_relsp:
	PUSH_RA
	li		a0, '('
	jal		print_char
	li		a0, 2
	jal		get_int_register_name_by_index
	jal		print_string
	li		a0, ')'
	jal		print_char
	POP_RA_RET
.size dis_C_relsp, .-dis_C_relsp


# in: a0 = instruction word
dis_CI_imm:
	PUSH_RA
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
	POP_RA_RET
.size dis_CI_imm, .-dis_CI_imm


# in: a0 = instruction word
dis_CI_4imm:
	li		a1, 0b11100
	li		a2, 0b11000000
#if XLEN >= 64
	j		dis_CI_Ximm
#endif
.size dis_CI_4imm, .-dis_CI_4imm
dis_CI_8imm:
#if XLEN >= 64
	li		a1, 0b11000
	li		a2, 0b111000000
	j		dis_CI_Ximm
#endif
.size dis_CI_8imm, .-dis_CI_8imm
dis_CI_16imm:
#if XLEN >= 128
	li		a1, 0b10000
	li		a2, 0b11110000
#endif
.size dis_CI_16imm, .-dis_CI_16imm
dis_CI_Ximm:
	PUSH_RA
	srli	t0, a0, 2
	and		t0, t0, a1					# from above
	srli	t1, a0, 7
	andi	t1, t1, 0b100000			# always the same
	slli	t2, a0, 4
	and		t2, t2, a2					# from above
	# put everything together
	or		a0, t0, t1
	or		a0, a0, t2
	jal		print_decimal
	POP_RA_RET
.size dis_CI_Ximm, .-dis_CI_Ximm


# in: a0 = instruction word
dis_CSS_16imm:
#if XLEN >= 128
	PUSH_RA
	srli	t0, a0, 7
	andi	t0, t0, 0b110000
	srli	t1, a0, 1
	andi	t1, t1, 0b1111000000
	j		dis_CSS_tail
#endif
.size dis_CSS_16imm, .-dis_CSS_16imm
dis_CSS_8imm:
#if XLEN >= 64
	PUSH_RA
	srli	t0, a0, 7
	andi	t0, t0, 0b111000
	srli	t1, a0, 1
	andi	t1, t1, 0b111000000
	j		dis_CSS_tail
#endif
.size dis_CSS_8imm, .-dis_CSS_8imm
dis_CSS_4imm:
	PUSH_RA
	srli	t0, a0, 7
	andi	t0, t0, 0b111100
	srli	t1, a0, 1
	andi	t1, t1, 0b11000000
.size dis_CSS_4imm, .-dis_CSS_4imm
dis_CSS_tail:
	or		a0, t0, t1
	jal		print_decimal
	POP_RA_RET
.size dis_CSS_tail, .-dis_CSS_tail


# in: a0 = instruction word
dis_CIW_imm:
	PUSH_RA
	srli	t0, a0, 2
	andi	t0, t0, 0b1000
	srli	t1, a0, 4
	andi	t1, t1, 0b100
	or		a1, t0, t1
	srli	t0, a0, 1
	andi	t0, t0, 0b1111000000
	or		a1, a1, t0
	srli	t0, a0, 7
	andi	t0, t0, 0b110000
	or		a0, a1, t0
	jal		print_decimal
	POP_RA_RET
.size dis_CIW_imm, .-dis_CIW_imm


# in: a0 = instruction word
dis_CL_LW_16imm:
#if XLEN >= 128
	PUSH_RA
	srli	t0, a0, 7
	andi	t0, t0, 0b110000
	srli	t1, a0, 2
	andi	t1, t1, 0b100000000
	slli	t2, a0, 1
	andi	t2, t2, 0b11000000
	j		dis_CL_LW_imm_tail
#endif
.size dis_CL_LW_16imm, .-dis_CL_LW_16imm
dis_CL_LW_8imm:
#if XLEN >= 64
	PUSH_RA
	srli	t0, a0, 7
	andi	t0, t0, 0b111000
	slli	t1, a0, 1
	andi	t1, t1, 0b11000000
	li		t2, 0
	j		dis_CL_LW_imm_tail
#endif
.size dis_CL_LW_8imm, .-dis_CL_LW_8imm
dis_CL_LW_4imm:
	PUSH_RA
	srli	t0, a0, 7
	andi	t0, t0, 0b111000
	slli	t1, a0, 1
	andi	t1, t1, 0b1000000
	srli	t2, a0, 4
	andi	t2, t2, 0b100
.size dis_CL_LW_4imm, .-dis_CL_LW_4imm
dis_CL_LW_imm_tail:
	# join everything
	or		a0, t0, t1
	or		a0, a0, t2
	jal		print_decimal
	POP_RA_RET
.size dis_CL_LW_imm_tail, .-dis_CL_LW_imm_tail


# in: a0 = instruction word
# in: a5 = origin address
dis_C_BRA:
	PUSH_RA
	slli	t0, a0, 3
	andi	t0, t0, 0b100000
	srli	t1, a0, 2
	andi	t1, t1, 0b110
	or		a1, t0, t1
	slli	t0, a0, 1
	andi	t0, t0, 0b11000000
	or		a1, a1, t0
	srli	t0, a0, 7
	andi	t0, t0, 0b11000
	or		a1, a1, t0
	srli	t0, a0, 4
	andi	t0, t0, 0b100000000
	or		a0, a1, t0
	# sign extend
	slli	a0, a0, 23
	#if XLEN >=64
		sext.w	a0, a0					# sign-extend to 64 bits
	#endif
	srai	a0, a0, 23
	# add insn address
	add		a0, a5, a0
	jal		print_hex					# effective address
	POP_RA_RET
.size dis_C_BRA, .-dis_C_BRA


# in: a0 = instruction word
# in: a5 = origin address
dis_CJ_off:
	PUSH_RA
	# decode offset
	slli	t0, a0, 3
	andi	t0, t0, 0b100000
	srli	t1, a0, 2
	andi	t1, t1, 0b1110
	or		a1, t0, t1
	srli	t0, a0, 1
	li		t1, 0b101101000000
	and		t0, t0, t1
	or		a1, a1, t0
	slli	t0, a0, 1
	andi	t0, t0, 0b10000000
	or		a1, a1, t0
	slli	t0, a0, 2
	andi	t0, t0, 0b10000000000
	or		a1, a1, t0
	srli	t0, a0, 7
	andi	t0, t0, 0b10000
	or		a0, a1, t0
	# sign extend
	slli	a0, a0, 20
	#if XLEN >=64
		sext.w	a0, a0					# sign-extend to 64 bits
	#endif
	srai	a0, a0, 20
	# add insn address
	add		a0, a5, a0
	jal		print_hex					# effective address
	POP_RA_RET
.size dis_CJ_off, .-dis_CJ_off


# in: a0 = instruction word
dis_CA_imm:
	ret
.size dis_CA_imm, .-dis_CA_imm


# in: instruction word in a0
dis_CL_rel:
dis_CS_rel:
	PUSH_S0_RA
	mv		s0, a0
	li		a0, '('
	jal		print_char
	mv		a0, s0
	jal		dis_C_rs1a
	li		a0, ')'
	jal		print_char
	POP_S0_RA_RET
.size dis_CL_rel, .-dis_CL_rel


# in: a0 = instruction word
dis_C_16sp_imm:
	PUSH_RA
	slli	t0, a0, 3
	andi	t0, t0, 0b100000
	slli	t1, a0, 4
	andi	t1, t1, 0b110000000
	or		a1, t0, t1
	slli	t0, a0, 1
	andi	t0, t0, 0b1000000
	or		a1, a1, t0
	srli	t0, a0, 2
	andi	t0, t0, 0b10000
	or		a1, a1, t0
	srli	t0, a0, 3
	andi	t0, t0, 0b1000000000
	or		a0, a1, t0
	# sign extend
	slli	a0, a0, 22
	#if XLEN >=64
		sext.w	a0, a0					# sign-extend to 64 bits
	#endif
	srai	a0, a0, 22
	# add insn address
	jal		print_decimal
	POP_RA_RET
.size dis_C_16sp_imm, .-dis_C_16sp_imm


#endif /* (WITH_CMD_D) && defined (DISASS_RVC) */
