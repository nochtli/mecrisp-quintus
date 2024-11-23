#
#    Mecrisp-Quintus - A native code Forth implementation for RISC-V
#    Copyright (C) 2018  Matthias Koch
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

    .equ    R32_USART1_STATR,     0x40013800    # UASRT1 status register 0x000000C0
    .equ    R32_USART1_DATAR,     0x40013804    # UASRT1 data register 0x000000XX
    .equ    R32_USART1_BRR,       0x40013808    # UASRT1 baud rate register 0x00000000
    .equ    R32_USART1_CTLR1,     0x4001380C    # UASRT1 control register1 0x00000000
    .equ    R32_USART1_CTLR2,     0x40013810    # UASRT1 control register2 0x00000000
    .equ    R32_USART1_CTLR3,     0x40013814    # UASRT1 control register3 0x00000000
    .equ    R32_USART1_GPR,       0x40013818    # UASRT1 guard time and prescaler register 0x00000000

    .equ    R32_RCC_CTLR,         0x40021000    # Clock control register                 0x0000xx83
    .equ    R32_RCC_CFGR0,        0x40021004    # Clock configuration register 0         0x00000000
    .equ    R32_RCC_INTR,         0x40021008    # Clock interrupt register               0x00000000
    .equ    R32_RCC_PB2PRSTR,     0x4002100C    # PB2 peripheral reset register          0x00000000
    .equ    R32_RCC_PB1PRSTR,     0x40021010    # PB1 peripheral reset register          0x00000000
    .equ    R32_RCC_HBPCENR,      0x40021014    # HB peripheral clock enable register    0x00000014
    .equ    R32_RCC_PB2PCENR,     0x40021018    # PB2 peripheral clock enable register   0x00000000
    .equ    R32_RCC_PB1PCENR,     0x4002101C    # PB1 peripheral clock enable register   0x00000000
    .equ    R32_RCC_BDCTLR,       0x40021020    # Backup domain control register         0x00000000
    .equ    R32_RCC_RSTSCKR,      0x40021024    # Control/status register                0x0C000000
    .equ    R32_RCC_HBRSTR,       0x40021028    # HB peripheral reset register           0x00000000

    .equ    R32_HSE_CAL_CTRL,     0x4002202C    # HSE crystal oscillator calibration control register          0x09000000
    .equ    R16_LSI32K_TUNE,      0x40022036    # LSI crystal oscillator calibration tune register             0x1011
    .equ    R8_LSI32K_CAL_CFG,    0x40022049    # LSI crystal oscillator calibration configuration register    0x01
    .equ    R16_LSI32K_CAL_STATR, 0x4002204C    # LSI crystal oscillator calibration status register           0x0000
    .equ    R8_LSI32K_CAL_OV_CNT, 0x4002204E    # LSI crystal oscillator calibration counter                   0x00
    .equ    R8_LSI32K_CAL_CTRL,   0x4002204F    # LSI crystal oscillator calibration control register          0x80

    .equ    R32_GPIOA_CFGLR,      0x40010800    # PA port configuration register low     0x44444444
    .equ    R32_GPIOA_CFGHR,      0x40010804    # PA port configuration register high    0x44444444
    .equ    R32_GPIOA_INDR,       0x40010808    # PA port input data register            0x0000XXXX
    .equ    R32_GPIOA_OUTDR,      0x4001080C    # PA port output data register           0x00000000
    .equ    R32_GPIOA_BSHR,       0x40010810    # PA port set/reset register             0x00000000
    .equ    R32_GPIOA_BCR,        0x40010814    # PA port reset register                 0x00000000
    .equ    R32_GPIOA_LCKR,       0x40010818    # PA port configuration lock register    0x00000000

    .equ    _RCC_PB2Periph_GPIOA,     (0x00000004)
    .equ    _RCC_PB2Periph_USART1,    (0x00004000)
    .equ    _GPIOA_BASE,              (_PB2PERIPH_BASE + 0x0800)
    .equ    _PB2PERIPH_BASE,          (_PERIPH_BASE + 0x10000)
    .equ    _PERIPH_BASE,             (0x40000000) # /* Peripheral base address in the alias region */
    .equ    _GPIO_Pin_9,              (0x0200) # /* Pin 9 selected */
    .equ    _GPIO_Pin_10,             (0x0400) # /* Pin 10 selected */

    .equ    OFFSET_STATR, 0x00
    .equ    OFFSET_DATAR, 0x04
    .equ    OFFSET_BRR,   0x08
    .equ    OFFSET_CTLR1, 0x0C
    .equ    OFFSET_CTLR2, 0x10
    .equ    OFFSET_CTLR3, 0x14
    .equ    OFFSET_GPR,   0x18

    .equ    RXNE, 1<<5
    .equ    TXNE, 1<<7

# -----------------------------------------------------------------------------
uart_init:
# -----------------------------------------------------------------------------

# HSION is on ..
# R32_RCC_PB2PCENR = RCC_PB2Periph_USART1 | RCC_PB2Periph_GPIOA
# R32_GPIOA_CFGHR =
# pa9 == Tx, pa10 = Rx
# MODE10 = 3, MODE9=3
# CNF10 = 2, CNF9 = 2
# power on uart and pa
  li  x15, R32_RCC_PB2PCENR
  li  x14, 0x4004  #_RCC_PB2Periph_USART1 + _RCC_PB2Periph_GPIOA
  sw  x14, 0(x15)
# pa9/10 init
  lui x14, (3<<9)
  li  x15, R32_GPIOA_BSHR
  sh  x14, 0(x15)
  li  x14, 0x48844fb4
  li  x15, R32_GPIOA_CFGHR
  sw  x14, 0(x15)
  li  x15, R32_USART1_STATR
# 115200 bps at 8Mhz HSI
  li  x14, 69
  sw  x14, OFFSET_BRR(x15)
  li  x14, 0b1100
  sw  x14, OFFSET_CTLR1(x15)
  li  x14, 1<<12   # one stop bit
  sw  x14, OFFSET_CTLR2(x15)
  lw  x14, OFFSET_CTLR1(x15)
  li  x15, 1<<13
  or  x14, x14,x15
  li  x15, R32_USART1_STATR
  sw  x14, OFFSET_CTLR1(x15)

  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-emit"
serial_emit: # ( c -- ) Emit one character
# -----------------------------------------------------------------------------
  push x1

1:call serial_qemit
  popda x15
  beq x15, zero, 1b

  li  x15, R32_USART1_STATR
  sb  x8, OFFSET_DATAR(x15)
  drop

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-key"
serial_key: # ( -- c ) Receive one character
# -----------------------------------------------------------------------------
  push x1

1:call serial_qkey
  popda x15
  beq x15, zero, 1b

  pushdatos
  li  x8, R32_USART1_STATR
  lb  x8, OFFSET_DATAR(x8)

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-emit?"
serial_qemit:  # ( -- ? ) Ready to send a character ?
# -----------------------------------------------------------------------------
  push x1
  call pause

  pushdatos
  li  x8, R32_USART1_STATR
  lw  x8, OFFSET_STATR(x8)
  andi  x8, x8, TXNE

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
  li  x8, R32_USART1_STATR
  lw  x8, OFFSET_STATR(x8)
  andi  x8, x8, RXNE

  sltiu x8, x8, 1 # 0<>
  addi x8, x8, -1

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "reset"
# -----------------------------------------------------------------------------

# The CH32V2x and CH32V3x reset the system by setting the SYSRESET bit in the
# interrupt configuration register (PFIC_CFGR) to 1, or by setting the SYSRESET
# bit in the PFIC_SCTLR register to 1.
    .equ R32_PFIC_SCTLR, 0xE000ED10 # PFIC system control register
  li  x15, R32_PFIC_SCTLR
  li  x14, 0x80000000       # SYSRST
  sw  x14, 0(x15)

  # Real chip resets now; this jump is just to trap the emulator:
  j Reset
