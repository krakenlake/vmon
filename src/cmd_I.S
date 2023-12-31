#include "vmon/config.h"


#ifdef WITH_CMD_I

.global cmd_I

.text


cmd_I:
    la      a0, string_info_text
    jal     print_string
    la      a0, start    
    jal     print_hex

    la      a0, string_info_data
    jal     print_string
    la      a0, start_data    
    jal     print_hex

    la      a0, string_info_bss
    jal     print_string
    la      a0, start_bss    
    jal     print_hex

    la      a0, string_info_buffer
    jal     print_string
    la      a0, buffer   
    jal     print_hex

#ifdef BARE_METAL
    la      a0, string_info_stackstart
    jal     print_string
    la      a0, stack   
    jal     print_hex

    la      a0, string_info_stackend
    jal     print_string
    la      a0, stack + STACK_SIZE   
    jal     print_hex

    la      a0, string_info_stacksize
    jal     print_string
    la      t0, stack    
    sub     a0, sp, t0
    jal     print_hex
#endif /* BARE_METAL */

#ifdef WITH_TESTCODE
    la      a0, string_info_testcode
    jal     print_string
    la      a0, testcode 
    jal     print_hex
#endif /* WITH_TESTCODE */

    j       prompt


.data
string_info_text:
    .string ".text addr: ";
string_info_data:
    .string "\n.data addr: ";
string_info_bss:
    .string "\n.bss addr: ";
string_info_buffer:
    .string "\nbuffer addr: ";
string_info_stackstart:
    .string "\nstack start addr: ";
string_info_stackend:
    .string "\nstack end addr: ";
string_info_stacksize:
    .string "\nstack bytes free: ";
string_info_testcode:
    .string "\ntestcode addr: ";

#endif /* WITH_CMD_I */