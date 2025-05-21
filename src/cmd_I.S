#include "vmon/config.h"


#ifdef WITH_CMD_I

.global cmd_I

.text


cmd_I:
	la		a0, string_info_instructionset
	jal		print_string
	li		a0, XLEN
	jal		print_decimal
	li		a0, 'i'
	jal		print_char

#ifdef DISASS_RVM
	li		a0, 'm'
	jal		print_char
#endif

#ifdef DISASS_RVA
	li		a0, 'a'
	jal		print_char
#endif

#ifdef DISASS_RVF
	li		a0, 'f'
	jal		print_char
#endif

#ifdef DISASS_RVD
	li		a0, 'd'
	jal		print_char
#endif

#ifdef DISASS_RVQ
	li		a0, 'q'
	jal		print_char
#endif

#ifdef DISASS_RVC
	li		a0, 'c'
	jal		print_char
#endif

#ifdef DISASS_RVV
	li		a0, 'v'
	jal		print_char
#endif

#ifdef DISASS_RVZicsr
	la		a0, string_info_Zicsr 
	jal		print_string
#endif

#ifdef DISASS_RVZifencei
	la		a0, string_info_Zifencei
	jal		print_string
#endif

	la		a0, string_info_text
	jal		print_string
	la		a0, start	 
	jal		print_hex

	la		a0, string_info_data
	jal		print_string
	la		a0, start_data	  
	jal		print_hex

	la		a0, string_info_bss
	jal		print_string
	la		a0, start_bss	 
	jal		print_hex

#ifdef M_MODE
	la		a0, string_info_stackstart
	jal		print_string
	la		a0, stack	
	jal		print_hex

	la		a0, string_info_stackend
	jal		print_string
	la		a0, stack + STACK_SIZE	 
	jal		print_hex

	la		a0, string_info_stacksize
	jal		print_string
	la		t0, stack	 
	sub		a0, sp, t0
	jal		print_hex
#endif /* M_MODE */

#ifdef WITH_TESTCODE
	la		a0, string_info_testcode
	jal		print_string
	la		a0, testcode 
	jal		print_hex

	#ifdef WITH_TESTCODE_RV32I
		la		a0, string_info_testcode_RV32I
		jal		print_string
		la		a0, testcode_RV32I
		jal		print_hex
	#endif /* WITH_TESTCODE_RV32I */

	#if defined(WITH_TESTCODE_RV64I) && (XLEN >= 64)
		la		a0, string_info_testcode_RV64I
		jal		print_string
		la		a0, testcode_RV64I
		jal		print_hex
	#endif /* WITH_TESTCODE_RV64I */

	#ifdef WITH_TESTCODE_RVM
		la		a0, string_info_testcode_RVM
		jal		print_string
		la		a0, testcode_RVM
		jal		print_hex
	#endif /* WITH_TESTCODE_RVM */

	#ifdef WITH_TESTCODE_RVA
		la		a0, string_info_testcode_RVA
		jal		print_string
		la		a0, testcode_RVA
		jal		print_hex
	#endif /* WITH_TESTCODE_RVA */

	#ifdef WITH_TESTCODE_RVF
		la		a0, string_info_testcode_RVF
		jal		print_string
		la		a0, testcode_RVF
		jal		print_hex
	#endif /* WITH_TESTCODE_RVF */

	#if defined (WITH_TESTCODE_RVD) && XLEN >= 64
		la		a0, string_info_testcode_RVD
		jal		print_string
		la		a0, testcode_RVD
		jal		print_hex
	#endif /* WITH_TESTCODE_RVD */

	#if defined (WITH_TESTCODE_RVQ) && XLEN >= 128
		la		a0, string_info_testcode_RVQ
		jal		print_string
		la		a0, testcode_RVQ
		jal		print_hex
	#endif /* WITH_TESTCODE_RVQ */

	#if defined (WITH_TESTCODE_RVC) && defined (DISASS_RVC)
		la		a0, string_info_testcode_RVC
		jal		print_string
		la		a0, testcode_RVC
		jal		print_hex
	#endif /* WITH_TESTCODE_RVC */

	#ifdef WITH_TESTCODE_RVV
		la		a0, string_info_testcode_RVV
		jal		print_string
		la		a0, testcode_RVV
		jal		print_hex
	#endif /* WITH_TESTCODE_RVV */

	#ifdef WITH_TESTCODE_RVZicsr
		la		a0, string_info_testcode_RVZicsr
		jal		print_string
		la		a0, testcode_RVZicsr
		jal		print_hex
	#endif /* WITH_TESTCODE_RVZicsr */

	#ifdef WITH_TESTCODE_RVZifencei
		la		a0, string_info_testcode_RVZifencei
		jal		print_string
		la		a0, testcode_RVZifencei
		jal		print_hex
	#endif /* WITH_TESTCODE_RVZifencei */

	#ifdef WITH_TESTCODE_RVPRIV
		la		a0, string_info_testcode_RVPRIV
		jal		print_string
		la		a0, testcode_RVPRIV
		jal		print_hex
	#endif /* WITH_TESTCODE_RVPRIV */

	#ifdef WITH_TESTCODE_PSEUDO
		la		a0, string_info_testcode_PSEUDO
		jal		print_string
		la		a0, testcode_PSEUDO
		jal		print_hex
	#endif /* WITH_TESTCODE_PSEUDO */

#endif /* WITH_TESTCODE */

	j		main_prompt
.size cmd_I, .-cmd_I


.data


string_info_instructionset:
	.string "instructions: rv";
.size string_info_instructionset, .-string_info_instructionset
string_info_Zicsr:
	.string "_Zicsr";
.size string_info_Zicsr, .-string_info_Zicsr
string_info_Zifencei:
	.string "_Zifencei";
.size string_info_Zifencei, .-string_info_Zifencei
string_info_text:
	.string "\n.text:  ";
.size string_info_text, .-string_info_text
string_info_data:
	.string "\n.data:  ";
.size string_info_data, .-string_info_data
string_info_bss:
	.string "\n.bss:   ";
.size string_info_bss, .-string_info_bss
string_info_buffer:
	.string "\nbuffer: ";
.size string_info_buffer, .-string_info_buffer
string_info_stackstart:
	.string "\nstack start: ";
.size string_info_stackstart, .-string_info_stackstart
string_info_stackend:
	.string "\nstack end:   ";
.size string_info_stackend, .-string_info_stackend
string_info_stacksize:
	.string "\nstack bytes free: ";
.size string_info_stacksize, .-string_info_stacksize

#ifdef WITH_TESTCODE
string_info_testcode:
	.string "\ntestcode: ";
.size string_info_testcode, .-string_info_testcode

	#ifdef WITH_TESTCODE_RV32I
	string_info_testcode_RV32I:
		.string "\n RV32I: ";
	.size string_info_testcode_RV32I, .-string_info_testcode_RV32I
	#endif

	#ifdef WITH_TESTCODE_RV64I
	string_info_testcode_RV64I:
		.string "\n RV64I: ";
	.size string_info_testcode_RV64I, .-string_info_testcode_RV64I
	#endif

	#ifdef WITH_TESTCODE_RVM
	string_info_testcode_RVM:
		.string "\n RVM: ";
	.size string_info_testcode_RVM, .-string_info_testcode_RVM
	#endif

	#ifdef WITH_TESTCODE_RVA
	string_info_testcode_RVA:
		.string "\n RVA: ";
	.size string_info_testcode_RAM, .-string_info_testcode_RVA
	#endif

	#ifdef WITH_TESTCODE_RVF
	string_info_testcode_RVF:
		.string "\n RVF: ";
	.size string_info_testcode_RVF, .-string_info_testcode_RVF
	#endif

	#ifdef WITH_TESTCODE_RVD
	string_info_testcode_RVD:
		.string "\n RVD: ";
	.size string_info_testcode_RVD, .-string_info_testcode_RVD
	#endif

	#ifdef WITH_TESTCODE_RVQ
	string_info_testcode_RVQ:
		.string "\n RVQ: ";
	.size string_info_testcode_RVQ, .-string_info_testcode_RVQ
	#endif

	#ifdef WITH_TESTCODE_RVC
	string_info_testcode_RVC:
		.string "\n RVC: ";
	.size string_info_testcode_RVC, .-string_info_testcode_RVC
	#endif

	#ifdef WITH_TESTCODE_RVV
	string_info_testcode_RVV:
		.string "\n RVV: ";
	.size string_info_testcode_RVV, .-string_info_testcode_RVV
	#endif

	#ifdef WITH_TESTCODE_RVZicsr
	string_info_testcode_RVZicsr:
		.string "\n RVZicsr: ";
	.size string_info_testcode_RVZicsr, .-string_info_testcode_RVZicsr
	#endif

	#ifdef WITH_TESTCODE_RVZifencei
	string_info_testcode_RVZifencei:
		.string "\n RVZifencei: ";
	.size string_info_testcode_RVZifencei, .-string_info_testcode_RVZifencei
	#endif

	#ifdef WITH_TESTCODE_RVPRIV
	string_info_testcode_RVPRIV:
		.string "\n RVPRIV: ";
	.size string_info_testcode_RVPRIV, .-string_info_testcode_RVPRIV
	#endif

	#ifdef WITH_TESTCODE_PSEUDO
	string_info_testcode_PSEUDO:
		.string "\n PSEUDO: ";
	.size string_info_testcode_PSEUDO, .-string_info_testcode_PSEUDO
	#endif
#endif /* WITH_TESTCODE */


#endif /* WITH_CMD_I */
