#include "vmon/config.h"
#include "riscv/riscv-opc.h"

#ifdef WITH_CMD_D

.global encoding_table
.global register_names
.global string_OP_UNKNOWN

.data

.align 4
register_names:
#ifndef ABI_REGISTER_NAMES
	.string  "x0",  "x1",  "x2",  "x3",  "x4",  "x5",  "x6",  "x7"
	.string  "x8",  "x9", "x10", "x11", "x12", "x13", "x14", "x15"
	.string "x16", "x17", "x18", "x19", "x20", "x21", "x22", "x23"
	.string "x24", "x25", "x26", "x27", "x28", "x29", "x30", "x31"
#else
	.string "zero", "ra",  "sp",  "gp", "tp", "t0", "t1", "t2"
	.string "fp",   "s1",  "a0",  "a1", "a2", "a3", "a4", "a5"
	.string "a6",   "a7",  "s2",  "s3", "s4", "s5", "s6", "s7"
	.string "s8",   "s9", "s10", "s11", "t3", "t4", "t5", "t6"
#endif
.size register_names, .-register_names


# Opcode strings


# RV32I
string_opcodes:
string_OP_LUI:      .string "lui";		#
string_OP_AUIPC:    .string "auipc";	#	
string_OP_JAL:      .string "jal";		#
string_OP_JALR:     .string "jalr";		#
string_OP_BEQ:      .string "beq";		#
string_OP_BNE:      .string "bne";		#
string_OP_BLT:      .string "blt";		#
string_OP_BGE:      .string "bge";		#
string_OP_BLTU:     .string "bltu";		#
string_OP_BGEU:     .string "bgeu";		#
string_OP_LB:       .string "lb";		#
string_OP_LH:       .string "lh";		#
string_OP_LW:       .string "lw";		#
string_OP_LBU:      .string "lbu";		#
string_OP_LHU:      .string "lhu";		#
string_OP_SB:       .string "sb";		#
string_OP_SH:       .string "sh";		#
string_OP_SW:       .string "sw";		#
string_OP_ADDI:     .string "addi";		#
string_OP_SLTI:     .string "slti";		#
string_OP_SLTIU:    .string "sltiu";	#
string_OP_XORI:     .string "xori";		#
string_OP_ORI:      .string "ori";		#
string_OP_ANDI:     .string "andi";		#
string_OP_SLLI:     .string "slli";		#
string_OP_SRLI:     .string "srli";		#
string_OP_SRAI:     .string "srai";		#
string_OP_ADD:      .string "add";		#
string_OP_SUB:      .string "sub";		#
string_OP_SLL:      .string "sll";		#
string_OP_SLT:      .string "slt";		#
string_OP_SLTU:     .string "sltu";		#
string_OP_XOR:      .string "xor";		#
string_OP_SRL:      .string "srl";		#
string_OP_SRA:      .string "sra";		#
string_OP_OR:       .string "or";		#
string_OP_AND:      .string "and";		#
string_OP_FENCE:    .string "fence";	#
string_OP_ECALL:    .string "ecall";	#
string_OP_EBREAK:   .string "ebreak";	#


# RV64I
#if XLEN >=64
	string_OP_LWU:      .string "lwu";		#
	string_OP_LD:       .string "ld";		#
	string_OP_SD:       .string "sd";		#
	string_OP_ADDIW:    .string "addiw";	#
	string_OP_SLLIW:    .string "slliw";	#
	string_OP_SRLIW:    .string "srliw";	#
	string_OP_SRAIW:    .string "sraiw";	#
	string_OP_ADDW:     .string "addw";		#
	string_OP_SUBW:     .string "subw";		#
	string_OP_SLLW:     .string "sllw";		#
	string_OP_SRLW:     .string "srlw";		#
	string_OP_SRAW:     .string "sraw";		#
#endif


# RVM
#ifdef ENABLE_RVM
	# RV32M
	string_OP_MUL:      .string "mul";		#	
	string_OP_MULH:     .string "mulh";		#	
	string_OP_MULHU:    .string "mulhu";	#	
	string_OP_MULHSU:   .string "mulhsu";	#
	string_OP_DIV:      .string "div";		#	
	string_OP_DIVU:     .string "divu";		#
	string_OP_REM:      .string "rem";		#	
	string_OP_REMU:     .string "remu";		#
	
	# RV64M
	#if XLEN >=64
		string_OP_MULW:     .string "mulw";		#
		string_OP_DIVW:     .string "divw";		#
		string_OP_DIVUW:    .string "divuw";	#
		string_OP_REMW:     .string "remw";		#	
		string_OP_REMUW:    .string "remuw";	#
	#endif
#endif /* ENABLE_RVM */


# RVA
#ifdef ENABLE_RVA
	# RV32A
	string_OP_LRW:		.string "lr.w";	
	string_OP_SCW:		.string "sc.w";	
	string_OP_AMOSWAPW:	.string "amoswap.w";	
	string_OP_AMOADDW:	.string "amoadd.w";	
	string_OP_AMOANDW:	.string "amoand.w";	
	string_OP_AMOORW:	.string "amoor.w";	
	string_OP_AMOXORW:	.string "amoxor.w";	
	string_OP_AMOMAXW:	.string "amomax.w";	
	string_OP_AMOMINW:	.string "amomin.w";	
	string_OP_AMOMAXUW:	.string "amomaxu.w";	
	string_OP_AMOMINUW:	.string "amominu.w";	
	
	# RV64A
	#if XLEN >= 64
		string_OP_LRD:		.string "lr.d";	
		string_OP_SCD:		.string "sc.d";	
		string_OP_AMOSWAPD:	.string "amoswap.d";	
		string_OP_AMOADDD:	.string "amoadd.d";	
		string_OP_AMOANDD:	.string "amoand.d";	
		string_OP_AMOORD:	.string "amoor.d";	
		string_OP_AMOXORD:	.string "amoxor.d";	
		string_OP_AMOMAXD:	.string "amomax.d";	
		string_OP_AMOMIND:	.string "amomin.d";	
		string_OP_AMOMAXUD:	.string "amomaxu.d";	
		string_OP_AMOMINUD:	.string "amominu.d";	
	#endif
#endif /* ENABLE_RVA */

# Zifencei
string_OP_FENCE_I:  .string "fence.i";	#


# Zicsr
string_OP_CSRRW:    .string "csrrw";	#	
string_OP_CSRRS:    .string "csrrs";	#
string_OP_CSRRC:    .string "csrrc";	#
string_OP_CSRRWI:   .string "csrrwi";	#
string_OP_CSRRSI:   .string "csrrsi";	#
string_OP_CSRRCI:	.string "csrrci";	#


# RVC

# Pseudo
#ifdef ENABLE_PSEUDO
	string_OP_RET:		.string "ret";	
	string_OP_NOP:		.string "nop";	
#endif /* ENABLE_PSEUDO */
.size string_opcodes, .-string_opcodes


.align 4

encoding_table:
# format: MASK, MATCH, decode function ptr, opcode string

# pseudo opcodes
# order is important, these have to be at the beginning of the table
#ifdef ENABLE_PSEUDO
	.word 0xffffffff, 0x00008067, decode_EMPTY, string_OP_RET
	.word 0xffffffff, 0x00000013, decode_EMPTY, string_OP_NOP
#endif /* ENABLE_PSEUDO */

# RV32I
.word MASK_ADD, MATCH_ADD, decode_R_type, string_OP_ADD
.word MASK_SUB, MATCH_SUB, decode_R_type, string_OP_SUB
.word MASK_XOR, MATCH_XOR, decode_R_type, string_OP_XOR
.word MASK_OR, MATCH_OR, decode_R_type, string_OP_OR
.word MASK_AND, MATCH_AND, decode_R_type, string_OP_AND
.word MASK_SLL, MATCH_SLL, decode_R_type, string_OP_SLL
.word MASK_SRL, MATCH_SRL, decode_R_type, string_OP_SRL
.word MASK_SRA, MATCH_SRA, decode_R_type, string_OP_SRA
.word MASK_SLT, MATCH_SLT, decode_R_type, string_OP_SLT
.word MASK_SLTU, MATCH_SLTU, decode_R_type, string_OP_SLTU
.word MASK_ADDI, MATCH_ADDI, decode_I_type, string_OP_ADDI
.word MASK_XORI, MATCH_XORI, decode_I_type, string_OP_XORI
.word MASK_ORI, MATCH_ORI, decode_I_type, string_OP_ORI
.word MASK_ANDI, MATCH_ANDI, decode_I_type, string_OP_ANDI
.word MASK_SLLI, MATCH_SLLI, decode_I_type_SHIFT, string_OP_SLLI
.word MASK_SRLI, MATCH_SRLI, decode_I_type_SHIFT, string_OP_SRLI
.word MASK_SRAI, MATCH_SRAI, decode_I_type_SHIFT, string_OP_SRAI
.word MASK_SLTI, MATCH_SLTI, decode_I_type, string_OP_SLTI
.word MASK_SLTIU, MATCH_SLTIU, decode_I_type, string_OP_SLTIU
.word MASK_LB, MATCH_LB, decode_I_type_LOAD, string_OP_LB
.word MASK_LH, MATCH_LH, decode_I_type_LOAD, string_OP_LH
.word MASK_LW, MATCH_LW, decode_I_type_LOAD, string_OP_LW
.word MASK_LBU, MATCH_LBU, decode_I_type_LOAD, string_OP_LBU
.word MASK_LHU, MATCH_LHU, decode_I_type_LOAD, string_OP_LHU
.word MASK_SB, MATCH_SB, decode_S_type, string_OP_SB
.word MASK_SH, MATCH_SH, decode_S_type, string_OP_SH 
.word MASK_SW, MATCH_SW, decode_S_type, string_OP_SW
.word MASK_BEQ, MATCH_BEQ, decode_B_type, string_OP_BEQ
.word MASK_BNE, MATCH_BNE, decode_B_type, string_OP_BNE
.word MASK_BLT, MATCH_BLT, decode_B_type, string_OP_BLT
.word MASK_BGE, MATCH_BGE, decode_B_type, string_OP_BGE
.word MASK_BLTU, MATCH_BLTU, decode_B_type, string_OP_BLTU
.word MASK_BGEU, MATCH_BGEU, decode_B_type, string_OP_BGEU
.word MASK_JAL, MATCH_JAL, decode_JAL, string_OP_JAL
.word MASK_JALR, MATCH_JALR, decode_JALR, string_OP_JALR
.word MASK_LUI, MATCH_LUI, decode_U_type, string_OP_LUI
.word MASK_AUIPC, MATCH_AUIPC, decode_U_type, string_OP_AUIPC
.word MASK_ECALL, MATCH_ECALL, decode_ECALL, string_OP_ECALL
.word MASK_EBREAK, MATCH_EBREAK, decode_EBREAK, string_OP_EBREAK

# RV64I
#if XLEN >= 64
	.word MASK_ADDIW, MATCH_ADDIW, decode_I_type, string_OP_ADDIW
	.word MASK_SLLIW, MATCH_SLLIW, decode_I_type_SHIFT, string_OP_SLLIW
	.word MASK_SRLIW, MATCH_SRLIW, decode_I_type_SHIFT, string_OP_SRLIW
	.word MASK_SRAIW, MATCH_SRAIW, decode_I_type_SHIFT, string_OP_SRAIW
	.word MASK_ADDW, MATCH_ADDW, decode_R_type, string_OP_ADDW
	.word MASK_SUBW, MATCH_SUBW, decode_R_type, string_OP_SUBW
	.word MASK_SLLW, MATCH_SLLW, decode_R_type, string_OP_SLLW
	.word MASK_SRLW, MATCH_SRLW, decode_R_type, string_OP_SRLW
	.word MASK_SRAW, MATCH_SRAW, decode_R_type, string_OP_SRAW
	.word MASK_LD, MATCH_LD, decode_I_type_LOAD, string_OP_LD
	.word MASK_LWU, MATCH_LWU, decode_I_type_LOAD, string_OP_LWU
	.word MASK_SD, MATCH_SD, decode_S_type, string_OP_SD
	.word MASK_FENCE, MATCH_FENCE, decode_FENCE, string_OP_FENCE
#endif

# RVM
#ifdef ENABLE_RVM
	# RV32M
	.word MASK_MUL, MATCH_MUL, decode_R_type, string_OP_MUL
	.word MASK_MULH, MATCH_MULH, decode_R_type, string_OP_MULH
	.word MASK_MULHSU, MATCH_MULHSU, decode_R_type, string_OP_MULHSU
	.word MASK_MULHU, MATCH_MULHU, decode_R_type, string_OP_MULHU
	.word MASK_DIV, MATCH_DIV, decode_R_type, string_OP_DIV
	.word MASK_DIVU, MATCH_DIVU, decode_R_type, string_OP_DIVU
	.word MASK_REM, MATCH_REM, decode_R_type, string_OP_REM
	.word MASK_REMU, MATCH_REMU, decode_R_type, string_OP_REMU

	# RV64M
	#if XLEN >= 64
		.word MASK_MULW, MATCH_MULW, decode_R_type, string_OP_MULW
		.word MASK_DIVW, MATCH_DIVW, decode_R_type, string_OP_DIVW
		.word MASK_DIVUW, MATCH_DIVUW, decode_R_type, string_OP_DIVUW
		.word MASK_REMW, MATCH_REMW, decode_R_type, string_OP_REMW
		.word MASK_REMUW, MATCH_REMUW, decode_R_type, string_OP_REMUW
	#endif
#endif /* ENABLE_RVM */

# RVA
#ifdef ENABLE_RVA
	# RV32A
	.word MASK_LR_W, MATCH_LR_W, decode_LRSC, string_OP_LRW
	.word MASK_SC_W, MATCH_SC_W, decode_LRSC, string_OP_SCW
	.word MASK_AMOSWAP_W, MATCH_AMOSWAP_W, decode_AMO, string_OP_AMOSWAPW
	.word MASK_AMOADD_W, MATCH_AMOADD_W, decode_AMO, string_OP_AMOADDW
	.word MASK_AMOAND_W, MATCH_AMOAND_W, decode_AMO, string_OP_AMOANDW
	.word MASK_AMOOR_W, MATCH_AMOOR_W, decode_AMO, string_OP_AMOORW
	.word MASK_AMOXOR_W, MATCH_AMOXOR_W, decode_AMO, string_OP_AMOXORW
	.word MASK_AMOMAX_W, MATCH_AMOMAX_W, decode_AMO, string_OP_AMOMAXW
	.word MASK_AMOMIN_W, MATCH_AMOMIN_W, decode_AMO, string_OP_AMOMINW
	.word MASK_AMOMAXU_W, MATCH_AMOMAXU_W, decode_AMO, string_OP_AMOMAXUW
	.word MASK_AMOMINU_W, MATCH_AMOMINU_W, decode_AMO, string_OP_AMOMINUW

	# RV64A
	#if XLEN >= 64
		.word MASK_LR_D, MATCH_LR_D, decode_LRSC, string_OP_LRD
		.word MASK_SC_D, MATCH_SC_D, decode_LRSC, string_OP_SCD
		.word MASK_AMOSWAP_D, MATCH_AMOSWAP_D, decode_AMO, string_OP_AMOSWAPD
		.word MASK_AMOADD_D, MATCH_AMOADD_D, decode_AMO, string_OP_AMOADDD
		.word MASK_AMOAND_D, MATCH_AMOAND_D, decode_AMO, string_OP_AMOANDD
		.word MASK_AMOOR_D, MATCH_AMOOR_D, decode_AMO, string_OP_AMOORD
		.word MASK_AMOXOR_D, MATCH_AMOXOR_D, decode_AMO, string_OP_AMOXORD
		.word MASK_AMOMAX_D, MATCH_AMOMAX_D, decode_AMO, string_OP_AMOMAXD
		.word MASK_AMOMIN_D, MATCH_AMOMIN_D, decode_AMO, string_OP_AMOMIND
		.word MASK_AMOMAXU_D, MATCH_AMOMAXU_D, decode_AMO, string_OP_AMOMAXUD
		.word MASK_AMOMINU_D, MATCH_AMOMINU_D, decode_AMO, string_OP_AMOMINUD
	#endif
#endif /* ENABLE_RVA */

# Zifencei
.word MASK_FENCE_I, MATCH_FENCE_I, decode_FENCE_I, string_OP_FENCE_I

# Zicsr
.word MASK_CSRRW, MATCH_CSRRW, decode_CSR, string_OP_CSRRW
.word MASK_CSRRS, MATCH_CSRRS, decode_CSR, string_OP_CSRRS
.word MASK_CSRRC, MATCH_CSRRC, decode_CSR, string_OP_CSRRC
.word MASK_CSRRWI, MATCH_CSRRWI, decode_CSRI, string_OP_CSRRWI
.word MASK_CSRRSI, MATCH_CSRRSI, decode_CSRI, string_OP_CSRRSI
.word MASK_CSRRCI, MATCH_CSRRCI, decode_CSRI, string_OP_CSRRCI

# table end marker
.word 0, 0, 0, 0
.size encoding_table, .-encoding_table

#endif /* WITH_CMD_D */
