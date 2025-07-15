#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_A

.global assemble_instruction
.global assemble_GENERIC

.text


# in: a0 = ptr to input text
# in: a2 = current memory address to write (needed for branch calculation)
# out: a0 = insn size (normal 4, 2 for RVC, 0 if error)
# out: a1 = assembled instruction to be written into memory
assemble_instruction:
	PUSH_S4_S3_S2_S1_S0_RA

	mv		s3, zero							# clear RVA aqrl bits
	jal		skip_whitespace
	mv		s0, a0								# insn string start
	jal		parse_insn_string
	mv		s1, a0								# insn string end

#ifdef DISASS_RVA
	mv		s2, a1								# ptr to second '.' in string (if present)
	beqz	a1, assemble_instruction_not_aqrl
	# RVA insns may end with ".aq", ".rl", or ".aqrl".
	# Those insns are stored in the encoding table without these extensions.
	# So if one of these extensions is present
	# - assemble the aq/rl bits
	# - set up s1 so that only the part without extension will be used for lookup later
	addi	a0, s2, 1							# advance to char after second dot
	jal		parse_aqrl
	mv		s3, a1
	# set s1 so that the string between s0 and s1 is that part
	# of the insn that does not contain the ".aqrl" extension
	mv		a0, s1
	jal		skip_whitespace
	mv		s1, a0
assemble_instruction_not_aqrl:
#endif /* DISASS_RVA */

	# find string between s0 and s1 in encoding table
	jal		get_data_by_insn_name
	# function ptr now in a0
	# MATCH value now in a1
	# table entry ptr in a3
	beqz	a0, assemble_instruction_done		# not found
	mv		a0, s1								# input  string ptr
	# current memory addr already in a2
	jal		assemble_GENERIC					# handle all insns
	# now a1 = insn code
	# in case insn == 0, 
	beqz	a1, assemble_instruction_error		# error while assembling insn parameters

#ifdef DISASS_RVA
	# add RVA aqrl bits if there were any from above
	or		a1, a1, s3
#endif /* DISASS_RVA */

	j 		assemble_instruction_done
assemble_instruction_error:
	mv		a0, zero
assemble_instruction_done:
	POP_S4_S3_S2_S1_S0_RA_RET
.size assemble_instruction, .-assemble_instruction


# in: a0 = ptr to remaining input string
# in: a2 = origin address
# in: a3 = ptr to encoding table entry
# out: assembled instruction in a1
assemble_GENERIC:
	PUSH_S4_S3_S2_S1_S0_RA

	mv		s2, a2
	li		s4,	4							# process max. 4 arguments
	# assemble instruction word in s1, starting with MATCH value from table
	LWU		s1, ENC_OFF_MATCH(a3)
	# get control word for this insn
	LWU		s0, ENC_OFF_CTRL(a3)
assemble_GENERIC_next_argument:
	andi	s3, s0, 0xff
	beqz	s3, assemble_GENERIC_done
	# advance string ptr to arg
	jal		skip_whitespace
	# compute func ptr
	slli	t2, s3, 3						# *8
	la		t1, disass_vectors
	add		t0, t2, t1
	LWU		t0, 0(t0)
	beqz	t0, assemble_GENERIC_done
	# assemble argument
											# ptr to parameter start in a0
	mv		a1, s1							# insn word in a1
	mv		a2, s2							# origin address in a2
	jalr 	t0
	# it is an error if a2 == -1, so add 1 and check for zero
	addi	a2, a2, 1							
	beqz	a2, assemble_GENERIC_error		# assembling argument failed
	mv		s1, a1							# save insn word
	# check if we have processed 4 arguments already
	addi	s4, s4, -1
	beqz	s4, assemble_GENERIC_done
	# expect comma
	li		t1, 0x04						# no comma after I-type offset
	beq		s3, t1, assemble_GENERIC_skip_comma
	li		t1, 0x05						# no comma after S-type offset
	beq		s3, t1, assemble_GENERIC_skip_comma
	#ifdef DISASS_RVC
		li		t1, 0x1f					# no comma after I_4imm offset
		beq		s3, t1, assemble_GENERIC_skip_comma
		li		t1, 0x1b					# no comma after c.lw/c.sw offset
		beq		s3, t1, assemble_GENERIC_skip_comma
	#endif
	srli	t0, s0, 8						# do we expect more arguments?
	beqz	t0, assemble_GENERIC_done
	# expect comma
	li		t0, ','
	jal		expect_char
	beqz	a0, assemble_GENERIC_error		# missing comma
assemble_GENERIC_skip_comma:
	srli	s0, s0, 8						# shift mask to next control word byte
	j 		assemble_GENERIC_next_argument
assemble_GENERIC_error:
	mv		a1, zero
assemble_GENERIC_done:
	POP_S4_S3_S2_S1_S0_RA_RET
.size assemble_GENERIC, .-assemble_GENERIC


#endif /* WITH_CMD_A */
