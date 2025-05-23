#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#ifdef WITH_CMD_A

.global assemble_instruction
.global assemble_GENERIC

.text


# in: a0 = ptr to input text
# in: a2 = current memory address to write (needed for branch calculation)
# out: a0 = insn size (normal 4, 2 for RVC, 0 if error)
# out: a1 = assembled instruction to be written into memory
assemble_instruction:
	addi	sp, sp, -(XLEN_BYTES*5)
	SAVE_X	s3, 0(sp)
	SAVE_X	s2, (XLEN_BYTES*1)(sp)
	SAVE_X	s1, (XLEN_BYTES*2)(sp)
	SAVE_X	s0, (XLEN_BYTES*3)(sp)
	SAVE_X	ra, (XLEN_BYTES*4)(sp)

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

	# now return insn size in a0
#ifdef DISASS_RVC
	mv		a0, a1
	jal		insn_is_compressed
	bnez	a0, assemble_instruction_is_RVC
	li		a0, 4
	j		assemble_instruction_done
assemble_instruction_is_RVC:
	li		a0, 2
#else
	li		a0, 4
#endif
	j 		assemble_instruction_done
assemble_instruction_error:
	mv		a0, zero
assemble_instruction_done:
	j		pop_s3_s2_s1_s0_ra_ret
.size assemble_instruction, .-assemble_instruction


# in: a0 = ptr to remaining input string
# in: a2 = origin address
# in: a3 = ptr to encoding table entry
# out: assembled instruction in a1
assemble_GENERIC:
	addi	sp, sp, -(XLEN_BYTES*8)
	SAVE_X	s6, 0(sp)
	SAVE_X	s5, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	SAVE_X	s3, (XLEN_BYTES*3)(sp)
	SAVE_X	s2, (XLEN_BYTES*4)(sp)
	SAVE_X	s1, (XLEN_BYTES*5)(sp)
	SAVE_X	s0, (XLEN_BYTES*6)(sp)
	SAVE_X	ra, (XLEN_BYTES*7)(sp)
	li		s4,	4							# process max. 4 arguments
	mv		s2, a2
	# assemble instruction word in s1, starting with MATCH value from table
	LWU		s1, ENC_OFF_MATCH(a3)
	# get control word for this insn
	LWU		s0, ENC_OFF_CTRL(a3)
	li		s5, 0xff						# init control word mask
	li		s6, 0							# init control word shift
assemble_GENERIC_next_argument:
	# advance string ptr to arg
	jal		skip_whitespace
	# get function ptr 
	and		s3, s0, s5						# mask next control word byte
	# done if no more arguments to process
	beqz	s3, assemble_GENERIC_done
	# check for comma if not first argument
	beqz	s6, assemble_GENERIC_skip_comma
	jal		expect_comma
	beqz 	a0, assemble_GENERIC_error
assemble_GENERIC_skip_comma:
	sra		s3, s3, s6						# shift result to lsb
	slli	s3, s3, 3						# *8
	la		t1, encoding_vectors
	add		s3, s3, t1
	LWU		s3, 0(s3)
	# now func ptr in s3

	# assemble argument
											# ptr to parameter start in a0
	mv		a1, s1							# insn word in a1
	mv		a2, s2							# origin address in a2
	jalr 	s3	
	beqz	a1, assemble_GENERIC_error		# assembling argument failed
	mv		s1, a1							# save insn word
	# check if we have processed 4 arguments already
	addi	s4, s4, -1
	beqz	s4, assemble_GENERIC_done
	# advance our tools
	slli	s5, s5, 8						# shift mask to next control word byte
	addi	s6, s6, 8						# adjust lsb shifting parameter
	j 		assemble_GENERIC_next_argument
assemble_GENERIC_error:
	mv		a1, zero
assemble_GENERIC_done:
	j		pop_s6_s5_s4_s3_s2_s1_s0_ra_ret
.size assemble_GENERIC, .-assemble_GENERIC


#endif /* WITH_CMD_A */
