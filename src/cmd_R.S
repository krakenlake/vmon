#include "vmon/config.h"


#ifdef WITH_CMD_R

.global cmd_R

.text


cmd_R:
	# dump registers as they were on entry
	jal		print_int_registers
	#ifdef DISASS_RVF
		jal		print_float_registers
	#endif /* DISASS_RVF */
	j		main_prompt
.size cmd_R, .-cmd_R


#endif /* WITH_CMD_R */
