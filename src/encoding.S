#include "vmon/config.h"
#include "riscv/riscv-opc.h"
#include "vmon/encoding.h"


#if defined (WITH_CMD_D) || defined (WITH_CMD_A)


# table with MASK, MATCH, decode_func_ptr, opcode_string, assemble_func_ptr, parameter function ptrs
.global encoding_table
# table access functions
.global get_data_by_insn_name

# tables with register names
.global int_register_names
.global float_register_names
# table access functions
.global get_int_register_name_by_index
.global get_float_register_name_by_index
.global get_int_register_index_by_name
.global get_float_register_index_by_name

.global string_OP_UNKNOWN
# necessary for c.add/c.jalr/c.ebreak adjustment
.global string_OP_C_ADD
.global string_OP_C_JALR
.global string_OP_C_EBREAK


# in: s0 = ptr to search string start
# in: s1 = ptr to last char of search string
# out: a0 = ptr to assemble function (0 if string was not found)
# out: a1 = MATCH value for insn (undefined if string was not found)
# out: a3 = ptr to table entry (undefined if string was not found)
get_data_by_insn_name:
	la		t0, encoding_table
get_data_by_insn_name_next:								# check string in next table entry
	# load values from current table entry
	#if XLEN >= 64
		lwu		a1, ENC_OFF_MATCH(t0)					# store MATCH value from table entry in a1
		lwu		t1, ENC_OFF_OP_STRING(t0)				# get string ptr from table
		lwu		a0, ENC_OFF_FUNC_ASS(t0)				# get function ptr from table
	#else
		lw		a1, ENC_OFF_MATCH(t0)					# store MATCH value from table entry in a1
		lw		t1, ENC_OFF_OP_STRING(t0)				# get string ptr from table
		lw		a0, ENC_OFF_FUNC_ASS(t0)				# get function ptr from table
	#endif
	beqz	t1, get_data_by_insn_name_not_found			# if string in this entry is empty, then table end, no match found
	# compare strings
	mv		t2, s0										# iterate with t2 over search string
get_data_by_insn_name_cmp_next_byte:
	lbu		t3, 0(t2)									# load char from search string
	lbu		t4, 0(t1)									# load char from table string
	beq		t2, s1, get_data_by_insn_name_check			# search string ended, check if match
	bne		t3, t4, get_data_by_insn_name_next_entry	# strings not equal
	beqz	t4, get_data_by_insn_name_next_entry		# string in table ended
	addi	t1, t1, 1
	addi	t2, t2, 1
	j		get_data_by_insn_name_cmp_next_byte
get_data_by_insn_name_next_entry:
	addi	t0, t0, ENC_ENTRY_SIZE						# next table entry
	j		get_data_by_insn_name_next
get_data_by_insn_name_not_found:
	mv		a0, zero
	j 		get_data_by_insn_name_done
get_data_by_insn_name_check:
	lbu		t4, 0(t1)									# check next byte in table string
	bnez	t4, get_data_by_insn_name_next_entry		# if table string did not end yet, no match 
get_data_by_insn_name_done:
	mv		a3, t0										# return also current table entry
	ret
.size get_data_by_insn_name, .-get_data_by_insn_name


get_int_register_name_by_index:
	la		a1, int_register_names
	j 		get_register_name_by_index
.size get_int_register_name_by_index, .-get_int_register_name_by_index


get_float_register_name_by_index:
	la		a1, float_register_names
	j 		get_register_name_by_index
.size get_float_register_name_by_index, .-get_float_register_name_by_index



# return a string ptr to the name of the n-th register
# in:	a0 = n
# in:	a1 = ptr to table (int_register_names or float_register_names)
# out:	a0 = string ptr
get_register_name_by_index:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
get_register_name_by_index_search:
	beqz	a0, get_register_name_by_index_found
	addi	a1, a1, 1
get_register_name_by_index_skip_next_zero:
	lb		t1, 0(a1)
	beqz	t1, get_register_name_by_index_next_zero
	# arrived at zero
	addi	a1, a1, 1
	j		get_register_name_by_index_skip_next_zero
get_register_name_by_index_next_zero:
	addi	a0, a0, -1
	addi	a1, a1, 1
	j		get_register_name_by_index_search
get_register_name_by_index_found:
	mv		a0, a1
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	ret
.size get_register_name_by_index, .-get_register_name_by_index


# return index of int register given by name
# in: a0 = string ptr to start of name
# in: a1 = string ptr to end of name (after last char; no 0-termination expected)
# out: a0 = index number of int register (-1 if error)
get_int_register_index_by_name:
	la		a2, int_register_names
	j 		get_register_index_by_name
.size get_int_register_index_by_name, .-get_int_register_index_by_name


# return index of float register given by name
# in: a0 = string ptr to start of name
# in: a1 = string ptr to end of name (after last char; no 0-termination expected)
# out: a0 = index number of float register (-1 if error)
get_float_register_index_by_name:
	la		a2, float_register_names
	j 		get_register_index_by_name
.size get_float_register_index_by_name, .-get_float_register_index_by_name


# return index of register given by name
# in: a0 = start of string ptr to name
# in: a1 = end of string ptr to name (after last char; no 0-termination expected)
# in: a2 = ptr to table (int_register_names or float_register_names)
# out: a0 = index number of register (-1 if error)
get_register_index_by_name:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	li		a3, 0											# init index counter
	mv		a4, a0											# save a0 for reuse
	li		t0, 32											# max entries in table
get_register_index_by_name_compare_next:
	lb		t1, 0(a0)										# search string byte
	lb		t2, 0(a2)										# table string byte
	beq		t1, t2, get_register_index_by_name_next_char	# chars matched
	# chars are not equal
	beqz	t2, get_register_index_by_name_check1			# register name ended
	bgt		a0, a1, get_register_index_by_name_check2		# search string ended
	# chars did not match and register name did not terminate
	j		get_register_index_by_name_next_reg
get_register_index_by_name_next_char:
	addi	a0, a0,1
	addi	a2, a2,1
	j 		get_register_index_by_name_compare_next
get_register_index_by_name_next_reg:
	mv		a0, a4											# reset search string ptr
get_register_index_by_name_to_reg_end:
	addi	a2, a2, 1										# advance a2 to next reg
	lb		t2, 0(a2)										# table string byte	
	bnez	t2, get_register_index_by_name_to_reg_end		# until 0 reached
	addi	a2, a2, 1										# start of next reg
	addi	a3, a3, 1										# inc index counter
	beq		a3, t0, get_register_index_by_name_not_found	# out of entries
	j 		get_register_index_by_name_compare_next
get_register_index_by_name_check1:
	bgt		a0, a1,	get_register_index_by_name_found
	addi	a3, a3, 1										# entry is prefix of search string
	j		get_register_index_by_name_next_reg
get_register_index_by_name_check2:
	lb		t2, 1(a2)
	beqz	t2, get_register_index_by_name_found
	j		get_register_index_by_name_next_reg
get_register_index_by_name_found:
	mv		a0, a3											# return index counter
	j 		get_register_index_by_name_done
get_register_index_by_name_not_found:
	li		a0, -1											# return error
get_register_index_by_name_done:
	LOAD_X	ra, 0(sp)
	addi	sp, sp, (XLEN_BYTES*1)
	ret
.size get_register_index_by_name, .-get_register_index_by_name


	.data

	.align 4
int_register_names:
#ifndef ABI_REGISTER_NAMES
	.string	 "x0",	"x1",  "x2",  "x3",	 "x4",	"x5",  "x6",  "x7"
	.string	 "x8",	"x9", "x10", "x11", "x12", "x13", "x14", "x15"
	.string "x16", "x17", "x18", "x19", "x20", "x21", "x22", "x23"
	.string "x24", "x25", "x26", "x27", "x28", "x29", "x30", "x31"
#else
	.string "zero", "ra",  "sp",  "gp", "tp", "t0", "t1", "t2"
	.string "fp",	"s1",  "a0",  "a1", "a2", "a3", "a4", "a5"
	.string "a6",	"a7",  "s2",  "s3", "s4", "s5", "s6", "s7"
	.string "s8",	"s9", "s10", "s11", "t3", "t4", "t5", "t6"
#endif
.size int_register_names, .-int_register_names


#ifdef ENABLE_RVF
	.align 4
float_register_names:
#ifndef ABI_REGISTER_NAMES
	.string	 "f0",	"f1",  "f2",  "f3",	 "f4",	"f5",  "f6",  "f7"
	.string	 "f8",	"f9", "f10", "f11", "f12", "f13", "f14", "f15"
	.string "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23"
	.string "f24", "f25", "f26", "f27", "f28", "f29", "f30", "f31"
#else
	.string "ft0", "ft1",  "ft2",  "ft3", "ft4", "ft5",	 "ft6",	 "ft7"
	.string "fs0", "fs1",  "fa0",  "fa1", "fa2", "fa3",	 "fa4",	 "fa5"
	.string "fa6", "fa7",  "fs2",  "fs3", "fs4", "fs5",	 "fs6",	 "fs7"
	.string "fs8", "fs9", "fs10", "fs11", "ft8", "ft9", "ft10", "ft11"
#endif
.size float_register_names, .-float_register_names
#endif /* ENABLE_RVF */

# ---------- opcode strings ----------

# RV32I
string_opcodes:
string_OP_LUI:		.string "lui";
string_OP_AUIPC:	.string "auipc";
string_OP_JAL:		.string "jal";
string_OP_JALR:		.string "jalr";
string_OP_BEQ:		.string "beq";
string_OP_BNE:		.string "bne";
string_OP_BLT:		.string "blt";
string_OP_BGE:		.string "bge";
string_OP_BLTU:		.string "bltu";
string_OP_BGEU:		.string "bgeu";
string_OP_LB:		.string "lb";
string_OP_LH:		.string "lh";
string_OP_LW:		.string "lw";
string_OP_LBU:		.string "lbu";
string_OP_LHU:		.string "lhu";
string_OP_SB:		.string "sb";
string_OP_SH:		.string "sh";
string_OP_SW:		.string "sw";
string_OP_ADDI:		.string "addi";
string_OP_SLTI:		.string "slti";
string_OP_SLTIU:	.string "sltiu";
string_OP_XORI:		.string "xori";
string_OP_ORI:		.string "ori";
string_OP_ANDI:		.string "andi";
string_OP_SLLI:		.string "slli";
string_OP_SRLI:		.string "srli";
string_OP_SRAI:		.string "srai";
string_OP_ADD:		.string "add";
string_OP_SUB:		.string "sub";
string_OP_SLL:		.string "sll";
string_OP_SLT:		.string "slt";
string_OP_SLTU:		.string "sltu";
string_OP_XOR:		.string "xor";
string_OP_SRL:		.string "srl";
string_OP_SRA:		.string "sra";
string_OP_OR:		.string "or";
string_OP_AND:		.string "and";
string_OP_FENCE:	.string "fence";
string_OP_FENCETSO: .string "fence.tso";
string_OP_ECALL:	.string "ecall";
string_OP_EBREAK:	.string "ebreak";

# RV64I
#if XLEN >=64
	string_OP_LWU:		.string "lwu";
	string_OP_LD:		.string "ld";
	string_OP_SD:		.string "sd";
	string_OP_ADDIW:	.string "addiw";
	string_OP_SLLIW:	.string "slliw";
	string_OP_SRLIW:	.string "srliw";
	string_OP_SRAIW:	.string "sraiw";
	string_OP_ADDW:		.string "addw";
	string_OP_SUBW:		.string "subw";
	string_OP_SLLW:		.string "sllw";
	string_OP_SRLW:		.string "srlw";
	string_OP_SRAW:		.string "sraw";
#endif

# RVM
#ifdef ENABLE_RVM
	# RV32M
	string_OP_MUL:		.string "mul";
	string_OP_MULH:		.string "mulh";
	string_OP_MULHU:	.string "mulhu";
	string_OP_MULHSU:	.string "mulhsu";
	string_OP_DIV:		.string "div";
	string_OP_DIVU:		.string "divu";
	string_OP_REM:		.string "rem";
	string_OP_REMU:		.string "remu";
	# RV64M
	#if XLEN >=64
		string_OP_MULW:		.string "mulw";
		string_OP_DIVW:		.string "divw";
		string_OP_DIVUW:	.string "divuw";
		string_OP_REMW:		.string "remw";
		string_OP_REMUW:	.string "remuw";
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
	string_OP_FLW:			.string "flw";
	string_OP_FSW:			.string "fsw";
	string_OP_FMADD_S:		.string "fmadd.s";
	string_OP_FMSUB_S:		.string "fmsub.s";
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
		string_OP_FLD:			.string "fld";
		string_OP_FSD:			.string "fsd";
		string_OP_FMADD_D:		.string "fmadd.d";
		string_OP_FMSUB_D:		.string "fmsub.d";
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
			string_OP_FLQ:			.string "flq";
			string_OP_FSQ:			.string "fsq";
			string_OP_FMADD_Q:		.string "fmadd.q";
			string_OP_FMSUB_Q:		.string "fmsub.q";
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
		#endif /* ENABLE_RVQ */
	#endif /* ENABLE_RVD */
#endif /* ENABLE_RVF */

# Zifencei
#ifdef ENABLE_RVZifencei
	string_OP_FENCE_I:	.string "fence.i";
#endif /* ENABLE_RVZifencei */

# Zicsr
	#ifdef ENABLE_RVZicsr
	string_OP_CSRRW:	.string "csrrw";
	string_OP_CSRRS:	.string "csrrs";
	string_OP_CSRRC:	.string "csrrc";
	string_OP_CSRRWI:	.string "csrrwi";
	string_OP_CSRRSI:	.string "csrrsi";
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
	string_OP_UNIMP:	.string "unimp";	
	#ifdef ENABLE_RVC
		string_OP_C_UNIMP:	.string "c.unimp";	
	#endif
#endif /* ENABLE_PSEUDO */

# Privileged
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
# This encoding table is used to lookup instructions during assembly 
# and disassembly:
# - MASK/MATCH are defined by the RISC-V standard
# - during disassembly, the decode function is called for each 
#   instruction when MASK/MATCH match
# - during assembly, the assemble function is called and calls the 
#   arg1-4 functions to parse the arguments of the user input
#
# format: MASK, MATCH, decode function ptr, opcode string, assemble func ptr, arg1 func ptr, arg2 func ptr, arg3 func ptr, arg4 func ptr

# pseudo opcodes
# order is important, these have to be at the beginning of the table
#ifdef ENABLE_PSEUDO
	#ifdef ENABLE_RVC
		.word 0x0000ffff, 0x0000,	decode_EMPTY,	string_OP_C_UNIMP,	assemble_GENERIC,	0,	0,	0,	0
		.word 0x0000ffff, 0x0001,	decode_EMPTY,	string_OP_C_NOP,	assemble_GENERIC,	0,	0,	0,	0
	#endif /* ENABLE_RVC */
	.word 0xffffffff, 0x00000000,	decode_EMPTY,	string_OP_UNIMP,	assemble_GENERIC,	0,	0,	0,	0
	.word 0xffffffff, 0x00008067,	decode_EMPTY,	string_OP_RET,		assemble_GENERIC,	0,	0,	0,	0
	.word 0xffffffff, 0x00000013,	decode_EMPTY,	string_OP_NOP,		assemble_GENERIC,	0,	0,	0,	0
#endif /* ENABLE_PSEUDO */

# RV32I
# offset in bytes from start of each entry:
#     0					4				8						12					16					20			24			28			32
.word MASK_ADD,			MATCH_ADD,		decode_R_type,			string_OP_ADD,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_SUB,			MATCH_SUB,		decode_R_type,			string_OP_SUB,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_XOR,			MATCH_XOR,		decode_R_type,			string_OP_XOR,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_OR,			MATCH_OR,		decode_R_type,			string_OP_OR,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_AND,			MATCH_AND,		decode_R_type,			string_OP_AND,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_SLL,			MATCH_SLL,		decode_R_type,			string_OP_SLL,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_SRL,			MATCH_SRL,		decode_R_type,			string_OP_SRL,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_SRA,			MATCH_SRA,		decode_R_type,			string_OP_SRA,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_SLT,			MATCH_SLT,		decode_R_type,			string_OP_SLT,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_SLTU,		MATCH_SLTU,		decode_R_type,			string_OP_SLTU,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
.word MASK_ADDI,		MATCH_ADDI,		decode_I_type,			string_OP_ADDI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_XORI,		MATCH_XORI,		decode_I_type,			string_OP_XORI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_ORI,			MATCH_ORI,		decode_I_type,			string_OP_ORI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_ANDI,		MATCH_ANDI,		decode_I_type,			string_OP_ANDI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_SLLI,		MATCH_SLLI,		decode_I_type_SHIFT,	string_OP_SLLI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_SRLI,		MATCH_SRLI,		decode_I_type_SHIFT,	string_OP_SRLI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_SRAI,		MATCH_SRAI,		decode_I_type_SHIFT,	string_OP_SRAI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_SLTI,		MATCH_SLTI,		decode_I_type,			string_OP_SLTI,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_SLTIU,		MATCH_SLTIU,	decode_I_type,			string_OP_SLTIU,	assemble_GENERIC,	ass_rd,		ass_rs1,	ass_I_imm,	0
.word MASK_LB,			MATCH_LB,		decode_I_type_LOAD,		string_OP_LB,		assemble_GENERIC,	ass_rd,		ass_MEM,	0,			0
.word MASK_LH,			MATCH_LH,		decode_I_type_LOAD,		string_OP_LH,		assemble_GENERIC,	ass_rd,		ass_MEM,	0,			0
.word MASK_LW,			MATCH_LW,		decode_I_type_LOAD,		string_OP_LW,		assemble_GENERIC,	ass_rd,		ass_MEM,	0,			0
.word MASK_LBU,			MATCH_LBU, 		decode_I_type_LOAD,		string_OP_LBU,		assemble_GENERIC,	ass_rd,		ass_MEM,	0,			0
.word MASK_LHU,			MATCH_LHU,		decode_I_type_LOAD,		string_OP_LHU, 		assemble_GENERIC,	ass_rd,		ass_MEM,	0,			0
.word MASK_SB,			MATCH_SB,		decode_S_type,			string_OP_SB,		assemble_GENERIC,	ass_rs2,	ass_MEM,	0,			0
.word MASK_SH,			MATCH_SH,		decode_S_type,			string_OP_SH,		assemble_GENERIC,	ass_rs2,	ass_MEM,	0,			0
.word MASK_SW,			MATCH_SW,		decode_S_type,			string_OP_SW,		assemble_GENERIC,	ass_rs2,	ass_MEM,	0,			0
.word MASK_BEQ,			MATCH_BEQ,		decode_B_type,			string_OP_BEQ,		assemble_GENERIC,	ass_rs1,	ass_rs2,	ass_BRA,	0
.word MASK_BNE,			MATCH_BNE,		decode_B_type,			string_OP_BNE,		assemble_GENERIC,	ass_rs1,	ass_rs2,	ass_BRA,	0
.word MASK_BLT,			MATCH_BLT,		decode_B_type,			string_OP_BLT,		assemble_GENERIC,	ass_rs1,	ass_rs2,	ass_BRA,	0
.word MASK_BGE,			MATCH_BGE,		decode_B_type,			string_OP_BGE,		assemble_GENERIC,	ass_rs1,	ass_rs2,	ass_BRA,	0
.word MASK_BLTU,		MATCH_BLTU,		decode_B_type,			string_OP_BLTU,		assemble_GENERIC,	ass_rs1,	ass_rs2,	ass_BRA,	0
.word MASK_BGEU,		MATCH_BGEU,		decode_B_type,			string_OP_BGEU,		assemble_GENERIC,	ass_rs1,	ass_rs2,	ass_BRA,	0
.word MASK_JAL,			MATCH_JAL,		decode_JAL,				string_OP_JAL,		assemble_GENERIC,	ass_rd,		ass_J,		0,			0
.word MASK_JALR,		MATCH_JALR,		decode_I_type_LOAD,		string_OP_JALR,		assemble_GENERIC,	0,			0,			0,			0
.word MASK_LUI,			MATCH_LUI,		decode_U_type,			string_OP_LUI,		assemble_GENERIC,	0,			0,			0,			0
.word MASK_AUIPC,		MATCH_AUIPC,	decode_U_type,			string_OP_AUIPC,	assemble_GENERIC,	0,			0,			0,			0
.word MASK_ECALL,		MATCH_ECALL,	decode_ECALL,			string_OP_ECALL,	assemble_GENERIC,	0,			0,			0,			0
.word MASK_EBREAK,		MATCH_EBREAK,	decode_EBREAK,			string_OP_EBREAK,	assemble_GENERIC,	0,			0,			0,			0
.word MASK_FENCETSO,	MATCH_FENCETSO,	decode_FENCE_TSO,		string_OP_FENCETSO,	assemble_GENERIC,	0,			0,			0,			0
.word MASK_FENCE,		MATCH_FENCE,	decode_FENCE,			string_OP_FENCE,	assemble_GENERIC,	ass_PRE,	ass_SUC,	0,			0

# RV64I
#if XLEN >= 64
	.word MASK_ADDIW,	MATCH_ADDIW,	decode_I_type,			string_OP_ADDIW,	assemble_DUMMY,		0,			0,			0,			0
	.word MASK_SLLIW,	MATCH_SLLIW,	decode_I_type_SHIFT,	string_OP_SLLIW,	assemble_DUMMY,		0,			0,			0,			0
	.word MASK_SRLIW,	MATCH_SRLIW,	decode_I_type_SHIFT,	string_OP_SRLIW,	assemble_DUMMY,		0,			0,			0,			0
	.word MASK_SRAIW,	MATCH_SRAIW,	decode_I_type_SHIFT,	string_OP_SRAIW,	assemble_DUMMY,		0,			0,			0,			0
	.word MASK_ADDW, 	MATCH_ADDW,		decode_R_type,			string_OP_ADDW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_SUBW,	MATCH_SUBW,		decode_R_type,			string_OP_SUBW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_SLLW,	MATCH_SLLW,		decode_R_type,			string_OP_SLLW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_SRLW,	MATCH_SRLW,		decode_R_type,			string_OP_SRLW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_SRAW,	MATCH_SRAW,		decode_R_type,			string_OP_SRAW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_LD,		MATCH_LD,		decode_I_type_LOAD,		string_OP_LD,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_LWU,		MATCH_LWU,		decode_I_type_LOAD,		string_OP_LWU,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_SD,		MATCH_SD,		decode_S_type,			string_OP_SD,		assemble_DUMMY,		0,			0,			0,			0
#endif

# RVM
#ifdef ENABLE_RVM
	# RV32M
	.word MASK_MUL,		MATCH_MUL,		decode_R_type,	string_OP_MUL,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_MULH,	MATCH_MULH,		decode_R_type,	string_OP_MULH,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_MULHSU,	MATCH_MULHSU,	decode_R_type,	string_OP_MULHSU,	assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_MULHU,	MATCH_MULHU,	decode_R_type,	string_OP_MULHU,	assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_DIV,		MATCH_DIV,		decode_R_type,	string_OP_DIV,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_DIVU,	MATCH_DIVU,		decode_R_type,	string_OP_DIVU,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_REM,		MATCH_REM,		decode_R_type,	string_OP_REM,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	.word MASK_REMU,	MATCH_REMU,		decode_R_type,	string_OP_REMU,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	# RV64M
	#if XLEN >= 64
		.word MASK_MULW,	MATCH_MULW,		decode_R_type,	string_OP_MULW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
		.word MASK_DIVW,	MATCH_DIVW,		decode_R_type,	string_OP_DIVW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
		.word MASK_DIVUW,	MATCH_DIVUW,	decode_R_type,	string_OP_DIVUW,	assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
		.word MASK_REMW,	MATCH_REMW,		decode_R_type,	string_OP_REMW,		assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
		.word MASK_REMUW,	MATCH_REMUW,	decode_R_type,	string_OP_REMUW,	assemble_GENERIC,	ass_rd,		ass_rs1,	ass_rs2,	0
	#endif
#endif /* ENABLE_RVM */

# RVA
#ifdef ENABLE_RVA
	# RV32A
	.word MASK_LR_W,		MATCH_LR_W,			decode_LRSC,	string_OP_LRW, 		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_SC_W,		MATCH_SC_W,			decode_LRSC,	string_OP_SCW,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOSWAP_W,	MATCH_AMOSWAP_W,	decode_AMO,		string_OP_AMOSWAPW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOADD_W,	MATCH_AMOADD_W,		decode_AMO,		string_OP_AMOADDW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOAND_W,	MATCH_AMOAND_W,		decode_AMO,		string_OP_AMOANDW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOOR_W,		MATCH_AMOOR_W,		decode_AMO,		string_OP_AMOORW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOXOR_W,	MATCH_AMOXOR_W,		decode_AMO,		string_OP_AMOXORW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOMAX_W,	MATCH_AMOMAX_W,		decode_AMO,		string_OP_AMOMAXW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOMIN_W,	MATCH_AMOMIN_W,		decode_AMO,		string_OP_AMOMINW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOMAXU_W,	MATCH_AMOMAXU_W,	decode_AMO,		string_OP_AMOMAXUW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_AMOMINU_W,	MATCH_AMOMINU_W,	decode_AMO,		string_OP_AMOMINUW,	assemble_DUMMY,	0,			0,			0,			0
		# RV64A
		#if XLEN >= 64
		.word MASK_LR_D, 		MATCH_LR_D,			decode_LRSC,	string_OP_LRD,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_SC_D, 		MATCH_SC_D, 		decode_LRSC,	string_OP_SCD,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOSWAP_D,	MATCH_AMOSWAP_D,	decode_AMO,		string_OP_AMOSWAPD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOADD_D,	MATCH_AMOADD_D,		decode_AMO,		string_OP_AMOADDD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOAND_D,	MATCH_AMOAND_D,		decode_AMO,		string_OP_AMOANDD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOOR_D,		MATCH_AMOOR_D,		decode_AMO,		string_OP_AMOORD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOXOR_D,	MATCH_AMOXOR_D,		decode_AMO,		string_OP_AMOXORD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOMAX_D,	MATCH_AMOMAX_D,		decode_AMO,		string_OP_AMOMAXD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOMIN_D,	MATCH_AMOMIN_D,		decode_AMO,		string_OP_AMOMIND,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOMAXU_D,	MATCH_AMOMAXU_D,	decode_AMO,		string_OP_AMOMAXUD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_AMOMINU_D,	MATCH_AMOMINU_D,	decode_AMO,		string_OP_AMOMINUD,	assemble_DUMMY,	0,			0,			0,			0
		#endif
#endif /* ENABLE_RVA */

# RVF / RVD / RVQ
#ifdef ENABLE_RVF
	.word MASK_FLW,			MATCH_FLW,			decode_FL,			string_OP_FLW,			assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FSW,			MATCH_FSW,			decode_FS,			string_OP_FSW,			assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FMADD_S,		MATCH_FMADD_S,		decode_FMA,			string_OP_FMADD_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FMSUB_S,		MATCH_FMSUB_S,		decode_FMA,			string_OP_FMSUB_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FNMADD_S,	MATCH_FNMADD_S,		decode_FMA,			string_OP_FNMADD_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FNMSUB_S,	MATCH_FNMSUB_S,		decode_FMA,			string_OP_FNMSUB_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FSUB_S,		MATCH_FSUB_S,		decode_FADD,		string_OP_FSUB_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FADD_S,		MATCH_FADD_S,		decode_FADD,		string_OP_FADD_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FMUL_S,		MATCH_FMUL_S,		decode_FADD,		string_OP_FMUL_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FDIV_S,		MATCH_FDIV_S,		decode_FADD,		string_OP_FDIV_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FSQRT_S,		MATCH_FSQRT_S,		decode_FSQRT,		string_OP_FSQRT_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FSGNJ_S,		MATCH_FSGNJ_S,		decode_FADD,		string_OP_FSGNJ_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FSGNJN_S,	MATCH_FSGNJN_S,		decode_FADD,		string_OP_FSGNJN_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FSGNJX_S,	MATCH_FSGNJX_S,		decode_FADD,		string_OP_FSGNJX_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FMIN_S,		MATCH_FMIN_S,		decode_FADD,		string_OP_FMIN_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FMAX_S,		MATCH_FMAX_S,		decode_FADD,		string_OP_FMAX_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FCVT_S_W,	MATCH_FCVT_S_W,		decode_FCVT_SW,		string_OP_FCVT_S_W,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FCVT_S_WU,	MATCH_FCVT_S_WU,	decode_FCVT_SW,		string_OP_FCVT_S_WU,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FCVT_W_S,	MATCH_FCVT_W_S,		decode_FCVT_WS,		string_OP_FCVT_W_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FCVT_WU_S,	MATCH_FCVT_WU_S,	decode_FCVT_WS,		string_OP_FCVT_WU_S,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FMV_X_S,		MATCH_FMV_X_S,		decode_FCVT_WS,		string_OP_FMV_X_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FMV_S_X,		MATCH_FMV_S_X,		decode_FCVT_SW,		string_OP_FMV_S_X,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FLT_S,		MATCH_FLT_S,		decode_FCMP,		string_OP_FLT_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FEQ_S,		MATCH_FEQ_S,		decode_FCMP,		string_OP_FEQ_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FLE_S,		MATCH_FLE_S,		decode_FCMP,		string_OP_FLE_S,		assemble_DUMMY,	0,			0,			0,			0
	.word MASK_FCLASS_S,	MATCH_FCLASS_S,		decode_FCLASS,		string_OP_FCLASS_S,		assemble_DUMMY,	0,			0,			0,			0
	#ifdef ENABLE_RVD
		.word MASK_FLD,			MATCH_FLD,			decode_FL,		string_OP_FLD,			assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FSD,			MATCH_FSD,			decode_FS,		string_OP_FSD,			assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FMADD_D,		MATCH_FMADD_D,		decode_FMA,		string_OP_FMADD_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FMSUB_D,		MATCH_FMSUB_D,		decode_FMA,		string_OP_FMSUB_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FNMADD_D,	MATCH_FNMADD_D,		decode_FMA,		string_OP_FNMADD_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FNMSUB_D,	MATCH_FNMSUB_D,		decode_FMA,		string_OP_FNMSUB_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FADD_D,		MATCH_FADD_D,		decode_FADD,	string_OP_FADD_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FSUB_D,		MATCH_FSUB_D,		decode_FADD,	string_OP_FSUB_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FMUL_D,		MATCH_FMUL_D,		decode_FADD,	string_OP_FMUL_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FDIV_D,		MATCH_FDIV_D,		decode_FADD,	string_OP_FDIV_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FSQRT_D,		MATCH_FSQRT_D,		decode_FSQRT,	string_OP_FSQRT_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FSGNJ_D,		MATCH_FSGNJ_D,		decode_FADD,	string_OP_FSGNJ_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FSGNJN_D,	MATCH_FSGNJN_D,		decode_FADD,	string_OP_FSGNJN_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FSGNJX_D,	MATCH_FSGNJX_D,		decode_FADD,	string_OP_FSGNJX_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FMIN_D,		MATCH_FMIN_D,		decode_FADD,	string_OP_FMIN_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FMAX_D,		MATCH_FMAX_D,		decode_FADD,	string_OP_FMAX_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FCVT_D_W,	MATCH_FCVT_D_W,		decode_FCVT_SW,	string_OP_FCVT_D_W,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FCVT_D_WU,	MATCH_FCVT_D_WU,	decode_FCVT_SW,	string_OP_FCVT_D_WU,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FCVT_W_D,	MATCH_FCVT_W_D,		decode_FCVT_WS,	string_OP_FCVT_W_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FCVT_WU_D,	MATCH_FCVT_WU_D,	decode_FCVT_WS,	string_OP_FCVT_WU_D,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FMV_X_D,		MATCH_FMV_X_D,		decode_FCVT_WS,	string_OP_FMV_X_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FMV_D_X,		MATCH_FMV_D_X,		decode_FCVT_SW,	string_OP_FMV_D_X,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FEQ_D,		MATCH_FEQ_D,		decode_FCMP,	string_OP_FEQ_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FLT_D,		MATCH_FLT_D,		decode_FCMP,	string_OP_FLT_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FLE_D,		MATCH_FLE_D,		decode_FCMP,	string_OP_FLE_D,		assemble_DUMMY,	0,			0,			0,			0
		.word MASK_FCLASS_D,	MATCH_FCLASS_D,		decode_FCLASS,	string_OP_FCLASS_D,		assemble_DUMMY,	0,			0,			0,			0
		#ifdef ENABLE_RVQ
			.word MASK_FLQ,			MATCH_FLQ,			decode_FL,		string_OP_FLQ,			assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FSQ,			MATCH_FSQ,			decode_FS,		string_OP_FSQ,			assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FMADD_Q,		MATCH_FMADD_Q,		decode_FMA,		string_OP_FMADD_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FMSUB_Q,		MATCH_FMSUB_Q,		decode_FMA,		string_OP_FMSUB_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FNMADD_Q,	MATCH_FNMADD_Q,		decode_FMA,		string_OP_FNMADD_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FNMSUB_Q,	MATCH_FNMSUB_Q,		decode_FMA,		string_OP_FNMSUB_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FADD_Q,		MATCH_FADD_Q,		decode_FADD,	string_OP_FADD_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FSUB_Q,		MATCH_FSUB_Q,		decode_FADD,	string_OP_FSUB_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FMUL_Q,		MATCH_FMUL_Q,		decode_FADD,	string_OP_FMUL_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FDIV_Q,		MATCH_FDIV_Q,		decode_FADD,	string_OP_FDIV_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FSQRT_Q,		MATCH_FSQRT_Q,		decode_FSQRT,	string_OP_FSQRT_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FSGNJ_Q,		MATCH_FSGNJ_Q,		decode_FADD,	string_OP_FSGNJ_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FSGNJN_Q,	MATCH_FSGNJN_Q,		decode_FADD,	string_OP_FSGNJN_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FSGNJX_Q,	MATCH_FSGNJX_Q,		decode_FADD,	string_OP_FSGNJX_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FMIN_Q,		MATCH_FMIN_Q,		decode_FADD,	string_OP_FMIN_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FMAX_Q,		MATCH_FMAX_Q,		decode_FADD,	string_OP_FMAX_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FCVT_Q_W,	MATCH_FCVT_Q_W,		decode_FCVT_SW,	string_OP_FCVT_Q_W,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FCVT_Q_WU,	MATCH_FCVT_Q_WU,	decode_FCVT_SW,	string_OP_FCVT_Q_WU,	assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FCVT_W_Q,	MATCH_FCVT_W_Q,		decode_FCVT_WS,	string_OP_FCVT_W_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FCVT_WU_Q,	MATCH_FCVT_WU_Q,	decode_FCVT_WS,	string_OP_FCVT_WU_Q,	assemble_DUMMY,	0,			0,			0,			0
			#if XLEN >=128
				.word MASK_FMV_X_Q, MATCH_FMV_X_Q,		decode_FCVT_WS,	string_OP_FMV_X_Q,		assemble_DUMMY,	0,			0,			0,			0
				.word MASK_FMV_Q_X, MATCH_FMV_Q_X,		decode_FCVT_SW,	string_OP_FMV_Q_X,		assemble_DUMMY,	0,			0,			0,			0
			#endif
			.word MASK_FEQ_Q,		MATCH_FEQ_Q,		decode_FCMP,	string_OP_FEQ_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FLT_Q,		MATCH_FLT_Q,		decode_FCMP,	string_OP_FLT_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FLE_Q,		MATCH_FLE_Q,		decode_FCMP,	string_OP_FLE_Q,		assemble_DUMMY,	0,			0,			0,			0
			.word MASK_FCLASS_Q,	MATCH_FCLASS_Q,		decode_FCLASS,	string_OP_FCLASS_Q,		assemble_DUMMY,	0,			0,			0,			0
		#endif /* ENABLE_RVQ */
	#endif /* ENABLE_RVD */
#endif /* ENABLE_RVF */

# RVC
#ifdef ENABLE_RVC
	.word MASK_C_LW,		MATCH_C_LW,			decode_EMPTY,				string_OP_C_LW,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SW,		MATCH_C_SW,			decode_EMPTY,				string_OP_C_SW,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_ADDI,		MATCH_C_ADDI,		decode_EMPTY,				string_OP_C_ADDI,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_JAL,		MATCH_C_JAL,		decode_EMPTY,				string_OP_C_JAL,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_LI,		MATCH_C_LI,			decode_EMPTY,				string_OP_C_LI,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_LUI,		MATCH_C_LUI,		decode_EMPTY,				string_OP_C_LUI,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SRLI,		MATCH_C_SRLI,		decode_EMPTY,				string_OP_C_SRLI,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SRLI64,	MATCH_C_SRLI64,		decode_EMPTY,				string_OP_C_SRLI64,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SRAI,		MATCH_C_SRAI,		decode_EMPTY,				string_OP_C_SRAI,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SRAI64,	MATCH_C_SRAI64,		decode_EMPTY,				string_OP_C_SRAI64,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_ANDI,		MATCH_C_ANDI,		decode_EMPTY,				string_OP_C_ANDI,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SUB,		MATCH_C_SUB,		decode_EMPTY,				string_OP_C_SUB,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_XOR,		MATCH_C_XOR,		decode_EMPTY,				string_OP_C_XOR,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_OR,		MATCH_C_OR,			decode_EMPTY,				string_OP_C_OR,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_AND,		MATCH_C_AND,		decode_EMPTY,				string_OP_C_AND,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SUBW,		MATCH_C_SUBW,		decode_EMPTY,				string_OP_C_SUBW,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_ADDW,		MATCH_C_ADDW,		decode_EMPTY,				string_OP_C_ADDW,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_J,			MATCH_C_J,			decode_EMPTY,				string_OP_C_J,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_BEQZ,		MATCH_C_BEQZ,		decode_EMPTY,				string_OP_C_BEQZ,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_BNEZ,		MATCH_C_BNEZ,		decode_EMPTY,				string_OP_C_BNEZ,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SLLI,		MATCH_C_SLLI,		decode_EMPTY,				string_OP_C_SLLI,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SLLI64,	MATCH_C_SLLI64,		decode_EMPTY,				string_OP_C_SLLI64,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_LWSP,		MATCH_C_LWSP,		decode_C_LWSP,				string_OP_C_LWSP,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_MV,		MATCH_C_MV,			decode_EMPTY,				string_OP_C_MV,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_ADD,		MATCH_C_ADD,		decode_C_ADD_JAL_EBREAK,	string_OP_C_ADD,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SWSP,		MATCH_C_SWSP,		decode_EMPTY,				string_OP_C_SWSP,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_NOP,		MATCH_C_NOP,		decode_EMPTY,				string_OP_C_NOP,		assemble_GENERIC,	0,			0,			0,			0
	.word MASK_C_ADDI16SP,	MATCH_C_ADDI16SP,	decode_EMPTY,				string_OP_C_ADDI16SP,	assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_JR,		MATCH_C_JR,			decode_EMPTY,				string_OP_C_JR,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_JALR,		MATCH_C_JALR,		decode_C_ADD_JAL_EBREAK,	string_OP_C_JALR,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_EBREAK,	MATCH_C_EBREAK,		decode_C_ADD_JAL_EBREAK,	string_OP_C_EBREAK,		assemble_GENERIC,	0,			0,			0,			0
	.word MASK_C_LD,		MATCH_C_LD,			decode_EMPTY,				string_OP_C_LD,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SD,		MATCH_C_SD,			decode_EMPTY,				string_OP_C_SD,			assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_ADDIW,		MATCH_C_ADDIW,		decode_EMPTY,				string_OP_C_ADDIW,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_LDSP,		MATCH_C_LDSP,		decode_EMPTY,				string_OP_C_LDSP,		assemble_DUMMY,		0,			0,			0,			0
	.word MASK_C_SDSP,		MATCH_C_SDSP,		decode_EMPTY,				string_OP_C_SDSP,		assemble_DUMMY,		0,			0,			0,			0
	#ifdef ENABLE_RVF
		.word MASK_C_FLD,	MATCH_C_FLD,	decode_EMPTY,	string_OP_C_FLD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_C_FSD,	MATCH_C_FSD,	decode_EMPTY,	string_OP_C_FSD,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_C_FLW,	MATCH_C_FLW,	decode_EMPTY,	string_OP_C_FLW,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_C_FSW,	MATCH_C_FSW,	decode_EMPTY,	string_OP_C_FSW,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_C_FLWSP, MATCH_C_FLWSP, 	decode_EMPTY,	string_OP_C_FLWSP,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_C_FSWSP,	MATCH_C_FSWSP,	decode_EMPTY,	string_OP_C_FSWSP,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_C_FLDSP,	MATCH_C_FLDSP,	decode_EMPTY,	string_OP_C_FLDSP,	assemble_DUMMY,	0,			0,			0,			0
		.word MASK_C_FSDSP,	MATCH_C_FSDSP,	decode_EMPTY,	string_OP_C_FSDSP,	assemble_DUMMY,	0,			0,			0,			0
	#endif /* ENABLE_RVF */
#endif /* ENABLE_RVC */

# Zifencei
#ifdef ENABLE_RVZifencei
	.word MASK_FENCE_I,		MATCH_FENCE_I,	decode_FENCE_I,	string_OP_FENCE_I,	assemble_GENERIC,	0,	0,	0,	0
#endif /* ENABLE_RVZifencei */

# Zicsr
#ifdef ENABLE_RVZicsr
	.word MASK_CSRRW,	MATCH_CSRRW,	decode_CSR,		string_OP_CSRRW,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_CSRRS,	MATCH_CSRRS,	decode_CSR,		string_OP_CSRRS,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_CSRRC,	MATCH_CSRRC,	decode_CSR,		string_OP_CSRRC,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_CSRRWI,	MATCH_CSRRWI,	decode_CSRI,	string_OP_CSRRWI,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_CSRRCI,	MATCH_CSRRCI,	decode_CSRI,	string_OP_CSRRCI,	assemble_DUMMY,	0,			0,			0,			0
	.word MASK_CSRRSI,	MATCH_CSRRSI,	decode_CSRI,	string_OP_CSRRSI,	assemble_DUMMY,	0,			0,			0,			0
#endif /* ENABLE_RVZicsr */

# Privileged
#ifdef ENABLE_RVPRIV
	.word MASK_WFI,			MATCH_WFI,			decode_WFI,			string_OP_WFI,			assemble_GENERIC,	0,	0,	0,	0
	.word MASK_MRET,		MATCH_MRET,			decode_MRET,		string_OP_MRET,			assemble_GENERIC,	0,	0,	0,	0
	.word MASK_SRET,		MATCH_SRET,			decode_SRET,		string_OP_SRET,			assemble_GENERIC,	0,	0,	0,	0
	.word MASK_SFENCE_VM,	MATCH_SFENCE_VM,	decode_SFENCE_VM,	string_OP_SFENCE_VM,	assemble_GENERIC,	0,	0,	0,	0
	.word MASK_SFENCE_VMA,	MATCH_SFENCE_VMA,	decode_SFENCE_VMA,	string_OP_SFENCE_VMA,	assemble_GENERIC,	0,	0,	0,	0
#endif /* ENABLE_RVPRIV */

# table end marker
.word 0, 0, 0, 0, 0, 0, 0, 0, 0
.size encoding_table, .-encoding_table


#endif /* #if defined (WITH_CMD_D) || defined (WITH_CMD_A) */
