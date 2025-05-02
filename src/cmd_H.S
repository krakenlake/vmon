	#include "vmon/config.h"


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
	c <src_start> <src_end> <dst_start> - copy memory\n\
	d <start_addr> - disassemble 16 instructions starting at start_addr\n\
	d <start_addr> <end_addr> - disassemble from start_addr to end_addr\n\
	d - continue disassembly from last address\n\
	f <start_addr> <end_addr> <byte_value> - find byte value\n\
	g <start_addr> - go to start_addr\n\
	h - help\n\
	i - print segment and debugging information\n\
	m <start_addr> - memory dump 128 bytes starting at start_addr\n\
	m <start_addr> <end_addr> - memory dump from start_addr to end_addr\n\
	m - continue memory dump from last address\n\
	p <dst_addr> <byte_value0> [...] - write byte_value(s) starting at dst_addr\n\
	x - exit to caller\n\
	All address and value entries are in hex (without 0x prefix).\n"
	.size string_help, .-string_help
	#endif /* WITH_CMD_H */
