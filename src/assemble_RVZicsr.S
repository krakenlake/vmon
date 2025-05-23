#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVZicsr)

.global ass_csr						# expect CSR specifier
.global ass_csri					# expect CSR immediate value

.text


# expect CSR specifier
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_csr:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_csr_error
	li		t0, -2048
	blt		a1, t0, ass_csr_error		# numeric too small
	li		t0, 2047
	bgt		a1, t0, ass_csr_error		# numeric too big
	# add imm value to instruction word
	slli	t0, a1, 20					# imm value
	or		a1, s0, t0					# insn word
	j 		ass_csr_done
ass_csr_error:
	mv		a1, zero
ass_csr_done:
	j		pop_s0_ra_ret
.size ass_csr, .-ass_csr


# expect CSR immediate
#
# in: a0 = ptr to first char of argument
# in: a1 = insn word to be modifed
# in: a2 = origin address
# out: a0 = ptr to char after argument
# out: a1 = insn word (0 on error)
ass_csri:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a1						# save insn word
	jal		get_numeric
	# imm  value in a1
	bnez	a2, ass_csri_error
	bltz	a1, ass_csri_error			# numeric too small
	li		t0, 31
	bgt		a1, t0, ass_csri_error		# numeric too big
	# add imm value to instruction word
	slli	t0, a1, 15					# prepare imm value
	or		a1, s0, t0					# add to insn word
	j 		ass_csr_done
ass_csri_error:
	mv		a1, zero
ass_csri_done:
	j		pop_s0_ra_ret
.size ass_csri, .-ass_csri


#endif /* defined (WITH_CMD_A) && defined (DISASS_RVZicsr) */
