#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVA)

.global ass_aqrl					# expect ".aqrl" extension for RVA
.global ass_AMEM					# expect (reg) parameter for RVA

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


# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_AMEM:
	addi	sp, sp, -(XLEN_BYTES*3)
	SAVE_X	s1, 0(sp)
	SAVE_X	s0, (XLEN_BYTES*1)(sp)
	SAVE_X	ra, (XLEN_BYTES*2)(sp)
	mv		s1, a1						# save insn word
	mv		s0, a0						# return string ptr later
	jal		expect_open_paren
	beqz	a0, ass_AMEM_error
	# process rs1
	mv		a1, s1
	jal		ass_rs1
	beqz	a1, ass_AMEM_error
	mv 		s1, a1
	jal		expect_close_paren
	beqz	a0, ass_AMEM_error
	# assemble in a1
	mv		a1, s1
ass_AMEM_continue:
	addi	a0, s0, 1					# string ptr +1
	j		ass_AMEM_done
ass_AMEM_error:
	mv		a1, zero
ass_AMEM_done:
	j		pop_s1_s0_ra_ret
.size ass_AMEM, .-ass_AMEM


#endif /* defined (WITH_CMD_A) && defined (DISASS_RVA) */
