#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_D

.global print_instruction

.text


# in: a0 = insn word
# in: a1 = origin address
# in: a3 = ptr to encoding table entry
decode_GENERIC:
	PUSH_TP_S1_S0_RA
	LWU		s0, ENC_OFF_CTRL(a3)			# control word for this insn
	mv		s1, a0							# save insn word
	mv		a5, a1							# save origin address
decode_GENERIC_next_argument:
	andi	tp, s0, 0xff
	beqz	tp, decode_GENERIC_done
	slli	t0, tp, 3						# *8
	la		t1, disass_vectors
	add		t0, t0, t1
	LWU		t0, 4(t0)
	beqz	t0, decode_GENERIC_done
	# now func ptr in tp
	mv		a0, s1							# insn word
	mv		a1, a5							# origin address
	jalr	t0								# call decode function for this argument

	#	print comma
	li		t0, 0x04						# skip comma after I-type offset
	beq		tp, t0, decode_GENERIC_skip_comma
	li		t0, 0x05						# skip comma after S-type offset
	beq		tp, t0, decode_GENERIC_skip_comma
	#ifdef DISASS_RVC
		li		t0, 0x1b					# skip comma after CL_imm offset
		beq		tp, t0, decode_GENERIC_skip_comma
		li		t0, 0x1f					# skip comma after I_4imm offset
		beq		tp, t0, decode_GENERIC_skip_comma
	#endif

	# decode more arguments?
	srli	t0, s0, 8
	beqz	t0, decode_GENERIC_done

	jal		print_comma

decode_GENERIC_skip_comma:
	srli	s0, s0, 8						# next byte of control word
	j 		decode_GENERIC_next_argument

decode_GENERIC_error:
	mv		a1, zero

decode_GENERIC_done:
	POP_TP_S1_S0_RA_RET
.size decode_GENERIC, .-decode_GENERIC


# in: a0 = insn word
# in: a1 = addr of insn in memory
# in: a3 = ptr to table entry
print_instruction:
	PUSH_S1_S0_RA
	mv		s0, a0
	mv		s1, a1
	LWU		a0, ENC_OFF_OP_STRING(a3)
	jal		print_string				# print opcode
	#ifdef DISASS_RVA
		mv		a0, s0
		jal		print_AMO_postfix		# prints aq/lr postfix for RVA opcodes
	#endif
	la		a0, string_asm_sep2
	jal		print_string
	mv		a0, s0
	mv		a1, s1
	jal 	decode_GENERIC
print_instruction_done:
	POP_S1_S0_RA_RET
.size print_instruction, .-print_instruction


#endif /* WITH_CMD_D */
