#include "vmon/config.h"


#ifdef WITH_CMD_I

.global cmd_I

.text


cmd_I:
    la      a0, string_info_instructionset
    jal     print_string
    li      a0, XLEN
    jal     print_decimal
    li      a0, 'i'
    jal     print_char
#ifdef ENABLE_RVM
    li      a0, 'm'
    jal     print_char
#endif
#ifdef ENABLE_RVA
    li      a0, 'a'
    jal     print_char
#endif
#ifdef ENABLE_RVF
    li      a0, 'f'
    jal     print_char
#endif
#ifdef ENABLE_RVD
    li      a0, 'd'
    jal     print_char
#endif
#ifdef ENABLE_RVC
    li      a0, 'c'
    jal     print_char
#endif
#ifdef ENABLE_RVV
    li      a0, 'v'
    jal     print_char
#endif
#ifdef ENABLE_RVZicsr
    la      a0, string_info_Zicsr 
    jal     print_string
#endif
#ifdef ENABLE_RVZifencei
    la      a0, string_info_Zifencei
    jal     print_string
#endif

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
string_info_instructionset:
    .string "instructions: rv";
string_info_Zicsr:
    .string "_Zicsr";
string_info_Zifencei:
    .string "_Zifencei";
string_info_text:
    .string "\n.text:  ";
.size string_info_text, .-string_info_text
string_info_data:
    .string "\n.data:  ";
.size string_info_data, .-string_info_data
string_info_bss:
    .string "\n.bss:   ";
.size string_info_bss, .-string_info_bss
string_info_buffer:
    .string "\nbuffer: ";
.size string_info_buffer, .-string_info_buffer
string_info_stackstart:
    .string "\nstack start: ";
.size string_info_stackstart, .-string_info_stackstart
string_info_stackend:
    .string "\nstack end:   ";
.size string_info_stackend, .-string_info_stackend
string_info_stacksize:
    .string "\nstack bytes free: ";
.size string_info_stacksize, .-string_info_stacksize
string_info_testcode:
    .string "\ntestcode: ";
.size string_info_testcode, .-string_info_testcode

#endif /* WITH_CMD_I */
