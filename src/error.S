#include "vmon/config.h"


.global error_no_addr
.global error_unknown_command


.data
error_no_addr:          .string "ERROR: address invalid";
error_unknown_command:	.string "ERROR: unknown command";

