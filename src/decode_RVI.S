#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#ifdef WITH_CMD_D

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
dis_rs2:								# rs2 needs 20 shifts in total, so fall through after this
	srli	a0, a0, 5
dis_rs1:
	srli	a0, a0, 8					# rs1 needs 15 shifts in total, so fall through after this
dis_rd:
dis_C_rd:								# rd needs 7 shifts
	srli	a0, a0, 7
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
# in: a1 = current instruction address
dis_BRA:
	PUSH_RA
	# imm[0] := 0
	# inst[11:8] -> imm[4:1] 
	srli	a2, a0, 7
	andi	a2, a2, 0b11110
	# inst[30:25] -> imm[10:5]
	srli	t0, a0, 20
	li		t1, 0b11111100000
	and		t0, t0, t1
	or		a2, a2, t0 
	# inst[7] -> imm[11]
	and		t0, a0, 0b10000000
	slli	t0, t0, 4
	or		a2, a2, t0 
	# inst[31] -> imm[63:12]
	#if XLEN >=64
		sext.w	a0, a0					# sign-extend to 64 bits
	#endif
	srai	t0, a0, 19
	li		t1, 0xfffffffffffff000
	and		t0, t0, t1
	or		a2, a2, t0 
	# add relative immediate to instruction address
	add		a0, a1, a2
	# print absolute target address
	jal		print_hex
	POP_RA_RET
.size dis_BRA, .-dis_BRA


# in: instruction word in a0
dis_I_imm:
	# inst[31:20] -> imm[11:0]
	#if XLEN >=64
		sext.w	a0, a0					# sign-extend to 64 bits
	#endif
	srai	a0, a0, 20
	j		print_decimal
.size dis_I_imm, .-dis_I_imm


# in: instruction word in a0
dis_S_imm:
	# inst[31:25] -> imm[11:5]
	srai	t0, a0, 25					# shift the 5 lower bits out to clear them
	slli	t0, t0, 5					# shift 5 back
	srai	t1, a0, 7
	andi	t1, t1, 0b11111
	or		a0, t0, t1
	j		print_decimal
.size dis_S_imm, .-dis_S_imm


# in: instruction word in a0
dis_U_imm:
	# extract imm
	li		t0, 0xffffffff
	and		a0, a0, t0
	srli	a0, a0, 12 
	j		print_hex
.size dis_U_imm, .-dis_U_imm


# in: a0 = instruction word
# in: a1 = current instruction address
dis_J:
	# inst[30:21] -> imm[10:1]
	srli	a2, a0, 20
	andi	a2, a2, 0b11111111110	 
	# inst[20] -> imm[11]
	srli	t0, a0, 9
	li		t1, 1 << 11 
	and		t0, t0, t1
	or		a2, a2, t0
	# inst[19:12] -> imm[19:12]
	li		t1, 0b11111111000000000000
	and		t0, a0, t1
	or		a2, a2, t0
	# inst[31] -> imm[63:20]
	#if XLEN >=64
		sext.w	a0, a0					# sign-extend to 64 bits
	#endif	
	srai	t0, a0, 11
	li		t1, -1 << 20
	and		t0, t0, t1
	or		a2, a2, t0
	add		a0, a1, a2
	j		print_hex
.size dis_J, .-dis_J


# in: a0: instruction word
# in: a1: number of start bit (27 for pre, 23 for sucessor)
decode_FENCE_bits:
	PUSH_TP_S1_S0_RA
	mv		tp, a0
	li		s1, 1
	sll		s1, s1, a1					# set up initial bit mask
	li		s0, 4						# 4 bits
	la		a5, string_FENCE_bits
decode_FENCE_bits_loop:
	and		t0, tp, s1
	beqz	t0, decode_FENCE_bits_skip
	lb		a0, 0(a5)
	jal		print_char					#* print_char does not use a5
decode_FENCE_bits_skip:
	srli	s1, s1, 1
	addi	a5, a5, 1
	addi	s0, s0, -1
	bnez	s0, decode_FENCE_bits_loop
	POP_TP_S1_S0_RA_RET
.size decode_FENCE_bits, .-decode_FENCE_bits


# in: a0 = instruction word
dis_PRE:
	li		a1, 27
	j		decode_FENCE_bits
.size dis_PRE, .-dis_PRE


# in: a0 = instruction word
dis_SUC:
	li		a1, 23
	j		decode_FENCE_bits
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


.section .rodata


string_FENCE_bits:
	.string "iorw";
.size string_FENCE_bits, .-string_FENCE_bits


#endif /* WITH_CMD_D */
