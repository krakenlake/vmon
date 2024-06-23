#include "vmon/config.h"


.global error_no_addr
.global error_unknown_command


.data
error_no_addr:          .string "ERROR: address invalid";
.size error_no_addr, .-error_no_addr
error_unknown_command:	.string "ERROR: unknown command";
.size error_unknown_command, .-error_unknown_command

