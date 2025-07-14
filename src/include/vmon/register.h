#ifndef VMON_REGISTER_H
#define VMON_REGISTER_H

// int register width
#if XLEN == 32
	#define	SAVE_X	sw
	#define LOAD_X	lw
	#define LWU		lw
	#define SWU		sw
#endif
#if XLEN == 64
	#define	SAVE_X	sd
	#define LOAD_X	ld
	#define LWU		lwu
	#define SWU		sw
#endif
#define XLEN_BYTES			(XLEN/8)

#ifdef TARGET_RVE
	#define NUM_INT_REGISTERS	16
#else
	#define NUM_INT_REGISTERS	32
#endif

// float register width
#ifdef TARGET_HAS_RVF
	#if FLEN == 32
		#define SAVE_F	fsw
		#define LOAD_F	flw
	#endif
	#if FLEN == 64
		#define	SAVE_F	fsd
		#define LOAD_F	fld
	#endif
	#define FLEN_BYTES			(FLEN/8)
#endif

#define NUM_FLOAT_REGISTERS		32

#endif /* VMON_REGISTER_H */
