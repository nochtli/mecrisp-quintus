#
#    Mecrisp-Quintus - A native code Forth implementation for RISC-V
#    Copyright (C) 2018  Matthias Koch
#    Copyright (C) 2026  Peter Schildmann
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

.include "interrupts.s"
.include "../common/terminalhooks.s"

# -----------------------------------------------------------------------------
# Labels for a few hardware ports
# -----------------------------------------------------------------------------

    .equ    RCC_BASE,             0x40021000
    .equ    OFS_RCC_CTLR,         0x00    # clock control register            0x0000xx83
    .equ    OFS_RCC_CFGR0,        0x04    # clock configuration register 0    0x00000050
    .equ    OFS_RCC_APB2PRSTR,    0x0C    # PB2 peripheral reset register     0x00000000
    .equ    OFS_RCC_APB1PRSTR,    0x10    # PB1 peripheral reset register     0x00000000
    .equ    OFS_RCC_AHBPCENR,     0x14    # HB peripheral clock enable reg.   0x00021004
    .equ    OFS_RCC_APB2PCENR,    0x18    # PB2 peripheral clock enable reg.  0x00000000
    .equ    OFS_RCC_APB1PCENR,    0x1C    # PB1 peripheral clock enable reg.  0x00000000
    .equ    OFS_RCC_RSTSCKR,      0x24    # control/status register           0x0C000000
    .equ    OFS_RCC_AHBRSTR,      0x28    # HB peripheral reset register      0x00000000

    .equ    USART2_BASE,          0x40004400
    .equ    OFS_USART_STATR,      0x00    # status register                   0x000000C0
    .equ    OFS_USART_DATAR,      0x04    # data register                     0x000000XX
    .equ    OFS_USART_BRR,        0x08    # baud rate register                0x00000000
    .equ    OFS_USART_CTLR1,      0x0C    # control register1                 0x00000000
    .equ    OFS_USART_CTLR2,      0x10    # control register2                 0x00000000
    .equ    OFS_USART_CTLR3,      0x14    # control register3                 0x00000000
    .equ    OFS_USART_GPR,        0x18    # guard time and prescaler reg.     0x00000000

    .equ    GPIOA_BASE,           0x40010800
    .equ    OFS_GPIO_CFGLR,       0x00    # configuration register low        0x44444444
    .equ    OFS_GPIO_CFGHR,       0x04    # configuration register high       0x44444444
    .equ    OFS_GPIO_INDR,        0x08    # input data register               0x0000XXXX
    .equ    OFS_GPIO_OUTDR,       0x0C    # output data register              0x00000000
    .equ    OFS_GPIO_BSHR,        0x10    # set/reset register                0x00000000
    .equ    OFS_GPIO_BCR,         0x14    # reset register                    0x00000000
    .equ    OFS_GPIO_LCKR,        0x18    # configuration lock register       0x00000000
    .equ    OFS_GPIO_CFGXR,       0x1C    # cfg reg expansion bits            0x44444444
    .equ    OFS_GPIO_BSXR,        0x20    # set/reset register high bits      0x00000000

    .equ    AFIO_BASE,            0x40010000
    .equ    OFS_AFIO_PCFR1,       0x04    # remap register 1                  0x00000000
    .equ    OFS_AFIO_EXTICR1,     0x08    # ext. interrupt cfg. register 1    0x00000000
    .equ    OFS_AFIO_EXTICR2,     0x0C    # ext. interrupt cfg. register 2    0x00000000
    .equ    OFS_AFIO_CTLR,        0x18    # control register                  0x00000045

    .equ    RXNE, 1<<5
    .equ    TXNE, 1<<7

# -----------------------------------------------------------------------------
uart_init:
# -----------------------------------------------------------------------------

# After reset, the high-speed internal oscillator (48 MHz) is enabled,
# and the HB clock source prescaler is set to divide by 6, resulting
# in an HB bus peripheral clock (HCLK) of 8 MHz.

# Power on AFIO, GPIOA, USART2
  li  x15, RCC_BASE
  li  x14, 0x00000005  # AFIO + GPIOA
  sw  x14, OFS_RCC_APB2PCENR(x15)
  li  x14, 0x00020000  # USART2
  sw  x14, OFS_RCC_APB1PCENR(x15)

# AFIO init
  li x15, AFIO_BASE
  li x14, 0x00000100  # RX: PA16, TX: PA15
  sw x14, OFS_AFIO_PCFR1(x15)

# PA15/PA16 init
  li  x15, GPIOA_BASE
  li  x14, 0xb4444444  # PA15: alternate function push-pull output
  sw  x14, OFS_GPIO_CFGHR(x15)
  li  x14, 0x44444448  # PA16: pull-up/down input mode
  sw  x14, OFS_GPIO_CFGXR(x15)
  li  x14, 0x00010000  # PA16: activate pull-up
  sw  x14, OFS_GPIO_OUTDR(x15)

# USART init
  li  x15, USART2_BASE
  li  x14, 0x00000045  # about 115200bps at 8Mhz HCLK
  sw  x14, OFS_USART_BRR(x15)
  li  x14, 0x0000000c  # transmit and receive enable
  sw  x14, OFS_USART_CTLR1(x15)
  li  x14, 0x00002000  # two stop bits
  sw  x14, OFS_USART_CTLR2(x15)
  lw  x14, OFS_USART_CTLR1(x15)
  li  x15, 1<<13       # UART enable
  or  x14, x14, x15
  li  x15, USART2_BASE
  sw  x14, OFS_USART_CTLR1(x15)
  ret
	
# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-emit"
serial_emit: # ( c -- ) Emit one character
# -----------------------------------------------------------------------------
  push x1

1:
  call serial_qemit
  popda x15
  beq x15, zero, 1b

  li x15, USART2_BASE
  sb x8, OFS_USART_DATAR(x15)
  drop

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-key"
serial_key: # ( -- c ) Receive one character
# -----------------------------------------------------------------------------
  push x1

1:
  call serial_qkey
  popda x15
  beq x15, zero, 1b

  pushdatos
  li x8, USART2_BASE
  lb x8, OFS_USART_DATAR(x8)

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-emit?"
serial_qemit:  # ( -- ? ) Ready to send a character ?
# -----------------------------------------------------------------------------
  push x1
  call pause

  pushdatos
  li  x8, USART2_BASE
  lw  x8, OFS_USART_STATR(x8)
  andi x8, x8, TXNE

  sltiu x8, x8, 1 # 0<>
  addi x8, x8, -1

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-key?"
serial_qkey:  # ( -- ? ) Is there a key press ?
# -----------------------------------------------------------------------------
  push x1
  call pause

  pushdatos
  li  x8, USART2_BASE
  lw  x8, OFS_USART_STATR(x8)
  andi  x8, x8, RXNE

  sltiu x8, x8, 1 # 0<>
  addi x8, x8, -1

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "reset"
# -----------------------------------------------------------------------------

# The CH32V2x, CH32V3x and CH32X03x reset the system by setting the SYSRESET
# bit in the interrupt configuration register (PFIC_CFGR) to 1, or by setting
# the SYSRESET bit in the PFIC_SCTLR register to 1.
  .equ R32_PFIC_SCTLR, 0xE000ED10 # PFIC system control register
  li  x15, R32_PFIC_SCTLR
  li  x14, 0x80000000       # SYSRST
  sw  x14, 0(x15)

  # Real chip resets now; this jump is just to trap the emulator:
  j Reset
