#include "config.h"


#ifdef WITH_CMD_H

.global cmd_H

.text


cmd_H:
	la		a0, string_help
	jal		print_string
	j		main_prompt
.size cmd_H, .-cmd_H


	.data
string_help:
.ascii "\nCommands:\n"
#ifdef WITH_CMD_A
.ascii "	a <start_addr> - assembly input (ENTER to stop)\n"
#endif /* WITH_CMD_A */
#ifdef WITH_CMD_B
.ascii "	b - list breakpoints\n"
.ascii "	bc <addr> - clear breakpoint\n"
.ascii "	br <addr> - reset (clear) all breakpoints\n"
.ascii "	bs <addr> - set breakpoint\n"
#endif /* WITH_CMD_B */
#ifdef WITH_CMD_C
.ascii "	c <src_start> <src_end> <dst_start> - copy memory\n"
#endif /* WITH_CMD_C */
#ifdef WITH_CMD_D 
.ascii "	d <start_addr> - disassemble 16 instructions starting at start_addr\n"
.ascii "	d <start_addr> <end_addr> - disassemble from start_addr to end_addr\n"
.ascii "	d - continue disassembly from last address\n"
#endif /* WITH_CMD_D */
#ifdef WITH_CMD_F
.ascii "	f <start_addr> <end_addr> <byte_value> - find byte value\n"
.ascii "	fb <start_addr> <end_addr> <byte_value> - find byte value\n"
.ascii "	fh <start_addr> <end_addr> <16bit_value> - find 16bit value\n"
.ascii "	fw <start_addr> <end_addr> <32bit_value> - find 32bit value\n"
#endif /* WITH_CMD_F */
#ifdef WITH_CMD_G
.ascii "	g <start_addr> - go to start_addr\n"
#endif /* WITH_CMD_G */
.ascii "	h - help\n"
#ifdef WITH_CMD_I
.ascii "	i - print segment and debugging information\n"
#endif /* WITH_CMD_I */
#ifdef WITH_CMD_M
.ascii "	m <start_addr> - memory dump 128 bytes starting at start_addr\n"
.ascii "	m <start_addr> <end_addr> - memory dump from start_addr to end_addr\n"
.ascii "	m - continue memory dump from last address\n"
#endif /* WITH_CMD_M */
#ifdef WITH_CMD_P
.ascii "	p <dst_addr> <byte_value0> [...] - write byte_value(s) starting at dst_addr\n"
.ascii "	pw <dst_addr> <32bit_value0> [...] - write 32bit_value(s) starting at dst_addr\n"
#endif /* WITH_CMD_P */
#ifdef WITH_CMD_R
.ascii "	r - dump registers as saved on entry \n"
#endif /* WITH_CMD_R */
#ifdef WITH_CMD_S
.ascii "	s <register_name> <numeric_value> - set saved register value \n"
#endif /* WITH_CMD_S */
.ascii "	x - exit to caller\n"
#ifdef WITH_CMD_QMARK
.ascii "	? <numeric_value> - print value in hex, decimal and binary\n"
#endif /* WITH_CMD_QMARK */
.string "All addresses and values are accepted in hex (0x...), bin (0b...) or decimal (no prefix).\n"
.size string_help, .-string_help


#endif /* WITH_CMD_H */
