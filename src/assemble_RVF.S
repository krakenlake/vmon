#include "config.h"
#include "vmon/ASCII.h"
#include "vmon/encoding.h"
#include "vmon/register.h"


#if defined (WITH_CMD_A) && defined (DISASS_RVF)

.global ass_frd						# expect int register name and use it for frd
.global ass_frs1					# expect int register name and use it for RVF frs1
.global ass_frs2					# expect int register name and use it for RVF frs2
.global ass_frs3					# expect int register name and use it for RVF frs3

.text


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_frd:
	li		t0, 7
	la		t1, get_float_register_index_by_name
	j		assemble_register
.size ass_frd, .-ass_frd


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_frs1:
	li		t0, 15
	la		t1, get_float_register_index_by_name
	j		assemble_register
.size ass_frs1, .-ass_frs1


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_frs2:
	li		t0, 20
	la		t1, get_float_register_index_by_name
	j		assemble_register
.size ass_frs2, .-ass_frs2


# facade for assemble_register:
# - add parameter for sll in t0
# - add parameter for lookup function in t1
# - jump to assemble_register 
ass_frs3:
	li		t0, 27
	la		t1, get_float_register_index_by_name
	j		assemble_register
.size ass_frs3, .-ass_frs3


#endif /* #if defined (WITH_CMD_A) && defined (DISASS_RVF) */
