// See LICENSE for license details.

#ifndef _CDAC_UART_H
#define _CDAC_UART_H

//UARTs
#define UART0                        0
#define UART1                        1
#define UART2                        2

/* Register offsets */
#define	UART_REG_DR  		0x00	//UART Data register
#define UART_REG_IE 		0x04	//UART Interrupt enable register
#define	UART_REG_IIR_FCR 	0x08	//UART Interrupt identification(Read only), FIFO control register(write only).
#define	UART_REG_LCR 		0x0C	//UART Line control register
#define	UART_REG_LSR 		0x14 //UART Line status register

/*fields*/
#define UART_LSR_DR			    (1)			//Data Ready
#define UART_LSR_THRE			(1 << 5)    //Transmitter Holding Register
#define UART_LSR_TEMT			(1 << 6)	//Transmitter Empty

#endif /* _CDAC_UART_H */
