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
	.string "\nCommands:\n\
	a <start_addr> - assembly input (ENTER to stop)\n\
	b - list breakpoints\n\
	bc <addr> - clear breakpoint\n\
	br <addr> - reset (clear) all breakpoints\n\
	bs <addr> - set breakpoint\n\
	c <src_start> <src_end> <dst_start> - copy memory\n\
	d <start_addr> - disassemble 16 instructions starting at start_addr\n\
	d <start_addr> <end_addr> - disassemble from start_addr to end_addr\n\
	d - continue disassembly from last address\n\
	f <start_addr> <end_addr> <byte_value> - find byte value\n\
	fb <start_addr> <end_addr> <byte_value> - find byte value\n\
	fh <start_addr> <end_addr> <16bit_value> - find 16bit value\n\
	fw <start_addr> <end_addr> <32bit_value> - find 32bit value\n\
	g <start_addr> - go to start_addr\n\
	h - help\n\
	i - print segment and debugging information\n\
	m <start_addr> - memory dump 128 bytes starting at start_addr\n\
	m <start_addr> <end_addr> - memory dump from start_addr to end_addr\n\
	m - continue memory dump from last address\n\
	p <dst_addr> <byte_value0> [...] - write byte_value(s) starting at dst_addr\n\
	pw <dst_addr> <32bit_value0> [...] - write 32bit_value(s) starting at dst_addr\n\
	r - dump registers as saved on entry \n\
	s <register_name> <numeric_value> - set saved register value \n\
	x - exit to caller\n\
	? <numeric_value> - print value in hex, decimal and binary\n\
	All addresses and values are accepted in hex (0x...), bin (0b...) or decimal (no prefix).\n"
.size string_help, .-string_help


#endif /* WITH_CMD_H */
