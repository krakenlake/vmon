#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVC)


.text

# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_RVC_rd:
ass_RVC_rs1:
	li		t0, 7
	la		t1, get_int_register_index_by_name
	j		assemble_register
.size ass_RVC_rs1, .-ass_RVC_rs1


ass_RVC_rs2:
	li		t0, 2
	la		t1, get_int_register_index_by_name
	j		assemble_register
.size ass_RVC_rs1, .-ass_RVC_rs1


#endif /* defined (WITH_CMD_A) && defined (DISASS_RVD) */
