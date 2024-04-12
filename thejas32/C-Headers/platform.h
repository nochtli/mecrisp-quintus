// See LICENSE for license details.

#ifndef _VEGA_PLATFORM_H
#define _VEGA_PLATFORM_H

#include <stdint.h>

/****************************************************************************
 * Platform definitions
 *****************************************************************************/

#define GPIO_BASE_ADDR 0x10080000
#define GPI1_BASE_ADDR 0x10180000

#define IIC0_BASE_ADDR 0x10000800
#define IIC1_BASE_ADDR 0x10000900
#define IIC_ADC_ADDR   0x10001000

#define UART0_BASE_ADDR 0x10000100
#define UART1_BASE_ADDR 0x10000200
#define UART2_BASE_ADDR 0x10000300

#define SPI0_BASE_ADDR 0x10000600
#define SPI1_BASE_ADDR  0x10000700
#define SPI2_BASE_ADDR 0x10200100
#define SPI3_BASE_ADDR 0x10200200

#define PWM0_BASE_ADDR 0x10400000
#define PWM1_BASE_ADDR 0x10400010
#define PWM2_BASE_ADDR 0x10400020
#define PWM3_BASE_ADDR 0x10400030
#define PWM4_BASE_ADDR 0x10400040
#define PWM5_BASE_ADDR 0x10400050
#define PWM6_BASE_ADDR 0x10400060
#define PWM7_BASE_ADDR 0x10400070

#define TIMER0_BASE_ADDR 0x10000A00
#define TIMER1_BASE_ADDR 0x10000A14
#define TIMER2_BASE_ADDR 0x10000A28

#define TIMERSINTSTATUS_BASE_ADDR 	  0x10000AA0

#define TIMERSEOI_BASE_ADDR 		  0x10000AA4

#define TIMERSRAWINTSTATUS_BASE_ADDR  0x1000_0AA8


//Register offsets
// New
#define UART_LSR_DR			    (1)			//Data Ready
#define UART_LSR_THRE			(1 << 5)    //Transmitter Holding Register
#define UART_LSR_TEMT			(1 << 6)	//Transmitter Empty

// SPI
#define SPIM_CR                         0x00                    // Control Register
#define SPIM_SR                         0x04                    // Status Register
#define SPIM_BRR                        0x08                   // Baud Rate Register
#define SPIM_TDR                        0x0C                    // Transmit Data Register
#define SPIM_RDR                        0x10                   // Receive Data Register

// Helper functions
#define _REG32(p, i) (*((volatile unsigned int *) (p+ i)))
#define _REG8(p, i) (*((volatile unsigned char *) (p+ i)))
#define _REG8P(p, i) (*((volatile unsigned char *) (p+ i)))
#define _REG32P(p, i) (*(volatile unsigned int *) (p + i))

#define GPIO_REG(offset) _REG32(GPIO_BASE_ADDR, offset)

#define IIC0_REG(offset) _REG8(IIC0_BASE_ADDR, offset)
#define IIC1_REG(offset) _REG8(IIC1_BASE_ADDR, offset)
#define IIC8_REG(offset) _REG8(IIC_ADC_ADDR, offset)

#define PWM0_REG(offset) _REG32(PWM0_BASE_ADDR, offset)
#define PWM1_REG(offset) _REG32(PWM1_BASE_ADDR, offset)
#define PWM2_REG(offset) _REG32(PWM2_BASE_ADDR, offset)
#define PWM3_REG(offset) _REG32(PWM3_BASE_ADDR, offset)
#define PWM4_REG(offset) _REG32(PWM4_BASE_ADDR, offset)
#define PWM5_REG(offset) _REG32(PWM5_BASE_ADDR, offset)
#define PWM6_REG(offset) _REG32(PWM6_BASE_ADDR, offset)
#define PWM7_REG(offset) _REG32(PWM7_BASE_ADDR, offset)

#define SPI0_REG(offset) _REG32(SPI0_BASE_ADDR, offset)
#define SPI1_REG(offset) _REG32(SPI1_BASE_ADDR, offset)
#define SPI2_REG(offset) _REG32(SPI2_BASE_ADDR, offset)
#define SPI3_REG(offset) _REG32(SPI3_BASE_ADDR, offset)

#define TIMER0_REG(offset) _REG32(TIMER0_BASE_ADDR, offset)
#define TIMER1_REG(offset) _REG32(TIMER1_BASE_ADDR, offset)
#define TIMER2_REG(offset) _REG32(TIMER2_BASE_ADDR, offset)

#define UART0_REG(offset) _REG32(UART0_BASE_ADDR, offset)
#define UART1_REG(offset) _REG32(UART1_BASE_ADDR, offset)
#define UART2_REG(offset) _REG32(UART2_BASE_ADDR, offset)




#endif /* _VEGA_PLATFORM_H */
