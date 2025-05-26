#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVA)

.global ass_aqrl					# expect ".aqrl" extension for RVA

.text


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_aqrl:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	li		t1, '.'						# consume '.'
	lb		t0, 0(a0)
	bne 	t0, t1, ass_aqrl_error
	addi	a0, a0, 1
	jal		parse_aqrl
	or		a1 , s0, a1
	j 		ass_aqrl_done
ass_aqrl_error:
	mv		a1, zero
ass_aqrl_done:
	j		pop_s0_ra_ret
.size ass_aqrl, .-ass_aqrl


#endif /* defined (WITH_CMD_A) && defined (DISASS_RVA) */
