#include "config.h"
#include "vmon/register.h"

#if defined (WITH_CMD_D) && defined (DISASS_RVF)

.global dis_frd
.global dis_frs1
.global dis_frs2
.global dis_frs3

.text

# in: instruction word in a0
dis_frd:
	srli	a0, a0, 7
	j		print_float_register_name	
.size dis_frd, .-dis_frd


# in: instruction word in a0
dis_frs1:
	srli	a0, a0, 15			
	j		print_float_register_name	
.size dis_frs1, .-dis_frs1


# in: instruction word in a0
dis_frs2:
	srli	a0, a0, 20			
	j		print_float_register_name	
.size dis_frs2, .-dis_frs2


# in: instruction word in a0
dis_frs3:
	srli	a0, a0, 27			 
	j		print_float_register_name	
.size dis_frs3, .-dis_frs3


# in: instruction word in a0
print_float_register_name:
	addi	sp, sp, -(XLEN_BYTES*1)				 
	SAVE_X	ra, 0(sp) 
	and		a0, a0, 0b11111
	jal		get_float_register_name_by_index
	jal		print_string
	j		pop_ra_ret
.size print_float_register_name, .-print_float_register_name


#endif /* (WITH_CMD_D) && defined (DISASS_RVF) */
