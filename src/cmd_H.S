#include "vmon/config.h"


#ifdef WITH_CMD_H

.global cmd_H

.text


cmd_H:
    la      a0, string_help
    jal     ra, print_string
    j       prompt


.data
string_help:
.string "Commands:  
    d <start_addr> - disassemble 16 instructions starting at start_addr 
    d <start_addr> <end_addr> - disassemble from start_addr to end_addr
    d - continue disassembly from last address used
    g <start_addr> - go to start_addr
    h - help
    i - print some internal information
    m <start_addr> - memory dump 128 bytes starting at start_addr
    m - continue memory dump from last address used
    m <start_addr> <end_addr> - memory dump from start_addr to end_addr";

#endif /* WITH_CMD_H */
