#ifndef VMON_UART_H
#define VMON_UART_H

#define UART_BASE		0x10000000
#define UART_REG_IER	2
#define UART_IRQ_ON		0b00000001
#define UART_REG_LSR	5
#define UART_MODE_8N1   0b00000011

#define UART_REGSIZE	4

#endif /* VMON_UART_H */