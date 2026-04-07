#ifndef TRAP_H
#define TRAP_H


#define TIMER_INTERVAL	10000000

#define MTIMECMP		0x2004000			# QEMU CLINT 0x2000000 + 0x4000 + 8*(hart_id)

#ifdef S_MODE
	#define MODE_PREFIX(__suffix)	s##__suffix
#else
	#define MODE_PREFIX(__suffix)	m##__suffix
#endif


#endif /* TRAP_H */
