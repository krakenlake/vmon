#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#ifdef WITH_CMD_D

.global print_instruction

.text


# in: a0 = insn word
# in: s5 = origin address (global)
# in: a3 = ptr to encoding table entry
decode_GENERIC:
	addi	sp, sp, -(XLEN_BYTES*8)
	SAVE_X	s6, 0(sp)
	SAVE_X	s5, (XLEN_BYTES*1)(sp)
	SAVE_X	s4, (XLEN_BYTES*2)(sp)
	SAVE_X	s3, (XLEN_BYTES*3)(sp)
	SAVE_X	s2, (XLEN_BYTES*4)(sp)
	SAVE_X	s1, (XLEN_BYTES*5)(sp)			# ex-ass dst word
	SAVE_X	s0, (XLEN_BYTES*6)(sp)
	SAVE_X	ra, (XLEN_BYTES*7)(sp)
	mv		s2, s5							# save global s5 for call later
	mv		s1, a0							# save insn word
	li		s4,	4							# process max. 4 arguments
	# get control word for this insn
	LWU		s0, ENC_OFF_CTRL(a3)
	li		s5, 0xff						# init control word mask
	li		s6, 0							# init control word shift
decode_GENERIC_next_argument:
	and		s3, s0, s5						# mask next control word byte
	# done if no more arguments to decode
	beqz	s3, decode_GENERIC_done
	# print comma if not first argument
	beqz	s6, decode_GENERIC_skip_comma
	jal		print_comma
decode_GENERIC_skip_comma:
	sra		s3, s3, s6						# shift result to lsb
	slli	s3, s3, 3						# *8
	la		t1, encoding_vectors
	add		s3, s3, t1
	LWU		s3, 4(s3)
	beqz	s3, decode_GENERIC_done
	# now func ptr in s3
	mv		a1, s2
	mv		a0, s1
	jalr	s3								# call decode function for this argument
	# check if we have processed 4 arguments already
	addi	s4, s4, -1
	beqz	s4, decode_GENERIC_done
	# advance our tools
	slli	s5, s5, 8						# shift mask to next control word byte
	addi	s6, s6, 8						# adjust lsb shifting parameter
	j 		decode_GENERIC_next_argument
decode_GENERIC_error:
	mv		a1, zero
decode_GENERIC_done:
	j		pop_s6_s5_s4_s3_s2_s1_s0_ra_ret
.size decode_GENERIC, .-decode_GENERIC


# in: a0 = insn word
# in: a3 = ptr to table entry
print_instruction:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	s0, 0(sp)
	SAVE_X	ra, (XLEN_BYTES*1)(sp)
	mv		s0, a0
	LWU		a0, ENC_OFF_OP_STRING(a3)
	jal		print_string				# print opcode
	#ifdef DISASS_RVA
		mv		a0, s0
		jal		print_AMO_postfix		# prints aq/lr postfix for RVA opcodes
	#endif
	la		a0, string_asm_sep2
	jal		print_string
	mv		a0, s0
	jal 	decode_GENERIC
print_instruction_done:
	j		pop_s0_ra_ret
.size print_instruction, .-print_instruction


#endif /* WITH_CMD_D */
