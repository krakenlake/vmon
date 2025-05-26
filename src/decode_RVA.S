#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_D) && defined (DISASS_RVA)

.global dis_PRE
.global dis_SUC
.global dis_AMEM
.global print_AMO_postfix

.text


# for RVA
# in: instruction word in a0
# out: instruction word in a0
# out: aq/rl bits in bits 0 and 1 of a1
insn_get_aqrl:
	srli	a1, a0, 25
	andi	a1, a1, 0b11
	ret
.size insn_get_aqrl, .-insn_get_aqrl


# in: instruction word in a0
print_AMO_postfix:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	# check if bits 0-6 are an AMO opcode, return if not
	li		t0, 0x7f			# MASK
	and		t1, a0, t0
	li		t2, 0x2f			# MATCH
	bne		t1, t2, print_AMO_postfix_done
	# decode ac/rl bits and print fitting postfix
	jal		insn_get_aqrl
	beqz	a1, print_AMO_postfix_done
	li		t0, 1
	bne		a1, t0, print_AMO_postfix_case2
	la		a0, string_OP_POSTFIX_RL
	jal		print_string
	j		print_AMO_postfix_done
print_AMO_postfix_case2:
	li		t0, 2
	bne		a1, t0, print_AMO_postfix_case3
	la		a0, string_OP_POSTFIX_AQ
	jal		print_string
	j		print_AMO_postfix_done
print_AMO_postfix_case3:
	la		a0, string_OP_POSTFIX_AQRL
	jal		print_string
print_AMO_postfix_done:
	j		pop_ra_ret
.size print_AMO_postfix, .-print_AMO_postfix


.data

.align 4

string_OP_POSTFIX_AQ:	.string ".aq";
	.size string_OP_POSTFIX_AQ, .-string_OP_POSTFIX_AQ

string_OP_POSTFIX_RL:	.string ".rl";
	.size string_OP_POSTFIX_RL, .-string_OP_POSTFIX_RL

string_OP_POSTFIX_AQRL:	.string ".aqrl";
	.size string_OP_POSTFIX_AQRL, .-string_OP_POSTFIX_AQRL


#endif /* (WITH_CMD_D) && defined (DISASS_RVA) */
