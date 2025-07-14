#include "config.h"


#ifdef WITH_CMD_X

.global cmd_X

.text


cmd_X:
	j		vmon_exit
.size cmd_X, .-cmd_X



#endif /* WITH_CMD_X */
