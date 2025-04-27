#include "vmon/config.h"

#ifdef WITH_CMD_A


.global assemble_DUMMY


.text

# in: input string ptr in a0
assemble_DUMMY:
    ret
.size assemble_DUMMY, .-assemble_DUMMY



















.data

.align 4



#endif /* WITH_CMD_A */
