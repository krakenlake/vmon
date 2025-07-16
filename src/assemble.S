#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"
#include "vmon/error.h"


#ifdef WITH_CMD_A

.global assemble_instruction
.global assemble_GENERIC

.text


# in: a0 = ptr to input text
# in: a2 = current memory address to write (needed for branch calculation)
# out: a1 = assembled instruction to be written into memory
# out: a2 = error code (0=OK)
assemble_instruction:
	PUSH_S1_S0_RA

	addi	sp, sp, -(XLEN_BYTES*1)				# local: RVA aqrl bits
	SAVE_X	zero, 0(sp)							# clear RVA aqrl bits

	jal		skip_whitespace
	mv		s0, a0								# insn string start
	jal		parse_insn_string
	# a0 = ptr to end of parsed insn word
	# a1 = ptr to second '.' if present (otherwise 0)
	mv		s1, a0								# insn string end

#ifdef DISASS_RVA
	beqz	a1, assemble_instruction_not_aqrl
	# RVA insns may end with ".aq", ".rl", or ".aqrl".
	# Those insns are stored in the encoding table without these extensions.
	# So if one of these extensions is present
	# - assemble the aq/rl bits
	# - set up s1 so that only the part without extension will be used for lookup later
	addi	a0, a1, 1							# advance to char after second dot
	jal		parse_aqrl
	SAVE_X	a1, 0(sp)							# save aqrl bits

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
	beqz	a0, assemble_instruction_not_found	# not found
	mv		a0, s1								# input  string ptr
	# current memory addr already in a2
	jal		assemble_GENERIC					# handle all insns
	# a1 = insn word
	# a2 = error code
	bnez	a2, assemble_instruction_done		# error while assembling insn parameters

#ifdef DISASS_RVA
	# add RVA aqrl bits if there were any from above
	LOAD_X	t0, 0(sp)
	or		a1, a1, t0
#endif /* DISASS_RVA */

	j 		assemble_instruction_done
assemble_instruction_not_found:
	li		a2, ERR_INSN_NOTFOUND
assemble_instruction_done:
	addi	sp, sp, (XLEN_BYTES*1)	
	POP_S1_S0_RA_RET
.size assemble_instruction, .-assemble_instruction



# in: a0 = ptr to remaining input string
# in: a2 = origin address
# in: a3 = ptr to encoding table entry
# out: a1 = assembled instruction
# out: a2 = error code (0=OK)
assemble_GENERIC:
	PUSH_S4_S3_S2_S1_S0_RA

	mv		s2, a2							# origin address for jumps
	li		s4,	4							# process max. 4 arguments
	# assemble instruction word in s1, starting with MATCH value from table
	LWU		s1, ENC_OFF_MATCH(a3)
	# get control word for this insn
	LWU		s0, ENC_OFF_CTRL(a3)
assemble_GENERIC_next_argument:
	
	# advance string ptr to arg
	jal		skip_whitespace

	andi	t0, s0, 0xff					# isolate current control byte
	beqz	t0, assemble_GENERIC_OK
	# compute func ptr
	slli	t2, t0, 3						# *8
	la		t1, disass_vectors
	add		t0, t2, t1
	LWU		t0, 0(t0)
	beqz	t0, assemble_GENERIC_OK

	# assemble argument
											# ptr to parameter start in a0
	mv		a1, s1							# insn word
	mv		a2, s2							# origin address
	jalr 	t0

	# it is an error if a2 == -1, so add 1 and check for zero
	addi	a2, a2, 1							
	beqz	a2, assemble_GENERIC_error		# assembling argument failed
	mv		s1, a1							# save insn word

	# check if we have processed 4 arguments already
	addi	s4, s4, -1
	beqz	s4, assemble_GENERIC_OK

	# expect comma
	andi	t0, s0, 0xff					# isolate control byte again
	li		t1, 0x04						# no comma after I-type offset
	beq		t0, t1, assemble_GENERIC_skip_comma
	li		t1, 0x05						# no comma after S-type offset
	beq		t0, t1, assemble_GENERIC_skip_comma

	#ifdef DISASS_RVC
		li		t1, 0x1f					# no comma after I_4imm offset
		beq		t0, t1, assemble_GENERIC_skip_comma
		li		t1, 0x1b					# no comma after c.lw/c.sw offset
		beq		t0, t1, assemble_GENERIC_skip_comma
	#endif

	srli	t0, s0, 8						# do we expect more arguments?
	beqz	t0, assemble_GENERIC_OK
	
	# expect comma
	li		a4, ','
	jal		expect_char
	beqz	a0, assemble_GENERIC_error		# missing comma

assemble_GENERIC_skip_comma:
	srli	s0, s0, 8						# shift mask to next control word byte
	j 		assemble_GENERIC_next_argument

assemble_GENERIC_error:
	li		a2, ERR_INSN_SYNTAX
	j		assemble_GENERIC_done

assemble_GENERIC_OK:
	li		a2, 0
assemble_GENERIC_done:
	POP_S4_S3_S2_S1_S0_RA_RET
.size assemble_GENERIC, .-assemble_GENERIC


#endif /* WITH_CMD_A */
