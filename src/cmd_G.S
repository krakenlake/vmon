#include "vmon/config.h"


#ifdef WITH_CMD_G

.global cmd_G

.text


cmd_G:
    la      a0, string_go
    jal     print_string
    mv      a0, s4
    jal     skip_whitespace
    jal     get_hex_addr            # read start addr from text buffer
    bnez    a2, cmd_G_error         # abort command if not found
    mv      a0, a1
    jal     print_hex
    # TODO: what about stack?
    jalr    ra, a1, 0
    j       start                   # start over if the call returns
cmd_G_error:
    la      a0, error_no_addr
    jal     print_string
    j       main_prompt
.size cmd_G, .-cmd_G


.data
string_go:              .string "jumping to address ";
.size string_go, .-string_go

#endif /* WITH_CMD_G */
