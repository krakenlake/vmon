#include "vmon/config.h"


#ifdef WITH_CMD_H

.global cmd_H

.text


cmd_H:
    la      a0, string_help
    jal     print_string
    j       prompt


.data
string_help:
.string "Commands:  
    d <start_addr> - disassemble 16 instructions starting at start_addr 
    d <start_addr> <end_addr> - disassemble from start_addr to end_addr
    d - continue disassembly from last address
    g <start_addr> - go to start_addr
    h - help
    i - print segment and debugging information
    m <start_addr> - memory dump 128 bytes starting at start_addr
    m <start_addr> <end_addr> - memory dump from start_addr to end_addr
    m - continue memory dump from last address
Addresses entry is in hex (without 0x prefix)."
#endif /* WITH_CMD_H */
