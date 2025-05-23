#include "config.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_D) && defined (DISASS_RVZicsr)

.global dis_csr
.global dis_csri

.text


# in: instruction word in a0
dis_csr:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp) 
	srai	a0, a0, 20
	li		t0, 0b111111111111
	and		a0, a0, t0
	jal		print_hex
	j		pop_ra_ret
.size dis_csr, .-dis_csr


# in: instruction word in a0
dis_csri:
	addi	sp, sp, -(XLEN_BYTES*1)
	SAVE_X	ra, 0(sp)
	# extract uimm[4:0] 
	srli	a0, a0, 15
	and		a0, a0, 0b11111
	jal		print_decimal
	j		pop_ra_ret
.size dis_csri, .-dis_csri


#endif /* (WITH_CMD_D) && defined (DISASS_RVZicsr) */
