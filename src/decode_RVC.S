#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_D) && defined (DISASS_RVC)

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

#endif /* (WITH_CMD_D) && defined (DISASS_RVC) */
