#include "vmon/config.h"
#include "riscv/riscv-opc.h"

#ifdef WITH_CMD_D

.global encoding_table
.global int_register_names
.global float_register_names
.global string_OP_UNKNOWN

.data

.align 4
int_register_names:
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
.size int_register_names, .-int_register_names


#ifdef ENABLE_RVF
	.align 4
	float_register_names:
	#ifndef ABI_REGISTER_NAMES
		.string  "f0",  "f1",  "f2",  "f3",  "f4",  "f5",  "f6",  "f7"
		.string  "f8",  "f9", "f10", "f11", "f12", "f13", "f14", "f15"
		.string "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23"
		.string "f24", "f25", "f26", "f27", "f28", "f29", "f30", "f31"
	#else
		.string "ft0", "ft1",  "ft2",  "ft3", "ft4", "ft5",  "ft6",  "ft7"
		.string "fs0", "fs1",  "fa0",  "fa1", "fa2", "fa3",  "fa4",  "fa5"
		.string "fa6", "fa7",  "fs2",  "fs3", "fs4", "fs5",  "fs6",  "fs7"
		.string "fs8", "fs9", "fs10", "fs11", "ft8", "ft9", "ft10", "ft11"
	#endif
	.size float_register_names, .-float_register_names
#endif /* ENABLE_RVF */

# ---------- opcode strings ----------

# RV32I
string_opcodes:
string_OP_LUI:      .string "lui";		
string_OP_AUIPC:    .string "auipc";		
string_OP_JAL:      .string "jal";		
string_OP_JALR:     .string "jalr";		
string_OP_BEQ:      .string "beq";		
string_OP_BNE:      .string "bne";		
string_OP_BLT:      .string "blt";		
string_OP_BGE:      .string "bge";		
string_OP_BLTU:     .string "bltu";		
string_OP_BGEU:     .string "bgeu";		
string_OP_LB:       .string "lb";		
string_OP_LH:       .string "lh";		
string_OP_LW:       .string "lw";		
string_OP_LBU:      .string "lbu";		
string_OP_LHU:      .string "lhu";		
string_OP_SB:       .string "sb";		
string_OP_SH:       .string "sh";		
string_OP_SW:       .string "sw";		
string_OP_ADDI:     .string "addi";		
string_OP_SLTI:     .string "slti";		
string_OP_SLTIU:    .string "sltiu";	
string_OP_XORI:     .string "xori";		
string_OP_ORI:      .string "ori";		
string_OP_ANDI:     .string "andi";		
string_OP_SLLI:     .string "slli";		
string_OP_SRLI:     .string "srli";		
string_OP_SRAI:     .string "srai";		
string_OP_ADD:      .string "add";		
string_OP_SUB:      .string "sub";		
string_OP_SLL:      .string "sll";		
string_OP_SLT:      .string "slt";		
string_OP_SLTU:     .string "sltu";		
string_OP_XOR:      .string "xor";		
string_OP_SRL:      .string "srl";		
string_OP_SRA:      .string "sra";		
string_OP_OR:       .string "or";		
string_OP_AND:      .string "and";		
string_OP_FENCE:    .string "fence";	
string_OP_FENCETSO: .string "fence.tso";	
string_OP_ECALL:    .string "ecall";	
string_OP_EBREAK:   .string "ebreak";	

# RV64I
#if XLEN >=64
	string_OP_LWU:      .string "lwu";		
	string_OP_LD:       .string "ld";		
	string_OP_SD:       .string "sd";		
	string_OP_ADDIW:    .string "addiw";	
	string_OP_SLLIW:    .string "slliw";	
	string_OP_SRLIW:    .string "srliw";	
	string_OP_SRAIW:    .string "sraiw";	
	string_OP_ADDW:     .string "addw";		
	string_OP_SUBW:     .string "subw";		
	string_OP_SLLW:     .string "sllw";		
	string_OP_SRLW:     .string "srlw";		
	string_OP_SRAW:     .string "sraw";		
#endif

# RVM
#ifdef ENABLE_RVM
	# RV32M
	string_OP_MUL:      .string "mul";			
	string_OP_MULH:     .string "mulh";			
	string_OP_MULHU:    .string "mulhu";		
	string_OP_MULHSU:   .string "mulhsu";	
	string_OP_DIV:      .string "div";			
	string_OP_DIVU:     .string "divu";		
	string_OP_REM:      .string "rem";			
	string_OP_REMU:     .string "remu";		
	# RV64M
	#if XLEN >=64
		string_OP_MULW:     .string "mulw";		
		string_OP_DIVW:     .string "divw";		
		string_OP_DIVUW:    .string "divuw";	
		string_OP_REMW:     .string "remw";			
		string_OP_REMUW:    .string "remuw";	
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

# RVF / RVD / RVQ
#ifdef ENABLE_RVF
	string_OP_FLW:  		.string "flw";
	string_OP_FSW:  		.string "fsw";
	string_OP_FMADD_S:  	.string "fmadd.s";
	string_OP_FMSUB_S:  	.string "fmsub.s";
	string_OP_FNMADD_S:		.string "fnmadd.s";
	string_OP_FNMSUB_S:		.string "fnmsub.s";
	string_OP_FADD_S:		.string "fadd.s";
	string_OP_FSUB_S:		.string "fsub.s";
	string_OP_FMUL_S:		.string "fmul.s";
	string_OP_FDIV_S:		.string "fdiv.s";
	string_OP_FSQRT_S:		.string "fsqrt.s";
	string_OP_FSGNJ_S:		.string "fsgnj.s";
	string_OP_FSGNJN_S:		.string "fsgnjn.s";
	string_OP_FSGNJX_S:		.string "fsgnjx.s";
	string_OP_FMIN_S:		.string "fmin.s";
	string_OP_FMAX_S:		.string "fmax.s";
	string_OP_FCVT_S_W:		.string "fcvt.s.w";
	string_OP_FCVT_S_WU:	.string "fcvt.s.wu";
	string_OP_FCVT_W_S:		.string "fcvt.w.s";
	string_OP_FCVT_WU_S:	.string "fcvt.wu.s";
	string_OP_FMV_X_S:		.string "fmv.x.w";
	string_OP_FMV_S_X:		.string "fmv.w.x";
	string_OP_FEQ_S:		.string "feq.s";
	string_OP_FLT_S:		.string "flt.s";
	string_OP_FLE_S:		.string "fle.s";
	string_OP_FCLASS_S:		.string "fclass.s";
	#ifdef ENABLE_RVD
		string_OP_FLD:  		.string "fld";
		string_OP_FSD:  		.string "fsd";
		string_OP_FMADD_D:  	.string "fmadd.d";
		string_OP_FMSUB_D:  	.string "fmsub.d";
		string_OP_FNMADD_D:		.string "fnmadd.d";
		string_OP_FNMSUB_D:		.string "fnmsub.d";
		string_OP_FADD_D:		.string "fadd.d";
		string_OP_FSUB_D:		.string "fsub.d";
		string_OP_FMUL_D:		.string "fmul.d";
		string_OP_FDIV_D:		.string "fdiv.d";
		string_OP_FSQRT_D:		.string "fsqrt.d";
		string_OP_FSGNJ_D:		.string "fsgnj.d";
		string_OP_FSGNJN_D:		.string "fsgnjn.d";
		string_OP_FSGNJX_D:		.string "fsgnjx.d";
		string_OP_FMIN_D:		.string "fmin.d";
		string_OP_FMAX_D:		.string "fmax.d";
		string_OP_FCVT_D_W:		.string "fcvt.d.w";
		string_OP_FCVT_D_WU:	.string "fcvt.d.wu";
		string_OP_FCVT_W_D:		.string "fcvt.w.d";
		string_OP_FCVT_WU_D:	.string "fcvt.wu.d";
		string_OP_FMV_X_D:		.string "fmv.x.d";
		string_OP_FMV_D_X:		.string "fmv.d.x";
		string_OP_FEQ_D:		.string "feq.d";
		string_OP_FLT_D:		.string "flt.d";
		string_OP_FLE_D:		.string "fle.d";
		string_OP_FCLASS_D:		.string "fclass.d";
		#ifdef ENABLE_RVQ
			string_OP_FLQ:  		.string "flq";
			string_OP_FSQ:  		.string "fsq";
			string_OP_FMADD_Q:  	.string "fmadd.q";
			string_OP_FMSUB_Q:  	.string "fmsub.q";
			string_OP_FNMADD_Q:		.string "fnmadd.q";
			string_OP_FNMSUB_Q:		.string "fnmsub.q";		
			string_OP_FADD_Q:		.string "fadd.q";
			string_OP_FSUB_Q:		.string "fsub.q";
			string_OP_FMUL_Q:		.string "fmul.q";
			string_OP_FDIV_Q:		.string "fdiv.q";
			string_OP_FSQRT_Q:		.string "fsqrt.q";
			string_OP_FSGNJ_Q:		.string "fsgnj.q";
			string_OP_FSGNJN_Q:		.string "fsgnjn.q";
			string_OP_FSGNJX_Q:		.string "fsgnjx.q";
			string_OP_FMIN_Q:		.string "fmin.q";
			string_OP_FMAX_Q:		.string "fmax.q";
			string_OP_FCVT_Q_W:		.string "fcvt.q.w";
			string_OP_FCVT_Q_WU:	.string "fcvt.q.wu";
			string_OP_FCVT_W_Q:		.string "fcvt.w.q";
			string_OP_FCVT_WU_Q:	.string "fcvt.wu.q";
			#if XLEN >=128
				string_OP_FMV_X_Q:		.string "fmv.x.q";
				string_OP_FMV_Q_X:		.string "fmv.q.x";
			#endif
			string_OP_FEQ_Q:		.string "feq.q";
			string_OP_FLT_Q:		.string "flt.q";
			string_OP_FLE_Q:		.string "fle.q";
			string_OP_FCLASS_Q:		.string "fclass.q";
		#endif
	#endif /* ENABLE_RVD */
#endif /* ENABLE_RVF */

# Zifencei
#ifdef ENABLE_RVZifencei
	string_OP_FENCE_I:  .string "fence.i";	#
#endif /* ENABLE_RVZifencei */

# Zicsr
#ifdef ENABLE_RVZicsr
	string_OP_CSRRW:    .string "csrrw";		
	string_OP_CSRRS:    .string "csrrs";	
	string_OP_CSRRC:    .string "csrrc";	
	string_OP_CSRRWI:   .string "csrrwi";	
	string_OP_CSRRSI:   .string "csrrsi";	
	string_OP_CSRRCI:	.string "csrrci";	
#endif /* ENABLE_RVZicsr */

# RVC
#ifdef ENABLE_RVC
	string_OP_C_LW:			.string "c.lw";
	string_OP_C_SW:			.string "c.sw";
	string_OP_C_ADDI:		.string "c.addi";
	string_OP_C_JAL:		.string "c.jal";
	string_OP_C_LI:			.string "c.li";
	string_OP_C_LUI:		.string "c.lui";
	string_OP_C_SRLI:		.string "c.srli";
	string_OP_C_SRLI64:		.string "c.srli64";
	string_OP_C_SRAI:		.string "c.srai";
	string_OP_C_SRAI64:		.string "c.srai64";
	string_OP_C_ANDI:		.string "c.andi";
	string_OP_C_SUB:		.string "c.sub";
	string_OP_C_XOR:		.string "c.xor";
	string_OP_C_OR:			.string "c.or";
	string_OP_C_AND:		.string "c.and";
	string_OP_C_SUBW:		.string "c.subw";
	string_OP_C_ADDW:		.string "c.addw";
	string_OP_C_J:			.string "c.j";
	string_OP_C_BEQZ:		.string "c.beqz";
	string_OP_C_BNEZ:		.string "c.bnez";
	string_OP_C_SLLI:		.string "c.slli";
	string_OP_C_SLLI64:		.string "c.slli64";
	string_OP_C_LWSP:		.string "c.lwsp";
	string_OP_C_MV:			.string "c.mv";
	string_OP_C_ADD:		.string "c.add";
	string_OP_C_SWSP:		.string "c.swsp";
	string_OP_C_NOP:		.string "c.nop";
	string_OP_C_ADDI16SP:	.string "c.addi16sp";
	string_OP_C_JR:			.string "c.jr";
	string_OP_C_JALR:		.string "c.jalr";
	string_OP_C_EBREAK:		.string "c.ebreak";
	string_OP_C_LD:			.string "c.ld";
	string_OP_C_SD:			.string "c.sd";
	string_OP_C_ADDIW:		.string "c.addiw";
	string_OP_C_LDSP:		.string "c.ldsp";
	string_OP_C_SDSP:		.string "c.sdsp";
	#ifdef ENABLE_RVF
		string_OP_C_FLD:		.string "c.fld";
		string_OP_C_FSD:		.string "c.fsd";
		string_OP_C_FLW:		.string "c.flw";
		string_OP_C_FSW:		.string "c.fsw";
		string_OP_C_FLDSP:		.string "c.fldsp";
		string_OP_C_FLWSP:		.string "c.flwsp";
		string_OP_C_FSDSP:		.string "c.fsdsp";
		string_OP_C_FSWSP:		.string "c.fswsp";
	#endif /* ENABLE_RVF */
#endif /* ENABLE_RVC */

# Pseudo
#ifdef ENABLE_PSEUDO
	string_OP_RET:		.string "ret";	
	string_OP_NOP:		.string "nop";	
#endif /* ENABLE_PSEUDO */

# Pseudo
#ifdef ENABLE_RVPRIV
	string_OP_WFI:			.string "wfi";	
	string_OP_MRET:			.string "mret";	
	string_OP_SRET:			.string "sret";	
	string_OP_SFENCE_VM:	.string "sfence.vm";	
	string_OP_SFENCE_VMA:	.string "sfence.vma";	
#endif /* ENABLE_PSEUDO */

.size string_opcodes, .-string_opcodes


# ---------- set up an encoding table  ----------


.align 4

encoding_table:
# format: MASK, MATCH, decode function ptr, opcode string

# pseudo opcodes
# order is important, these have to be at the beginning of the table
#ifdef ENABLE_PSEUDO
	.word 0xffffffff, 0x00008067, decode_EMPTY, string_OP_RET
	.word 0xffffffff, 0x00000013, decode_EMPTY, string_OP_NOP
	#ifdef ENABLE_RVC
		.word 0x0000ffff, 0x0001, decode_EMPTY, string_OP_C_NOP
	#endif /* ENABLE_RVC */
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
.word MASK_JALR, MATCH_JALR, decode_I_type_LOAD, string_OP_JALR
.word MASK_LUI, MATCH_LUI, decode_U_type, string_OP_LUI
.word MASK_AUIPC, MATCH_AUIPC, decode_U_type, string_OP_AUIPC
.word MASK_ECALL, MATCH_ECALL, decode_ECALL, string_OP_ECALL
.word MASK_EBREAK, MATCH_EBREAK, decode_EBREAK, string_OP_EBREAK
.word MASK_FENCETSO, MATCH_FENCETSO, decode_FENCE_TSO, string_OP_FENCETSO
.word MASK_FENCE, MATCH_FENCE, decode_FENCE, string_OP_FENCE
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

# RVF / RVD / RVQ
#ifdef ENABLE_RVF
	.word MASK_FLW, MATCH_FLW, decode_FL, string_OP_FLW
	.word MASK_FSW, MATCH_FSW, decode_FS, string_OP_FSW
	.word MASK_FMADD_S, MATCH_FMADD_S, decode_FMA, string_OP_FMADD_S
	.word MASK_FMSUB_S, MATCH_FMSUB_S, decode_FMA, string_OP_FMSUB_S
	.word MASK_FNMADD_S, MATCH_FNMADD_S, decode_FMA, string_OP_FNMADD_S
	.word MASK_FNMSUB_S, MATCH_FNMSUB_S, decode_FMA, string_OP_FNMSUB_S
	.word MASK_FADD_S, MATCH_FADD_S, decode_FADD, string_OP_FADD_S
	.word MASK_FSUB_S, MATCH_FSUB_S, decode_FADD, string_OP_FSUB_S
	.word MASK_FMUL_S, MATCH_FMUL_S, decode_FADD, string_OP_FMUL_S
	.word MASK_FDIV_S, MATCH_FDIV_S, decode_FADD, string_OP_FDIV_S
	.word MASK_FSQRT_S, MATCH_FSQRT_S, decode_FSQRT, string_OP_FSQRT_S
	.word MASK_FSGNJ_S, MATCH_FSGNJ_S, decode_FADD, string_OP_FSGNJ_S
	.word MASK_FSGNJN_S, MATCH_FSGNJN_S, decode_FADD, string_OP_FSGNJN_S
	.word MASK_FSGNJX_S, MATCH_FSGNJX_S, decode_FADD, string_OP_FSGNJX_S
	.word MASK_FMIN_S, MATCH_FMIN_S, decode_FADD, string_OP_FMIN_S
	.word MASK_FMAX_S, MATCH_FMAX_S, decode_FADD, string_OP_FMAX_S
	.word MASK_FCVT_S_W, MATCH_FCVT_S_W, decode_FCVT_SW, string_OP_FCVT_S_W
	.word MASK_FCVT_S_WU, MATCH_FCVT_S_WU, decode_FCVT_SW, string_OP_FCVT_S_WU
	.word MASK_FCVT_W_S, MATCH_FCVT_W_S, decode_FCVT_WS, string_OP_FCVT_W_S
	.word MASK_FCVT_WU_S, MATCH_FCVT_WU_S, decode_FCVT_WS, string_OP_FCVT_WU_S
	.word MASK_FMV_X_S, MATCH_FMV_X_S, decode_FCVT_WS, string_OP_FMV_X_S
	.word MASK_FMV_S_X, MATCH_FMV_S_X, decode_FCVT_SW, string_OP_FMV_S_X
	.word MASK_FEQ_S, MATCH_FEQ_S, decode_FCMP, string_OP_FEQ_S
	.word MASK_FLT_S, MATCH_FLT_S, decode_FCMP, string_OP_FLT_S
	.word MASK_FLE_S, MATCH_FLE_S, decode_FCMP, string_OP_FLE_S
	.word MASK_FCLASS_S, MATCH_FCLASS_S, decode_FCLASS, string_OP_FCLASS_S
	#ifdef ENABLE_RVD
		.word MASK_FLD, MATCH_FLD, decode_FL, string_OP_FLD
		.word MASK_FSD, MATCH_FSD, decode_FS, string_OP_FSD
		.word MASK_FMADD_D, MATCH_FMADD_D, decode_FMA, string_OP_FMADD_D
		.word MASK_FMSUB_D, MATCH_FMSUB_D, decode_FMA, string_OP_FMSUB_D
		.word MASK_FNMADD_D, MATCH_FNMADD_D, decode_FMA, string_OP_FNMADD_D
		.word MASK_FNMSUB_D, MATCH_FNMSUB_D, decode_FMA, string_OP_FNMSUB_D
		.word MASK_FADD_D, MATCH_FADD_D, decode_FADD, string_OP_FADD_D
		.word MASK_FSUB_D, MATCH_FSUB_D, decode_FADD, string_OP_FSUB_D
		.word MASK_FMUL_D, MATCH_FMUL_D, decode_FADD, string_OP_FMUL_D
		.word MASK_FDIV_D, MATCH_FDIV_D, decode_FADD, string_OP_FDIV_D
		.word MASK_FSQRT_D, MATCH_FSQRT_D, decode_FSQRT, string_OP_FSQRT_D
		.word MASK_FSGNJ_D, MATCH_FSGNJ_D, decode_FADD, string_OP_FSGNJ_D
		.word MASK_FSGNJN_D, MATCH_FSGNJN_D, decode_FADD, string_OP_FSGNJN_D
		.word MASK_FSGNJX_D, MATCH_FSGNJX_D, decode_FADD, string_OP_FSGNJX_D
		.word MASK_FMIN_D, MATCH_FMIN_D, decode_FADD, string_OP_FMIN_D
		.word MASK_FMAX_D, MATCH_FMAX_D, decode_FADD, string_OP_FMAX_D
		.word MASK_FCVT_D_W, MATCH_FCVT_D_W, decode_FCVT_SW, string_OP_FCVT_D_W
		.word MASK_FCVT_D_WU, MATCH_FCVT_D_WU, decode_FCVT_SW, string_OP_FCVT_D_WU
		.word MASK_FCVT_W_D, MATCH_FCVT_W_D, decode_FCVT_WS, string_OP_FCVT_W_D
		.word MASK_FCVT_WU_D, MATCH_FCVT_WU_D, decode_FCVT_WS, string_OP_FCVT_WU_D
		.word MASK_FMV_X_D, MATCH_FMV_X_D, decode_FCVT_WS, string_OP_FMV_X_D
		.word MASK_FMV_D_X, MATCH_FMV_D_X, decode_FCVT_SW, string_OP_FMV_D_X
		.word MASK_FEQ_D, MATCH_FEQ_D, decode_FCMP, string_OP_FEQ_D
		.word MASK_FLT_D, MATCH_FLT_D, decode_FCMP, string_OP_FLT_D
		.word MASK_FLE_D, MATCH_FLE_D, decode_FCMP, string_OP_FLE_D
		.word MASK_FCLASS_D, MATCH_FCLASS_D, decode_FCLASS, string_OP_FCLASS_D
		#ifdef ENABLE_RVQ
			.word MASK_FLQ, MATCH_FLQ, decode_FL, string_OP_FLQ
			.word MASK_FSQ, MATCH_FSQ, decode_FS, string_OP_FSQ
			.word MASK_FMADD_Q, MATCH_FMADD_Q, decode_FMA, string_OP_FMADD_Q
			.word MASK_FMSUB_Q, MATCH_FMSUB_Q, decode_FMA, string_OP_FMSUB_Q
			.word MASK_FNMADD_Q, MATCH_FNMADD_Q, decode_FMA, string_OP_FNMADD_Q
			.word MASK_FNMSUB_Q, MATCH_FNMSUB_Q, decode_FMA, string_OP_FNMSUB_Q		
			.word MASK_FADD_Q, MATCH_FADD_Q, decode_FADD, string_OP_FADD_Q
			.word MASK_FSUB_Q, MATCH_FSUB_Q, decode_FADD, string_OP_FSUB_Q
			.word MASK_FMUL_Q, MATCH_FMUL_Q, decode_FADD, string_OP_FMUL_Q
			.word MASK_FDIV_Q, MATCH_FDIV_Q, decode_FADD, string_OP_FDIV_Q
			.word MASK_FSQRT_Q, MATCH_FSQRT_Q, decode_FSQRT, string_OP_FSQRT_Q
			.word MASK_FSGNJ_Q, MATCH_FSGNJ_Q, decode_FADD, string_OP_FSGNJ_Q
			.word MASK_FSGNJN_Q, MATCH_FSGNJN_Q, decode_FADD, string_OP_FSGNJN_Q
			.word MASK_FSGNJX_Q, MATCH_FSGNJX_Q, decode_FADD, string_OP_FSGNJX_Q
			.word MASK_FMIN_Q, MATCH_FMIN_Q, decode_FADD, string_OP_FMIN_Q
			.word MASK_FMAX_Q, MATCH_FMAX_Q, decode_FADD, string_OP_FMAX_Q
			.word MASK_FCVT_Q_W, MATCH_FCVT_Q_W, decode_FCVT_SW, string_OP_FCVT_Q_W
			.word MASK_FCVT_Q_WU, MATCH_FCVT_Q_WU, decode_FCVT_SW, string_OP_FCVT_Q_WU
			.word MASK_FCVT_W_Q, MATCH_FCVT_W_Q, decode_FCVT_WS, string_OP_FCVT_W_Q
			.word MASK_FCVT_WU_Q, MATCH_FCVT_WU_Q, decode_FCVT_WS, string_OP_FCVT_WU_Q
			#if XLEN >=128
				.word MASK_FMV_X_Q, MATCH_FMV_X_Q, decode_FCVT_WS, string_OP_FMV_X_Q
				.word MASK_FMV_Q_X, MATCH_FMV_Q_X, decode_FCVT_SW, string_OP_FMV_Q_X
			#endif
			.word MASK_FEQ_Q, MATCH_FEQ_Q, decode_FCMP, string_OP_FEQ_Q
			.word MASK_FLT_Q, MATCH_FLT_Q, decode_FCMP, string_OP_FLT_Q
			.word MASK_FLE_Q, MATCH_FLE_Q, decode_FCMP, string_OP_FLE_Q
			.word MASK_FCLASS_Q, MATCH_FCLASS_Q, decode_FCLASS, string_OP_FCLASS_Q
		#endif /* ENABLE_RVQ */
	#endif /* ENABLE_RVD */
#endif /* ENABLE_RVF */

# RVC
#ifdef ENABLE_RVC
	.word MASK_C_LW, MATCH_C_LW, decode_EMPTY, string_OP_C_LW
	.word MASK_C_SW, MATCH_C_SW, decode_EMPTY, string_OP_C_SW
	.word MASK_C_ADDI, MATCH_C_ADDI, decode_EMPTY, string_OP_C_ADDI
	.word MASK_C_JAL, MATCH_C_JAL, decode_EMPTY, string_OP_C_JAL
	.word MASK_C_LI, MATCH_C_LI, decode_EMPTY, string_OP_C_LI
	.word MASK_C_LUI, MATCH_C_LUI, decode_EMPTY, string_OP_C_LUI
	.word MASK_C_SRLI, MATCH_C_SRLI, decode_EMPTY, string_OP_C_SRLI
	.word MASK_C_SRLI64, MATCH_C_SRLI64, decode_EMPTY, string_OP_C_SRLI64
	.word MASK_C_SRAI, MATCH_C_SRAI, decode_EMPTY, string_OP_C_SRAI
	.word MASK_C_SRAI64, MATCH_C_SRAI64, decode_EMPTY, string_OP_C_SRAI64
	.word MASK_C_ANDI, MATCH_C_ANDI, decode_EMPTY, string_OP_C_ANDI
	.word MASK_C_SUB, MATCH_C_SUB, decode_EMPTY, string_OP_C_SUB
	.word MASK_C_XOR, MATCH_C_XOR, decode_EMPTY, string_OP_C_XOR
	.word MASK_C_OR, MATCH_C_OR, decode_EMPTY, string_OP_C_OR
	.word MASK_C_AND, MATCH_C_AND, decode_EMPTY, string_OP_C_AND
	.word MASK_C_SUBW, MATCH_C_SUBW, decode_EMPTY, string_OP_C_SUBW
	.word MASK_C_ADDW, MATCH_C_ADDW, decode_EMPTY, string_OP_C_ADDW
	.word MASK_C_J, MATCH_C_J, decode_EMPTY, string_OP_C_J
	.word MASK_C_BEQZ, MATCH_C_BEQZ, decode_EMPTY, string_OP_C_BEQZ
	.word MASK_C_BNEZ, MATCH_C_BNEZ, decode_EMPTY, string_OP_C_BNEZ
	.word MASK_C_SLLI, MATCH_C_SLLI, decode_EMPTY, string_OP_C_SLLI
	.word MASK_C_SLLI64, MATCH_C_SLLI64, decode_EMPTY, string_OP_C_SLLI64
	.word MASK_C_LWSP, MATCH_C_LWSP, decode_C_LWSP, string_OP_C_LWSP
	.word MASK_C_MV, MATCH_C_MV, decode_EMPTY, string_OP_C_MV
	.word MASK_C_ADD, MATCH_C_ADD, decode_EMPTY, string_OP_C_ADD
	.word MASK_C_SWSP, MATCH_C_SWSP, decode_EMPTY, string_OP_C_SWSP
	.word MASK_C_NOP, MATCH_C_NOP, decode_EMPTY, string_OP_C_NOP
	.word MASK_C_ADDI16SP, MATCH_C_ADDI16SP, decode_EMPTY, string_OP_C_ADDI16SP
	.word MASK_C_JR, MATCH_C_JR, decode_EMPTY, string_OP_C_JR
	.word MASK_C_JALR, MATCH_C_JALR, decode_EMPTY, string_OP_C_JALR
	.word MASK_C_EBREAK, MATCH_C_EBREAK, decode_C_EBREAK, string_OP_C_EBREAK
	.word MASK_C_LD, MATCH_C_LD, decode_EMPTY, string_OP_C_LD
	.word MASK_C_SD, MATCH_C_SD, decode_EMPTY, string_OP_C_SD
	.word MASK_C_ADDIW, MATCH_C_ADDIW, decode_EMPTY, string_OP_C_ADDIW
	.word MASK_C_LDSP, MATCH_C_LDSP, decode_EMPTY, string_OP_C_LDSP
	.word MASK_C_SDSP, MATCH_C_SDSP, decode_EMPTY, string_OP_C_SDSP
	#ifdef ENABLE_RVF
		.word MASK_C_FLD, MATCH_C_FLD, decode_EMPTY, string_OP_C_FLD
		.word MASK_C_FSD, MATCH_C_FSD, decode_EMPTY, string_OP_C_FSD
		.word MASK_C_FLW, MATCH_C_FLW, decode_EMPTY, string_OP_C_FLW
		.word MASK_C_FSW, MATCH_C_FSW, decode_EMPTY, string_OP_C_FSW
		.word MASK_C_FLWSP, MATCH_C_FLWSP, decode_EMPTY, string_OP_C_FLWSP
		.word MASK_C_FSWSP, MATCH_C_FSWSP, decode_EMPTY, string_OP_C_FSWSP	
		.word MASK_C_FLDSP, MATCH_C_FLDSP, decode_EMPTY, string_OP_C_FLDSP
		.word MASK_C_FSDSP, MATCH_C_FSDSP, decode_EMPTY, string_OP_C_FSDSP
	#endif /* ENABLE_RVF */
#endif /* ENABLE_RVC */

# Zifencei
#ifdef ENABLE_RVZifencei
	.word MASK_FENCE_I, MATCH_FENCE_I, decode_FENCE_I, string_OP_FENCE_I
#endif /* ENABLE_RVZifencei */

# Zicsr
#ifdef ENABLE_RVZicsr
	.word MASK_CSRRW, MATCH_CSRRW, decode_CSR, string_OP_CSRRW
	.word MASK_CSRRS, MATCH_CSRRS, decode_CSR, string_OP_CSRRS
	.word MASK_CSRRC, MATCH_CSRRC, decode_CSR, string_OP_CSRRC
	.word MASK_CSRRWI, MATCH_CSRRWI, decode_CSRI, string_OP_CSRRWI
	.word MASK_CSRRSI, MATCH_CSRRSI, decode_CSRI, string_OP_CSRRSI
	.word MASK_CSRRCI, MATCH_CSRRCI, decode_CSRI, string_OP_CSRRCI
#endif /* ENABLE_RVZicsr */

# Privileged
#ifdef ENABLE_RVPRIV
	.word MASK_WFI, MATCH_WFI, decode_WFI, string_OP_WFI
	.word MASK_MRET, MATCH_MRET, decode_MRET, string_OP_MRET
	.word MASK_SRET, MATCH_SRET, decode_SRET, string_OP_SRET
	.word MASK_SFENCE_VM, MATCH_SFENCE_VM, decode_SFENCE_VM, string_OP_SFENCE_VM
	.word MASK_SFENCE_VMA, MATCH_SFENCE_VMA, decode_SFENCE_VMA, string_OP_SFENCE_VMA
#endif /* ENABLE_RVPRIV */

# table end marker
.word 0, 0, 0, 0
.size encoding_table, .-encoding_table

#endif /* WITH_CMD_D */
