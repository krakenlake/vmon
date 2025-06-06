#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"
#include "vmon/stack.h"


#if defined (WITH_CMD_D) && defined (DISASS_RVZicsr)

.global dis_csr
.global dis_csri

.text


# in: instruction word in a0
dis_csr:
	PUSH_RA
	srai	a0, a0, 20
	li		t0, 0b111111111111
	and		a0, a0, t0
	jal		print_hex
	POP_RA_RET
.size dis_csr, .-dis_csr


# in: instruction word in a0
dis_csri:
	PUSH_RA
	# extract uimm[4:0] 
	srli	a0, a0, 15
	and		a0, a0, 0b11111
	jal		print_decimal
	POP_RA_RET
.size dis_csri, .-dis_csri


#endif /* (WITH_CMD_D) && defined (DISASS_RVZicsr) */
