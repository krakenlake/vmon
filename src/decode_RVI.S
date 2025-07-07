#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_D

.global insn_is_compressed

.global print_register_name
.global print_rs1_as_base

.global print_int_register_name
.global print_float_register_name

.global dis_rd
.global dis_rs1
.global dis_rs2
.global dis_I_imm
.global dis_S_imm
.global dis_BRA
.global dis_J
.global dis_U_imm
.global dis_I_rel
.global dis_PRE
.global dis_SUC

.global dis_C_rd

.text


# in: instruction word in a0
dis_rd:
dis_C_rd:
	srli	a0, a0, 7
	j		print_int_register_name
.size dis_rd, .-dis_rd


# in: instruction word in a0
dis_rs1:
	srli	a0, a0, 15
	j		print_int_register_name
.size dis_rs1, .-dis_rs1


# in: instruction word in a0
dis_rs2:
	srli	a0, a0, 20
	j		print_int_register_name
.size dis_rs2, .-dis_rs2


# in: a0 = register index number n
print_int_register_name:
	PUSH_RA
	and		a0, a0, 0b11111
	jal		get_int_register_name_by_index
	jal		print_string
	POP_RA_RET
.size print_int_register_name, .-print_int_register_name


# in: a0 = instruction word
# in: a1 = current instruction address (global)
dis_BRA:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s2, (XLEN_BYTES*1)(sp)
	mv		s2, a0	 
	# imm[0] := 0
	# inst[11:8] -> imm[4:1] 
	srli	a0, s2, 7
	andi	a0, a0, 0b11110
	# inst[30:25] -> imm[10:5]
	srli	t0, s2, 20
	li		t1, 0b11111100000
	and		t0, t0, t1
	or		a0, a0, t0 
	# inst[7] -> imm[11]
	and		t0, s2, 0b10000000
	slli	t0, t0, 4
	or		a0, a0, t0 
	# inst[31] -> imm[63:12]
	#if XLEN >=64
		sext.w	s2, s2					# sign-extend to 64 bits
	#endif
	srai	t0, s2, 19
	li		t1, 0xfffffffffffff000
	and		t0, t0, t1
	or		a0, a0, t0 
	# add relative immediate to instruction address
	add		a0, a1, a0
	# print absolute target address
	jal		print_hex
	LOAD_X	ra, 0(sp)
	LOAD_X	s2, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size dis_BRA, .-dis_BRA


# in: instruction word in a0
dis_I_imm:
	PUSH_RA
	# inst[31:20] -> imm[11:0]
	srai	a0, a0, 20
	jal		print_decimal
	POP_RA_RET
.size dis_I_imm, .-dis_I_imm


# in: instruction word in a0
dis_S_imm:
	PUSH_RA
	# inst[31:25] -> imm[11:5]
	srai	t0, a0, 25					# shift the 5 lower bits out to clear them
	slli	t0, t0, 5					# shift 5 back
	srai	t1, a0, 7
	andi	t1, t1, 0b11111
	or		a0, t0, t1
	jal		print_decimal
	POP_RA_RET
.size dis_S_imm, .-dis_S_imm

# in: instruction word in a0
dis_U_imm:
	PUSH_RA
	# extract imm
	li		t0, 0xffffffff
	and		a0, a0, t0
	srli	a0, a0, 12 
	jal		print_hex
	POP_RA_RET
.size dis_U_imm, .-dis_U_imm


# in: a0 = instruction word
# in: a1 = current instruction address (global)
dis_J:
	addi	sp, sp, -(XLEN_BYTES*2)
	SAVE_X	ra, 0(sp)
	SAVE_X	s2, (XLEN_BYTES*1)(sp)
	mv		s2, a0
	# inst[30:21] -> imm[10:1]
	srli	a0, s2, 20
	andi	a0, a0, 0b11111111110	 
	# inst[20] -> imm[11]
	srli	t0, s2, 9
	li		t1, 0b100000000000 
	and		t0, t0, t1
	or		a0, a0, t0
	# inst[19:12] -> imm[19:12]
	li		t1, 0b11111111000000000000
	and		t0, s2, t1
	or		a0, a0, t0
	srai	t0, s2, 11
	li		t1, 0xfffffffffff80000
	and		t0, t0, t1
	or		a0, a0, t0
	add		a0, a1, a0
	jal		print_hex
	LOAD_X	ra, 0(sp)
	LOAD_X	s2, (XLEN_BYTES*1)(sp)
	addi	sp, sp, (XLEN_BYTES*2)
	ret
.size dis_J, .-dis_J


# in: a0: instruction word
# in: a1: number of start bit (27 for pre, 23 for sucessor)
decode_FENCE_bits:
	PUSH_S4_S3_S2_S1_S0_RA
	mv		s2, a0
	li		s3, 1
	sll		s3, s3, a1					# set up initial bit mask
	la		s1, string_FENCE_bits
	li		s0, 4						# 4 bits
decode_FENCE_bits_loop:
	and		t0, s2, s3
	beqz	t0, decode_FENCE_bits_skip
	lb		a0, 0(s1)
	jal		print_char
decode_FENCE_bits_skip:
	srli	s3, s3, 1
	addi	s1, s1, 1
	addi	s0, s0, -1
	bnez	s0, decode_FENCE_bits_loop
	POP_S4_S3_S2_S1_S0_RA_RET
.size decode_FENCE_bits, .-decode_FENCE_bits


# in: a0 = instruction word
dis_PRE:
	PUSH_RA
	li		a1, 27
	jal		decode_FENCE_bits
	POP_RA_RET
.size dis_PRE, .-dis_PRE


# in: a0 = instruction word
dis_SUC:
	PUSH_RA
	li		a1, 23
	jal		decode_FENCE_bits
	POP_RA_RET
.size dis_SUC, .-dis_SUC


# in: instruction word in a0
dis_I_rel:
	PUSH_RA
	SAVE_X	a0, (XLEN_BYTES*1)(sp)
	li		a0, '('
	jal		print_char
	LOAD_X	a0, (XLEN_BYTES*1)(sp)
	jal		dis_rs1
	li		a0, ')'
	jal		print_char
	POP_RA_RET
.size dis_I_rel, .-dis_I_rel


.data

.align 4

string_FENCE_bits:		.string "iorw";


#endif /* WITH_CMD_D */
