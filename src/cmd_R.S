#include "vmon/config.h"


#ifdef WITH_CMD_R

.global cmd_R

.text


cmd_R:
	# dump registers as they were on entry
	jal		print_int_registers
	jal		print_newline
	#ifdef ENABLE_RVF
		jal		print_float_registers
		jal		print_newline
	#endif /* ENABLE_RVF */
	j		main_prompt
.size cmd_R, .-cmd_R


#endif /* WITH_CMD_R */
