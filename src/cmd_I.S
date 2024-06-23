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

    j       main_prompt
.size cmd_I, .-cmd_I


.data
string_info_text:
    .string ".text addr: ";
.size string_info_text, .-string_info_text
string_info_data:
    .string "\n.data addr: ";
.size string_info_data, .-string_info_data
string_info_bss:
    .string "\n.bss addr: ";
.size string_info_bss, .-string_info_bss
string_info_buffer:
    .string "\nbuffer addr: ";
.size string_info_buffer, .-string_info_buffer
string_info_stackstart:
    .string "\nstack start addr: ";
.size string_info_stackstart, .-string_info_stackstart
string_info_stackend:
    .string "\nstack end addr: ";
.size string_info_stackend, .-string_info_stackend
string_info_stacksize:
    .string "\nstack bytes free: ";
.size string_info_stacksize, .-string_info_stacksize
string_info_testcode:
    .string "\ntestcode addr: ";
.size string_info_testcode, .-string_info_testcode

#endif /* WITH_CMD_I */
