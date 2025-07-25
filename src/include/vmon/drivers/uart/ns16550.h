#ifndef VMON_UART_H
#define VMON_UART_H

#ifdef HW_QEMU
	#define UART_BASE		0x10000000
	#define UART_REG_RDR	0x00
	#define UART_REG_THR	0x00
	#define UART_REG_IER	2
	#define UART_REG_LSR	5

	#define UART_IRQ_ON		0b00000001

	#define UART_MODE_8N1   0b00000011
#endif

#ifdef HW_VF2
	#define UART_BASE		0x10000000
	#define UART_REG_RDR	0x00
	#define UART_REG_THR	0x00
	#define UART_REG_IER	2*4
	#define UART_REG_LSR	5*4

	#define UART_IRQ_ON		0b00000001

	#define UART_MODE_8N1   0b00000011
#endif

#ifdef HW_CH32V003
	#define UART_BASE		0x40013800
	#define UART_REG_RDR	0x00
	#define UART_REG_THR	0x00
	#define UART_REG_IER	2
	#define UART_REG_LSR	5

	#define UART_IRQ_ON		0b00000001

	#define UART_MODE_8N1   0b00000011
#endif


#endif /* VMON_UART_H */