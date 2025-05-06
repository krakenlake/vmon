#include "vmon/config.h"


#ifdef WITH_CMD_R

.global cmd_R

.text


cmd_R:
	# dump registers as they were on entry
	jal		print_saved_registers
	j		main_prompt
.size cmd_R, .-cmd_R


#endif /* WITH_CMD_R */
