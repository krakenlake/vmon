#include "vmon/config.h"


.global error_param
.global error_unknown_command


.data


error_param:			.string "ERROR: parameter missing or invalid";
.size error_param, .-error_param

error_unknown_command:	.string "ERROR: unknown command";
.size error_unknown_command, .-error_unknown_command

