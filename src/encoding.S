#include "config.h"
#include "riscv/riscv-opc.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#if defined (WITH_CMD_D) || defined (WITH_CMD_A)

# jump table for disass functions
.global disass_vectors

# instructions table access functions
.global get_data_by_insn_name
.global get_data_by_insn_word

# encoding helper functions
.global insn_is_compressed

.global string_OP_UNKNOWN

#endif


#if defined (WITH_CMD_D) || defined (WITH_CMD_A) || defined (WITH_CMD_G)
	.global is_valid_insn_addr
#endif /* defined (WITH_CMD_D) || defined (WITH_CMD_A) || defined (WITH_CMD_G) */


.text


#if defined (WITH_CMD_D) || defined (WITH_CMD_A) || defined (WITH_CMD_G)
	# in: a0 = addr
	# out: a0 = addr
	# out: a1 = 0 if OK, nonzero if not OK
	is_valid_insn_addr:
		li		a1, 0
		#ifdef DISASS_RVC
			andi	a1, a0, 0b1
		#else
			andi	a1, a0, 0b11
		#endif
	break_check_addr_done:
		ret
	.size is_valid_insn_addr, .-is_valid_insn_addr
#endif /* defined (WITH_CMD_D) || defined (WITH_CMD_A) || defined (WITH_CMD_G) */


#if defined (WITH_CMD_D) || defined (WITH_CMD_A)

	#ifdef DISASS_RVC
		# evaluate if an instruction is an RVC instruction
		# in: a0 = instruction word
		# out: a0 = 0 if not, nonzero if yes
		insn_is_compressed:
			andi	a0, a0, 0b11				 # look at bit 0 and 1
			# uncompressed instructions have 0b11 in the end
			# so if a0 < 3 now, it is compressed
			sltiu	a0, a0, 0b11
			ret
		.size insn_is_compressed, .-insn_is_compressed
	#endif

# in: s0 = ptr to search string start
# in: s1 = ptr to last char of search string
# out: a0 = ptr to assemble function (0 if string was not found)
# out: a1 = MATCH value for insn (undefined if string was not found)
# out: a3 = ptr to table entry (undefined if string was not found)
get_data_by_insn_name:
	la		t0, encoding_table
	li		t6, '.'
get_data_by_insn_name_next:								# check string in next table entry
	li		t5, -2										# count dots for RVA insns
	# load values from current table entry
	LWU		a1, ENC_OFF_MATCH(t0)						# store MATCH value from table entry in a1
	LWU		t1, ENC_OFF_OP_STRING(t0)					# get string ptr from table
	beqz	t1, get_data_by_insn_name_not_found			# if string in this entry is empty, then table end, no match found
	# compare strings
	mv		t2, s0										# iterate with t2 over search string
get_data_by_insn_name_cmp_next_byte:
	lbu		t3, 0(t2)									# load char from search string
	lbu		t4, 0(t1)									# load char from table string
	# RVA insns may have two dots, as they may have an .aqrl extension.
	# Count dots in search string, and if we arrive at the second one, its just a match.
	bne		t3, t6, get_data_by_insn_name_no_dot
	addi	t5, t5, 1
	beqz	t5, get_data_by_insn_name_done				# we started with -2, so if it's 0 now, we found 2
get_data_by_insn_name_no_dot:
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


# in: instruction word in a0
# out: a3 = ptr to table entry
get_data_by_insn_word:
	PUSH_RA
	# search for a match in encoding table
	la		t0, encoding_table
	# clear return values
	mv		a3, zero
get_data_by_insn_word_search_next:
	LWU		t2, ENC_OFF_MASK(t0)				# get mask word from table
	beqz	t2, get_data_by_insn_word_done		# table end, no match found	  
	and		t2, a0, t2							# apply mask
	LWU		t1, ENC_OFF_MATCH(t0)				# get match word from table
	bne		t2, t1, get_data_by_insn_word_continue
	# found a match
	mv		a3, t0
	# last table entry is all zeros, so a3 = 0 if insn was not found
	j		get_data_by_insn_word_done
get_data_by_insn_word_continue:
	addi	t0, t0, ENC_ENTRY_SIZE				# point to next table entry
	j		get_data_by_insn_word_search_next	# repeat
get_data_by_insn_word_done:
	POP_RA_RET
.size get_data_by_insn_word, .-get_data_by_insn_word


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
#ifdef DISASS_RVM
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
#endif /* DISASS_RVM */

# RVA
#ifdef DISASS_RVA
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
#endif /* DISASS_RVA */

# RVF / RVD / RVQ
#ifdef DISASS_RVF
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
	#ifdef DISASS_RVD
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
		#ifdef DISASS_RVQ
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
		#endif /* DISASS_RVQ */
	#endif /* DISASS_RVD */
#endif /* DISASS_RVF */

# Zifencei
#ifdef DISASS_RVZifencei
	string_OP_FENCE_I:	.string "fence.i";
#endif /* DISASS_RVZifencei */

# Zicsr
	#ifdef DISASS_RVZicsr
	string_OP_CSRRW:	.string "csrrw";
	string_OP_CSRRS:	.string "csrrs";
	string_OP_CSRRC:	.string "csrrc";
	string_OP_CSRRWI:	.string "csrrwi";
	string_OP_CSRRSI:	.string "csrrsi";
	string_OP_CSRRCI:	.string "csrrci";
#endif /* DISASS_RVZicsr */

# RVC
#ifdef DISASS_RVC
	string_OP_C_LW:			.string "c.lw";
	string_OP_C_SW:			.string "c.sw";
	string_OP_C_ADDI:		.string "c.addi";
	string_OP_C_JAL:		.string "c.jal";
	string_OP_C_LI:			.string "c.li";
	string_OP_C_LUI:		.string "c.lui";
	string_OP_C_SRLI:		.string "c.srli";
	string_OP_C_SRAI:		.string "c.srai";
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
	string_OP_C_LWSP:		.string "c.lwsp";
	string_OP_C_MV:			.string "c.mv";
	string_OP_C_ADD:		.string "c.add";
	string_OP_C_SWSP:		.string "c.swsp";
	string_OP_C_NOP:		.string "c.nop";
	string_OP_C_ADDI16SP:	.string "c.addi16sp";
	string_OP_C_ADDI4SPN:	.string "c.addi4spn";
	string_OP_C_JR:			.string "c.jr";
	string_OP_C_JALR:		.string "c.jalr";
	string_OP_C_EBREAK:		.string "c.ebreak";
	string_OP_C_ADDIW:		.string "c.addiw";
	
	#if XLEN >= 64
		string_OP_C_LD:			.string "c.ld";
		string_OP_C_SD:			.string "c.sd";	
		string_OP_C_LDSP:		.string "c.ldsp";
		string_OP_C_SDSP:		.string "c.sdsp";
	#endif

	#if XLEN >= 128
		string_OP_C_LD:			.string "c.lq";
		string_OP_C_SD:			.string "c.sq";
		string_OP_C_LDSP:		.string "c.lqsp";
		string_OP_C_SDSP:		.string "c.sqsp";
		string_OP_C_SRLI64:		.string "c.srli64";
		string_OP_C_SRAI64:		.string "c.srai64";
		string_OP_C_SLLI64:		.string "c.slli64";	
	#endif
	
	#ifdef DISASS_RVF
		string_OP_C_FLW:		.string "c.flw";
		string_OP_C_FSW:		.string "c.fsw";
		string_OP_C_FLWSP:		.string "c.flwsp";
		string_OP_C_FSWSP:		.string "c.fswsp";

		#if XLEN >= 64
			string_OP_C_FLD:		.string "c.fld";
			string_OP_C_FSD:		.string "c.fsd";
			string_OP_C_FLDSP:		.string "c.fldsp";
			string_OP_C_FSDSP:		.string "c.fsdsp";
		#endif

	#endif /* DISASS_RVF */

#endif /* DISASS_RVC */

# Pseudo
#ifdef DISASS_PSEUDO
	string_OP_MV:		.string "mv";

	string_OP_NOT:		.string "not";
	string_OP_NEG:		.string "neg";

	string_OP_SEQZ:		.string "seqz";
	string_OP_SNEZ:		.string "snez";
	string_OP_SLTZ:		.string "sltz";
	string_OP_SGTZ:		.string "sgtz";

	string_OP_BEQZ:		.string "beqz";
	string_OP_BNEZ:		.string "bnez";
	string_OP_BGEZ:		.string "bgez";
	string_OP_BLTZ:		.string "bltz";
	string_OP_BLEZ:		.string "blez";
	string_OP_BGTZ:		.string "bgtz";
	string_OP_BGT:		.string "bgt";
	string_OP_BLE:		.string "ble";
	string_OP_BGTU:		.string "bgtu";
	string_OP_BLEU:		.string "bleu";

	string_OP_J:		.string "j";
	string_OP_JR:		.string "jr";

	string_OP_RET:		.string "ret";	
	string_OP_NOP:		.string "nop";	
	string_OP_UNIMP:	.string "unimp";	

	#if XLEN >= 64
		string_OP_NEGW:		.string "negw";
		string_OP_SEXTW:	.string "sext.w";
	#endif

	#ifdef DISASS_RVC
		string_OP_C_UNIMP:	.string "c.unimp";	
	#endif

#endif /* DISASS_PSEUDO */

# Privileged
#ifdef DISASS_RVPRIV
	string_OP_WFI:			.string "wfi";	
	string_OP_MRET:			.string "mret";	
	string_OP_SRET:			.string "sret";	
	string_OP_SFENCE_VM:	.string "sfence.vm";	
	string_OP_SFENCE_VMA:	.string "sfence.vma";	
#endif /* DISASS_PSEUDO */

.size string_opcodes, .-string_opcodes


# ---------- set up an encoding table  ----------


.align 4

disass_vectors:
.word	0, 0								# 0x00
.word	ass_rd, dis_rd						# 0x01
.word	ass_rs1, dis_rs1					# 0x02
.word	ass_rs2, dis_rs2					# 0x03
.word	ass_I_imm, dis_I_imm				# 0x04
.word	ass_S_imm, dis_S_imm				# 0x05
.word	ass_BRA, dis_BRA					# 0x06
.word	ass_J, dis_J						# 0x07
.word	ass_U_imm, dis_U_imm				# 0x08
.word	ass_I_rel, dis_I_rel				# 0x09
.word	ass_PRE, dis_PRE					# 0x0a
.word	ass_SUC, dis_SUC					# 0x0b
.word	0, 0								# 0x0c

#ifdef DISASS_RVF
	.word	ass_frd, dis_frd				# 0x0d
	.word	ass_frs1, dis_frs1				# 0x0e
	.word	ass_frs2, dis_frs2				# 0x0f
	.word	ass_frs3, dis_frs3				# 0x10
#else
	.word	0, 0							# 0x0d	
	.word	0, 0							# 0x0e
	.word	0, 0							# 0x0f
	.word	0, 0							# 0x10
#endif /* DISASS_RVF */

#ifdef DISASS_RVZicsr
	.word	ass_csr, dis_csr				# 0x11
	.word	ass_csri, dis_csri				# 0x12
#else
	.word	0, 0							# 0x11
	.word	0, 0							# 0x12
#endif /* DISASS_RVZicsr */

#ifdef DISASS_RVC
	.word	ass_C_rd, dis_C_rd					# 0x13	( C_rd == C_rs1 )
	.word	ass_C_rs2, dis_C_rs2				# 0x14
	.word	ass_CL_rel, dis_CL_rel				# 0x15	(== ass_CS_rel, dis_CS_rel)
	.word	ass_C_rs1a, dis_C_rs1a				# 0x16
	.word	ass_C_rs2a, dis_C_rs2a				# 0x17	(C_rda == C_rs2a in CL-type and CIW-type)
	.word	ass_CI_imm, dis_CI_imm				# 0x18
	.word	ass_CSS_4imm, dis_CSS_4imm			# 0x19
	.word	ass_CIW_imm, dis_CIW_imm			# 0x1a
	.word	ass_CL_LW_4imm, dis_CL_LW_4imm		# 0x1b	(c.lw, c.sw)
	.word	ass_C_rd_nz, dis_C_rd				# 0x1c
	.word	ass_C_rs2_nz, dis_C_rs2				# 0x1d
	.word	ass_CJ_off, dis_CJ_off				# 0x1e	(c.j, c.jal)
	.word	ass_CI_4imm, dis_CI_4imm			# 0x1f
	.word	ass_CSS_8imm, dis_CSS_8imm			# 0x20
	.word	ass_CI_8imm, dis_CI_8imm			# 0x21
	.word	ass_CI_16imm, dis_CI_16imm			# 0x22
	.word	ass_C_BRA, dis_C_BRA				# 0x23	(c.beqz, c.bnez)
	.word	ass_rdsp, dis_C_rd					# 0x24	(rd==sp in c.addi16sp)
	.word	ass_C_16sp_imm, dis_C_16sp_imm		# 0x25
	.word	ass_rdasp, dis_C_rdasp				# 0x26	(rda==sp in c.addi4spn)
	.word	ass_CSS_16imm, dis_CSS_16imm		# 0x27
	.word	ass_CL_LW_8imm, dis_CL_LW_8imm		# 0x28	(c.ld, c.sd)
	.word	ass_CL_LW_16imm, dis_CL_LW_16imm	# 0x29	(c.lq, c.sq)
	.word	ass_C_relsp, dis_C_relsp			# 0x2a	(c.lwsp, c.swsp)
#else
	.word	0, 0								# 0x13	
	.word	0, 0								# 0x14
	.word	0, 0								# 0x15
	.word	0, 0								# 0x16
	.word	0, 0								# 0x17
	.word	0, 0								# 0x18
	.word	0, 0								# 0x19
	.word	0, 0								# 0x1a
	.word	0, 0								# 0x1b
	.word	0, 0								# 0x1c
	.word	0, 0								# 0x1d
	.word	0, 0								# 0x1e
	.word	0, 0								# 0x1f
	.word	0, 0								# 0x20
	.word	0, 0								# 0x21
	.word	0, 0								# 0x22
	.word	0, 0								# 0x23
	.word	0, 0								# 0x24
	.word	0, 0								# 0x25
	.word	0, 0								# 0x26
	.word	0, 0								# 0x27
	.word	0, 0								# 0x28
	.word	0, 0								# 0x29
	.word	0, 0								# 0x2a
#endif /* DISASS_RVC */


encoding_table:
# This encoding table is used to lookup instructions during assembly 
# and disassembly:
# - MASK/MATCH are defined by the RISC-V standard
# - control word specifies what arguments to expect during assembly
#   and what to print during disassembly
#
# The control word contains indexes into the disass_vectors,
# for arg1 - arg4 BACKWARDS from *right* to *left*, so
# "0x00030201" means look for rd, rs1, rs2 and then stop.
#
# format: MASK, MATCH, opcode string, control word


# PSEUDO opcodes
# order is important, these have to be at the beginning of the table
#ifdef DISASS_PSEUDO

	#ifdef DISASS_RVC
		.word 0x0000ffff, 0x0000,	string_OP_C_UNIMP,	0x00000000
		.word 0x0000ffff, 0x0001,	string_OP_C_NOP,	0x00000000
	#endif /* DISASS_RVC */

	.word 0xffffffff, 0x00000000,	string_OP_UNIMP,	0x00000000
	.word 0xffffffff, 0x00008067,	string_OP_RET,		0x00000000
	.word 0xffffffff, 0x00000013,	string_OP_NOP,		0x00000000
	
	# for mv, look additionally at imm[11:0] == insn[31:20] which must be zero
	.word MASK_ADDI | 0xfff00000, MATCH_ADDI, string_OP_MV, 0x00000201
	
	# for not, look additionally at imm[11:0] == insn[31:20] which must be -1
	.word MASK_XORI | 0xfff00000, MATCH_XORI | 0xfff00000, string_OP_NOT, 0x00000201
	
	# for neg, look additionally at rs1 which must be x0 (0)
	.word MASK_SUB | 0b11111000000000000000, MATCH_SUB, string_OP_NEG, 0x00000301
	# for seqz, look additionally at imm[11:0] == insn[31:20] which must be 1
	
	.word MASK_SLTIU | 0xfff00000, MATCH_SLTIU | 0x00100000, string_OP_SEQZ, 0x00000201
	# for snez, look additionally at rs1 which must be x0 (0)
	.word MASK_SLTU | 0b11111000000000000000, MATCH_SLTU, string_OP_SNEZ, 0x00000301
	# for sltz, look additionally at rs2 which must be x0 (0)
	.word MASK_SLT | 0b1111100000000000000000000, MATCH_SLT, string_OP_SLTZ, 0x00000201
	# for sgtz, look additionally at rs1 which must be x0 (0)
	.word MASK_SLT | 0b11111000000000000000, MATCH_SLT, string_OP_SGTZ, 0x00000301
	
	# for beqz, look additionally at rs2 which must be x0 (0)
	.word MASK_BEQ | 0b1111100000000000000000000, MATCH_BEQ, string_OP_BEQZ, 0x00000602
	# for bnez, look additionally at rs2 which must be x0 (0)
	.word MASK_BNE | 0b1111100000000000000000000, MATCH_BNE, string_OP_BNEZ, 0x00000602
	# for bgez, look additionally at rs2 which must be x0 (0)
	.word MASK_BGE | 0b1111100000000000000000000, MATCH_BGE, string_OP_BGEZ, 0x00000602
	# for bltz, look additionally at rs2 which must be x0 (0)
	.word MASK_BLT | 0b1111100000000000000000000, MATCH_BLT, string_OP_BLTZ, 0x00000602
	# for blez, look additionally at rs1 which must be x0 (0)
	.word MASK_BGE | 0b11111000000000000000, MATCH_BGE, string_OP_BLEZ, 0x00000603
	# for bgtz, look additionally at rs1 which must be x0 (0)
	.word MASK_BLT | 0b11111000000000000000, MATCH_BLT, string_OP_BGTZ, 0x00000603

	# for j, look additionally at rd which must be x0 (0)
	.word MASK_JAL | 0b111110000000, MATCH_JAL, string_OP_J, 0x00000007
	
	# for jal <offset> (without rd), look additionally at rd which must be x1 (1)
	# todo: if this is enabled, "jal rd, offset" does not work any more (same mnemonic with different syntax)
	#.word MASK_JAL | 0b111110000000, MATCH_JAL | 0b10000000, string_OP_JAL, 0x00000007

	# for jr, rd==0 and offset==0
	.word MASK_JALR | 0xfff00000 | 0b111110000000 , MATCH_JALR, string_OP_JR, 0x00000002

	#if XLEN >= 64
		# for negw, look additionally at rs1 which must be x0 (0)
		.word MASK_SUBW | 0b11111000000000000000, MATCH_SUBW, string_OP_NEGW, 0x00000301
		# for sext.w, look additionally at imm[11:0] == insn[31:20] which must be zero
		.word MASK_ADDIW | 0xfff00000, MATCH_ADDIW, string_OP_SEXTW, 0x00000201
	#endif

#endif /* DISASS_PSEUDO */

# RV32I
# offset in bytes from start of each entry:
#     0					4				8					12
.word MASK_ADD,			MATCH_ADD,		string_OP_ADD,		0x00030201
.word MASK_SUB,			MATCH_SUB,		string_OP_SUB,		0x00030201
.word MASK_XOR,			MATCH_XOR,		string_OP_XOR,		0x00030201
.word MASK_OR,			MATCH_OR,		string_OP_OR,		0x00030201
.word MASK_AND,			MATCH_AND,		string_OP_AND,		0x00030201
.word MASK_SLL,			MATCH_SLL,		string_OP_SLL,		0x00030201
.word MASK_SRL,			MATCH_SRL,		string_OP_SRL,		0x00030201
.word MASK_SRA,			MATCH_SRA,		string_OP_SRA,		0x00030201
.word MASK_SLT,			MATCH_SLT,		string_OP_SLT,		0x00030201
.word MASK_SLTU,		MATCH_SLTU,		string_OP_SLTU,		0x00030201
.word MASK_ADDI,		MATCH_ADDI,		string_OP_ADDI,		0x00040201
.word MASK_XORI,		MATCH_XORI,		string_OP_XORI,		0x00040201
.word MASK_ORI,			MATCH_ORI,		string_OP_ORI,		0x00040201
.word MASK_ANDI,		MATCH_ANDI,		string_OP_ANDI,		0x00040201
.word MASK_SLLI,		MATCH_SLLI,		string_OP_SLLI,		0x00040201
.word MASK_SRLI,		MATCH_SRLI,		string_OP_SRLI,		0x00040201
.word MASK_SRAI,		MATCH_SRAI,		string_OP_SRAI,		0x00040201
.word MASK_SLTI,		MATCH_SLTI,		string_OP_SLTI,		0x00040201
.word MASK_SLTIU,		MATCH_SLTIU,	string_OP_SLTIU,	0x00040201
.word MASK_LB,			MATCH_LB,		string_OP_LB,		0x00090401
.word MASK_LH,			MATCH_LH,		string_OP_LH,		0x00090401
.word MASK_LW,			MATCH_LW,		string_OP_LW,		0x00090401
.word MASK_LBU,			MATCH_LBU, 		string_OP_LBU,		0x00090401
.word MASK_LHU,			MATCH_LHU,		string_OP_LHU, 		0x00090401
.word MASK_SB,			MATCH_SB,		string_OP_SB,		0x00090503
.word MASK_SH,			MATCH_SH,		string_OP_SH,		0x00090503
.word MASK_SW,			MATCH_SW,		string_OP_SW,		0x00090503
.word MASK_BEQ,			MATCH_BEQ,		string_OP_BEQ,		0x00060302
.word MASK_BNE,			MATCH_BNE,		string_OP_BNE,		0x00060302
.word MASK_BLT,			MATCH_BLT,		string_OP_BLT,		0x00060302
.word MASK_BGE,			MATCH_BGE,		string_OP_BGE,		0x00060302
.word MASK_BLTU,		MATCH_BLTU,		string_OP_BLTU,		0x00060302
.word MASK_BGEU,		MATCH_BGEU,		string_OP_BGEU,		0x00060302
.word MASK_JAL,			MATCH_JAL,		string_OP_JAL,		0x00000701
.word MASK_JALR,		MATCH_JALR,		string_OP_JALR,		0x00090401
.word MASK_LUI,			MATCH_LUI,		string_OP_LUI,		0x00000801
.word MASK_AUIPC,		MATCH_AUIPC,	string_OP_AUIPC,	0x00000801
.word MASK_ECALL,		MATCH_ECALL,	string_OP_ECALL,	0x00000000
.word MASK_EBREAK,		MATCH_EBREAK,	string_OP_EBREAK,	0x00000000
.word MASK_FENCETSO,	MATCH_FENCETSO,	string_OP_FENCETSO,	0x00000000
.word MASK_FENCE,		MATCH_FENCE,	string_OP_FENCE,	0x00000b0a

# RV64I
#if XLEN >= 64
	.word MASK_ADDIW,	MATCH_ADDIW,	string_OP_ADDIW,	0x00040201
	.word MASK_SLLIW,	MATCH_SLLIW,	string_OP_SLLIW,	0x00040201
	.word MASK_SRLIW,	MATCH_SRLIW,	string_OP_SRLIW,	0x00040201
	.word MASK_SRAIW,	MATCH_SRAIW,	string_OP_SRAIW,	0x00040201
	.word MASK_ADDW, 	MATCH_ADDW,		string_OP_ADDW,		0x00030201
	.word MASK_SUBW,	MATCH_SUBW,		string_OP_SUBW,		0x00030201
	.word MASK_SLLW,	MATCH_SLLW,		string_OP_SLLW,		0x00030201
	.word MASK_SRLW,	MATCH_SRLW,		string_OP_SRLW,		0x00030201
	.word MASK_SRAW,	MATCH_SRAW,		string_OP_SRAW,		0x00030201
	.word MASK_LD,		MATCH_LD,		string_OP_LD,		0x00090401

	.word MASK_LWU,		MATCH_LWU,		string_OP_LWU,		0x00090401
	.word MASK_SD,		MATCH_SD,		string_OP_SD,		0x00090503
#endif

# RVM
#ifdef DISASS_RVM
	# RV32M
	.word MASK_MUL,		MATCH_MUL,		string_OP_MUL,		0x00030201
	.word MASK_MULH,	MATCH_MULH,		string_OP_MULH,		0x00030201
	.word MASK_MULHSU,	MATCH_MULHSU,	string_OP_MULHSU,	0x00030201
	.word MASK_MULHU,	MATCH_MULHU,	string_OP_MULHU,	0x00030201
	.word MASK_DIV,		MATCH_DIV,		string_OP_DIV,		0x00030201
	.word MASK_DIVU,	MATCH_DIVU,		string_OP_DIVU,		0x00030201
	.word MASK_REM,		MATCH_REM,		string_OP_REM,		0x00030201
	.word MASK_REMU,	MATCH_REMU,		string_OP_REMU,		0x00030201
	# RV64M
	#if XLEN >= 64
		.word MASK_MULW,	MATCH_MULW,		string_OP_MULW,		0x00030201
		.word MASK_DIVW,	MATCH_DIVW,		string_OP_DIVW,		0x00030201
		.word MASK_DIVUW,	MATCH_DIVUW,	string_OP_DIVUW,	0x00030201
		.word MASK_REMW,	MATCH_REMW,		string_OP_REMW,		0x00030201
		.word MASK_REMUW,	MATCH_REMUW,	string_OP_REMUW,	0x00030201
	#endif
#endif /* DISASS_RVM */

# RVA
#ifdef DISASS_RVA
	# RV32A
	.word MASK_LR_W,		MATCH_LR_W,			string_OP_LRW, 		0x00000901
	.word MASK_SC_W,		MATCH_SC_W,			string_OP_SCW,		0x00090301
	.word MASK_AMOSWAP_W,	MATCH_AMOSWAP_W,	string_OP_AMOSWAPW,	0x00090301
	.word MASK_AMOADD_W,	MATCH_AMOADD_W,		string_OP_AMOADDW,	0x00090301
	.word MASK_AMOAND_W,	MATCH_AMOAND_W,		string_OP_AMOANDW,	0x00090301
	.word MASK_AMOOR_W,		MATCH_AMOOR_W,		string_OP_AMOORW,	0x00090301
	.word MASK_AMOXOR_W,	MATCH_AMOXOR_W,		string_OP_AMOXORW,	0x00090301
	.word MASK_AMOMAX_W,	MATCH_AMOMAX_W,		string_OP_AMOMAXW,	0x00090301
	.word MASK_AMOMIN_W,	MATCH_AMOMIN_W,		string_OP_AMOMINW,	0x00090301
	.word MASK_AMOMAXU_W,	MATCH_AMOMAXU_W,	string_OP_AMOMAXUW,	0x00090301
	.word MASK_AMOMINU_W,	MATCH_AMOMINU_W,	string_OP_AMOMINUW,	0x00090301
	# RV64A
	#if XLEN >= 64
		.word MASK_LR_D, 		MATCH_LR_D,			string_OP_LRD,		0x00000901
		.word MASK_SC_D, 		MATCH_SC_D, 		string_OP_SCD,		0x00090301
		.word MASK_AMOSWAP_D,	MATCH_AMOSWAP_D,	string_OP_AMOSWAPD,	0x00090301
		.word MASK_AMOADD_D,	MATCH_AMOADD_D,		string_OP_AMOADDD,	0x00090301
		.word MASK_AMOAND_D,	MATCH_AMOAND_D,		string_OP_AMOANDD,	0x00090301
		.word MASK_AMOOR_D,		MATCH_AMOOR_D,		string_OP_AMOORD,	0x00090301
		.word MASK_AMOXOR_D,	MATCH_AMOXOR_D,		string_OP_AMOXORD,	0x00090301
		.word MASK_AMOMAX_D,	MATCH_AMOMAX_D,		string_OP_AMOMAXD,	0x00090301
		.word MASK_AMOMIN_D,	MATCH_AMOMIN_D,		string_OP_AMOMIND,	0x00090301
		.word MASK_AMOMAXU_D,	MATCH_AMOMAXU_D,	string_OP_AMOMAXUD,	0x00090301
		.word MASK_AMOMINU_D,	MATCH_AMOMINU_D,	string_OP_AMOMINUD,	0x00090301
	#endif
#endif /* DISASS_RVA */

# RVF / RVD / RVQ
#ifdef DISASS_RVF
	.word MASK_FLW,			MATCH_FLW,			string_OP_FLW,			0x0009040d
	.word MASK_FSW,			MATCH_FSW,			string_OP_FSW,			0x0009050f
	.word MASK_FMADD_S,		MATCH_FMADD_S,		string_OP_FMADD_S,		0x100f0e0d
	.word MASK_FMSUB_S,		MATCH_FMSUB_S,		string_OP_FMSUB_S,		0x100f0e0d
	.word MASK_FNMADD_S,	MATCH_FNMADD_S,		string_OP_FNMADD_S,		0x100f0e0d
	.word MASK_FNMSUB_S,	MATCH_FNMSUB_S,		string_OP_FNMSUB_S,		0x100f0e0d
	.word MASK_FSUB_S,		MATCH_FSUB_S,		string_OP_FSUB_S,		0x000f0e0d
	.word MASK_FADD_S,		MATCH_FADD_S,		string_OP_FADD_S,		0x000f0e0d
	.word MASK_FMUL_S,		MATCH_FMUL_S,		string_OP_FMUL_S,		0x000f0e0d
	.word MASK_FDIV_S,		MATCH_FDIV_S,		string_OP_FDIV_S,		0x000f0e0d
	.word MASK_FSQRT_S,		MATCH_FSQRT_S,		string_OP_FSQRT_S,		0x00000e0d
	.word MASK_FSGNJ_S,		MATCH_FSGNJ_S,		string_OP_FSGNJ_S,		0x000f0e0d
	.word MASK_FSGNJN_S,	MATCH_FSGNJN_S,		string_OP_FSGNJN_S,		0x000f0e0d
	.word MASK_FSGNJX_S,	MATCH_FSGNJX_S,		string_OP_FSGNJX_S,		0x000f0e0d
	.word MASK_FMIN_S,		MATCH_FMIN_S,		string_OP_FMIN_S,		0x000f0e0d
	.word MASK_FMAX_S,		MATCH_FMAX_S,		string_OP_FMAX_S,		0x000f0e0d
	.word MASK_FCVT_S_W,	MATCH_FCVT_S_W,		string_OP_FCVT_S_W,		0x0000020d
	.word MASK_FCVT_S_WU,	MATCH_FCVT_S_WU,	string_OP_FCVT_S_WU,	0x0000020d
	.word MASK_FCVT_W_S,	MATCH_FCVT_W_S,		string_OP_FCVT_W_S,		0x00000e01
	.word MASK_FCVT_WU_S,	MATCH_FCVT_WU_S,	string_OP_FCVT_WU_S,	0x00000e01
	.word MASK_FMV_X_S,		MATCH_FMV_X_S,		string_OP_FMV_X_S,		0x00000e01
	.word MASK_FMV_S_X,		MATCH_FMV_S_X,		string_OP_FMV_S_X,		0x0000020d
	.word MASK_FLT_S,		MATCH_FLT_S,		string_OP_FLT_S,		0x000f0e0d
	.word MASK_FEQ_S,		MATCH_FEQ_S,		string_OP_FEQ_S,		0x000f0e0d
	.word MASK_FLE_S,		MATCH_FLE_S,		string_OP_FLE_S,		0x000f0e0d
	.word MASK_FCLASS_S,	MATCH_FCLASS_S,		string_OP_FCLASS_S,		0x0000000d
	#ifdef DISASS_RVD
		.word MASK_FLD,			MATCH_FLD,			string_OP_FLD,			0x0009040d
		.word MASK_FSD,			MATCH_FSD,			string_OP_FSD,			0x0009050f
		.word MASK_FMADD_D,		MATCH_FMADD_D,		string_OP_FMADD_D,		0x100f0e0d
		.word MASK_FMSUB_D,		MATCH_FMSUB_D,		string_OP_FMSUB_D,		0x100f0e0d
		.word MASK_FNMADD_D,	MATCH_FNMADD_D,		string_OP_FNMADD_D,		0x100f0e0d
		.word MASK_FNMSUB_D,	MATCH_FNMSUB_D,		string_OP_FNMSUB_D,		0x100f0e0d
		.word MASK_FADD_D,		MATCH_FADD_D,		string_OP_FADD_D,		0x000f0e0d
		.word MASK_FSUB_D,		MATCH_FSUB_D,		string_OP_FSUB_D,		0x000f0e0d
		.word MASK_FMUL_D,		MATCH_FMUL_D,		string_OP_FMUL_D,		0x000f0e0d
		.word MASK_FDIV_D,		MATCH_FDIV_D,		string_OP_FDIV_D,		0x000f0e0d
		.word MASK_FSQRT_D,		MATCH_FSQRT_D,		string_OP_FSQRT_D,		0x00000e0d
		.word MASK_FSGNJ_D,		MATCH_FSGNJ_D,		string_OP_FSGNJ_D,		0x000f0e0d
		.word MASK_FSGNJN_D,	MATCH_FSGNJN_D,		string_OP_FSGNJN_D,		0x000f0e0d
		.word MASK_FSGNJX_D,	MATCH_FSGNJX_D,		string_OP_FSGNJX_D,		0x000f0e0d
		.word MASK_FMIN_D,		MATCH_FMIN_D,		string_OP_FMIN_D,		0x000f0e0d
		.word MASK_FMAX_D,		MATCH_FMAX_D,		string_OP_FMAX_D,		0x000f0e0d
		.word MASK_FCVT_D_W,	MATCH_FCVT_D_W,		string_OP_FCVT_D_W,		0x0000020d
		.word MASK_FCVT_D_WU,	MATCH_FCVT_D_WU,	string_OP_FCVT_D_WU,	0x0000020d
		.word MASK_FCVT_W_D,	MATCH_FCVT_W_D,		string_OP_FCVT_W_D,		0x00000e01
		.word MASK_FCVT_WU_D,	MATCH_FCVT_WU_D,	string_OP_FCVT_WU_D,	0x00000e01
		.word MASK_FMV_X_D,		MATCH_FMV_X_D,		string_OP_FMV_X_D,		0x00000e01
		.word MASK_FMV_D_X,		MATCH_FMV_D_X,		string_OP_FMV_D_X,		0x0000020d
		.word MASK_FEQ_D,		MATCH_FEQ_D,		string_OP_FEQ_D,		0x000f0e0d
		.word MASK_FLT_D,		MATCH_FLT_D,		string_OP_FLT_D,		0x000f0e0d
		.word MASK_FLE_D,		MATCH_FLE_D,		string_OP_FLE_D,		0x000f0e0d
		.word MASK_FCLASS_D,	MATCH_FCLASS_D,		string_OP_FCLASS_D,		0x0000000d
		#ifdef DISASS_RVQ
			.word MASK_FLQ,			MATCH_FLQ,			string_OP_FLQ,			0x0009040d
			.word MASK_FSQ,			MATCH_FSQ,			string_OP_FSQ,			0x0009050f
			.word MASK_FMADD_Q,		MATCH_FMADD_Q,		string_OP_FMADD_Q,		0x100f0e0d
			.word MASK_FMSUB_Q,		MATCH_FMSUB_Q,		string_OP_FMSUB_Q,		0x100f0e0d
			.word MASK_FNMADD_Q,	MATCH_FNMADD_Q,		string_OP_FNMADD_Q,		0x100f0e0d
			.word MASK_FNMSUB_Q,	MATCH_FNMSUB_Q,		string_OP_FNMSUB_Q,		0x100f0e0d
			.word MASK_FADD_Q,		MATCH_FADD_Q,		string_OP_FADD_Q,		0x000f0e0d
			.word MASK_FSUB_Q,		MATCH_FSUB_Q,		string_OP_FSUB_Q,		0x000f0e0d
			.word MASK_FMUL_Q,		MATCH_FMUL_Q,		string_OP_FMUL_Q,		0x000f0e0d
			.word MASK_FDIV_Q,		MATCH_FDIV_Q,		string_OP_FDIV_Q,		0x000f0e0d
			.word MASK_FSQRT_Q,		MATCH_FSQRT_Q,		string_OP_FSQRT_Q,		0x00000e0d
			.word MASK_FSGNJ_Q,		MATCH_FSGNJ_Q,		string_OP_FSGNJ_Q,		0x000f0e0d
			.word MASK_FSGNJN_Q,	MATCH_FSGNJN_Q,		string_OP_FSGNJN_Q,		0x000f0e0d
			.word MASK_FSGNJX_Q,	MATCH_FSGNJX_Q,		string_OP_FSGNJX_Q,		0x000f0e0d
			.word MASK_FMIN_Q,		MATCH_FMIN_Q,		string_OP_FMIN_Q,		0x000f0e0d
			.word MASK_FMAX_Q,		MATCH_FMAX_Q,		string_OP_FMAX_Q,		0x000f0e0d
			.word MASK_FCVT_Q_W,	MATCH_FCVT_Q_W,		string_OP_FCVT_Q_W,		0x0000020d
			.word MASK_FCVT_Q_WU,	MATCH_FCVT_Q_WU,	string_OP_FCVT_Q_WU,	0x0000020d
			.word MASK_FCVT_W_Q,	MATCH_FCVT_W_Q,		string_OP_FCVT_W_Q,		0x00000e01
			.word MASK_FCVT_WU_Q,	MATCH_FCVT_WU_Q,	string_OP_FCVT_WU_Q,	0x00000e01
			#if XLEN >=128
				.word MASK_FMV_X_Q, MATCH_FMV_X_Q,		string_OP_FMV_X_Q,		0x00000e01
				.word MASK_FMV_Q_X, MATCH_FMV_Q_X,		string_OP_FMV_Q_X,		0x0000020d
			#endif
			.word MASK_FEQ_Q,		MATCH_FEQ_Q,		string_OP_FEQ_Q,		0x000f0e0d
			.word MASK_FLT_Q,		MATCH_FLT_Q,		string_OP_FLT_Q,		0x000f0e0d
			.word MASK_FLE_Q,		MATCH_FLE_Q,		string_OP_FLE_Q,		0x000f0e0d
			.word MASK_FCLASS_Q,	MATCH_FCLASS_Q,		string_OP_FCLASS_Q,		0x0000000d
		#endif /* DISASS_RVQ */
	#endif /* DISASS_RVD */
#endif /* DISASS_RVF */

# RVC
#ifdef DISASS_RVC
	# RV32C
	.word MASK_C_LW,		MATCH_C_LW,			string_OP_C_LW,			0x00151b17
	.word MASK_C_SW,		MATCH_C_SW,			string_OP_C_SW,			0x00151b16
	.word MASK_C_ADDI,		MATCH_C_ADDI,		string_OP_C_ADDI,		0x0000181c	# todo: check imm != 0
	.word MASK_C_ADDIW,		MATCH_C_ADDIW,		string_OP_C_ADDIW,		0x0000181c
	.word MASK_C_ADDI16SP,	MATCH_C_ADDI16SP,	string_OP_C_ADDI16SP,	0x00002524
	.word MASK_C_ADDI4SPN,	MATCH_C_ADDI4SPN,	string_OP_C_ADDI4SPN,	0x001a2617
	.word MASK_C_JAL,		MATCH_C_JAL,		string_OP_C_JAL,		0x0000001e
	.word MASK_C_LI,		MATCH_C_LI,			string_OP_C_LI,			0x0000181c
	.word MASK_C_LUI,		MATCH_C_LUI,		string_OP_C_LUI,		0x0000181c	# todo: check rd != x2 and imm != 0
	.word MASK_C_SRLI,		MATCH_C_SRLI,		string_OP_C_SRLI,		0x00001816
	.word MASK_C_SRAI,		MATCH_C_SRAI,		string_OP_C_SRAI,		0x00001816
	.word MASK_C_ANDI,		MATCH_C_ANDI,		string_OP_C_ANDI,		0x00001817
	.word MASK_C_SUB,		MATCH_C_SUB,		string_OP_C_SUB,		0x00001716
	.word MASK_C_XOR,		MATCH_C_XOR,		string_OP_C_XOR,		0x00001716
	.word MASK_C_OR,		MATCH_C_OR,			string_OP_C_OR,			0x00001716
	.word MASK_C_AND,		MATCH_C_AND,		string_OP_C_AND,		0x00001716
	.word MASK_C_SUBW,		MATCH_C_SUBW,		string_OP_C_SUBW,		0x00001716
	.word MASK_C_ADDW,		MATCH_C_ADDW,		string_OP_C_ADDW,		0x00001716
	.word MASK_C_J,			MATCH_C_J,			string_OP_C_J,			0x0000001e
	.word MASK_C_BEQZ,		MATCH_C_BEQZ,		string_OP_C_BEQZ,		0x00002316
	.word MASK_C_BNEZ,		MATCH_C_BNEZ,		string_OP_C_BNEZ,		0x00002316
	.word MASK_C_SLLI,		MATCH_C_SLLI,		string_OP_C_SLLI,		0x0000181c
	.word MASK_C_LWSP,		MATCH_C_LWSP,		string_OP_C_LWSP,		0x002a1f1c
	.word MASK_C_EBREAK,	MATCH_C_EBREAK,		string_OP_C_EBREAK,		0x00000000	# before c.jalr, c.add
	.word MASK_C_JALR,		MATCH_C_JALR,		string_OP_C_JALR,		0x00000013	# before c.add
	.word MASK_C_ADD,		MATCH_C_ADD,		string_OP_C_ADD,		0x00001d1c
	.word MASK_C_SWSP,		MATCH_C_SWSP,		string_OP_C_SWSP,		0x002a1914
	.word MASK_C_NOP,		MATCH_C_NOP,		string_OP_C_NOP,		0x00000000
	.word MASK_C_JR,		MATCH_C_JR,			string_OP_C_JR,			0x00000013	# todo: check rs1 != 0
	.word MASK_C_MV,		MATCH_C_MV,			string_OP_C_MV,			0x00001d1c

	# RV64C
	#if XLEN >= 64
		.word MASK_C_LD,		MATCH_C_LD,		string_OP_C_LD,		0x00152817
		.word MASK_C_SD,		MATCH_C_SD,		string_OP_C_SD,		0x00152816
		.word MASK_C_LDSP,		MATCH_C_LDSP,	string_OP_C_LDSP,	0x002a211c
		.word MASK_C_SDSP,		MATCH_C_SDSP,	string_OP_C_SDSP,	0x002a2014
	#endif /* XLEN >= 64 */

	# RV128C
	#if XLEN >= 128
		.word MASK_C_LQ,		MATCH_C_LQ,		string_OP_C_LQ,		0x00152917
		.word MASK_C_SQ,		MATCH_C_SQ,		string_OP_C_SQ,		0x00152916
		.word MASK_C_LQSP,		MATCH_C_LQSP,	string_OP_C_LQSP,	0x002a221c
		.word MASK_C_SQSP,		MATCH_C_SQSP,	string_OP_C_SQSP,	0x002a2714
		.word MASK_C_SRLI64,	MATCH_C_SRLI64,	string_OP_C_SRLI64,	0x00000000	# todo
		.word MASK_C_SRAI64,	MATCH_C_SRAI64,	string_OP_C_SRAI64,	0x00000000	# todo
		.word MASK_C_SLLI64,	MATCH_C_SLLI64,	string_OP_C_SLLI64,	0x00000000	# todo
	#endif /* XLEN >= 128 */

	#ifdef DISASS_RVF
		.word MASK_C_FLW,	MATCH_C_FLW,	string_OP_C_FLW,	0x00151b17
		.word MASK_C_FSW,	MATCH_C_FSW,	string_OP_C_FSW,	0x00151b16
		.word MASK_C_FLWSP, MATCH_C_FLWSP, 	string_OP_C_FLWSP,	0x002a1f1c
		.word MASK_C_FSWSP,	MATCH_C_FSWSP,	string_OP_C_FSWSP,	0x002a1914
	#endif /* DISASS_RVF */

	#if defined DISASS_RVD && XLEN >= 64
		.word MASK_C_FLD,	MATCH_C_FLD,	string_OP_C_FLD,	0x00152817
		.word MASK_C_FSD,	MATCH_C_FSD,	string_OP_C_FSD,	0x00152816
		.word MASK_C_FLDSP,	MATCH_C_FLDSP,	string_OP_C_FLDSP,	0x002a211c
		.word MASK_C_FSDSP,	MATCH_C_FSDSP,	string_OP_C_FSDSP,	0x002a2014
	#endif /* defined DISASS_RVD && XLEN >= 64 */

	#if defined DISASS_RVQ && XLEN >= 128
		.word MASK_C_FLQ,	MATCH_C_FLQ,	string_OP_C_FLQ,	0x00152917
		.word MASK_C_FSQ,	MATCH_C_FSQ,	string_OP_C_FSQ,	0x00152916
		.word MASK_C_FLQSP,	MATCH_C_FLQSP,	string_OP_C_FLQSP,	0x002a221c
		.word MASK_C_FSQSP,	MATCH_C_FSQSP,	string_OP_C_FSQSP,	0x002a2714
	#endif /* defined DISASS_RVQ && XLEN >= 128 */

#endif /* DISASS_RVC */

# Zifencei
#ifdef DISASS_RVZifencei
	.word MASK_FENCE_I,		MATCH_FENCE_I,	string_OP_FENCE_I,	0x00000000
#endif /* DISASS_RVZifencei */

# Zicsr
#ifdef DISASS_RVZicsr
	.word MASK_CSRRW,	MATCH_CSRRW,	string_OP_CSRRW,	0x00021101
	.word MASK_CSRRS,	MATCH_CSRRS,	string_OP_CSRRS,	0x00021101
	.word MASK_CSRRC,	MATCH_CSRRC,	string_OP_CSRRC,	0x00021101
	.word MASK_CSRRWI,	MATCH_CSRRWI,	string_OP_CSRRWI,	0x00121101
	.word MASK_CSRRCI,	MATCH_CSRRCI,	string_OP_CSRRCI,	0x00121101
	.word MASK_CSRRSI,	MATCH_CSRRSI,	string_OP_CSRRSI,	0x00121101
#endif /* DISASS_RVZicsr */

# Privileged
#ifdef DISASS_RVPRIV
	.word MASK_WFI,			MATCH_WFI,			string_OP_WFI,			0x00000000
	.word MASK_MRET,		MATCH_MRET,			string_OP_MRET,			0x00000000
	.word MASK_SRET,		MATCH_SRET,			string_OP_SRET,			0x00000000
	.word MASK_SFENCE_VM,	MATCH_SFENCE_VM,	string_OP_SFENCE_VM,	0x00000000
	.word MASK_SFENCE_VMA,	MATCH_SFENCE_VMA,	string_OP_SFENCE_VMA,	0x00000000
#endif /* DISASS_RVPRIV */


# we want to put these at the end, because we need them only for assembly
# and we prefer the originals for disassembly
#ifdef DISASS_PSEUDO
	# bgt is blt with rs1, rs2 exchanged
	.word MASK_BLT, MATCH_BLT, string_OP_BGT, 0x00060203
	# ble is bge with rs1, rs2 exchanged
	.word MASK_BGE, MATCH_BGE, string_OP_BLE, 0x00060203
	# bgtu is bltu with rs1, rs2 exchanged
	.word MASK_BLTU, MATCH_BLTU, string_OP_BGTU, 0x00060203
	# bleu is bgeu with rs1, rs2 exchanged
	.word MASK_BGEU, MATCH_BGEU, string_OP_BLEU, 0x00060203
#endif

# table end marker
.word 0,0,0,0
.size encoding_table, .-encoding_table


#endif /* #if defined (WITH_CMD_D) || defined (WITH_CMD_A) */
