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
	addi	sp, sp, -(XLEN_BYTES*6)
	SAVE_X	s4, 0(sp)
	SAVE_X	s3, (XLEN_BYTES*1)(sp)
	SAVE_X	s2, (XLEN_BYTES*2)(sp)
	SAVE_X	s1, (XLEN_BYTES*3)(sp)			# ex-ass dst word
	SAVE_X	s0, (XLEN_BYTES*4)(sp)
	SAVE_X	ra, (XLEN_BYTES*5)(sp)
	mv		s1, a0							# save insn word
	li		s4,	4							# process max. 4 arguments
	# get control word for this insn
	LWU		s0, ENC_OFF_CTRL(a3)
decode_GENERIC_next_argument:
	andi	s3, s0, 0xff
	beqz	s3, decode_GENERIC_done
	slli	t2, s3, 3						# *8
	la		t1, encoding_vectors
	add		t0, t2, t1
	LWU		t0, 4(t0)
	beqz	t0, decode_GENERIC_done
	# now func ptr in s3
	mv		a1, s5
	mv		a0, s1
	jalr	t0								# call decode function for this argument


	# check if we have processed 4 arguments already
	addi	s4, s4, -1
	beqz	s4, decode_GENERIC_done
	#	print comma
	li		t1, 0x04						# skip comma after I-type offset
	beq		s3, t1, decode_GENERIC_skip_comma
	li		t1, 0x05						# skip comma after S-type offset
	beq		s3, t1, decode_GENERIC_skip_comma
	srai	t0, s0, 8
	beqz	t0, decode_GENERIC_done
	jal		print_comma
	
decode_GENERIC_skip_comma:
	srai	s0, s0, 8						# next byte of control word
	j 		decode_GENERIC_next_argument
decode_GENERIC_error:
	mv		a1, zero
decode_GENERIC_done:
	j		pop_s4_s3_s2_s1_s0_ra_ret
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
