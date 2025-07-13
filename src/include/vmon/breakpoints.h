#ifndef BREAKPOINTS_H
#define BREAKPOINTS_H

#include "config.h"
#include "vmon/register.h"


#ifdef WITH_CMD_B


#define BP_NUM				8

// each entry consists of one address and one instruction
#define BP_ENTRY_SIZE		(XLEN_BYTES + 4)
#define BP_TABLE_SIZE		(BP_ENTRY_SIZE * BP_NUM)


#endif /* WITH_CMD_B */


#endif /* BREAKPOINTS_H */
