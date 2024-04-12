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

.include "../common/terminalhooks.s"
.include "cycles.s"

# -----------------------------------------------------------------------------
# Labels for a few hardware ports
# -----------------------------------------------------------------------------

# Baud generator calculations
.equ SYSF, 100000000
.equ BAUD, 115200
.equ BAUD_DIV, (SYSF / (BAUD * 16) )

.equ UART0_BASE_ADDR, 0x10000100

.equ UART_REG_DR,        0x00   # UART Data register
.equ UART_REG_IE,        0x04   # UART Interrupt enable register
.equ UART_REG_IIR_FCR,   0x08   # UART Interrupt identification(Read only), FIFO control register(write only).
.equ UART_REG_LCR,       0x0C   # UART Line control register
.equ UART_REG_LSR,       0x14   # UART Line status register

.equ UART_REG_DIVLSB,	 0x00	# UART baud generator LSB(yte) when LCR bit 7 is 1
.equ UART_REG_DIVMSB,	 0x04	# UART baud generator MSB(yte) when LCR bit 7 is 1


.equ UART_LSR_DR,        (1)      # Data Ready
.equ UART_LSR_THRE,      (1 << 5) # Transmitter Holding Register
.equ UART_LSR_TEMT,      (1 << 6) # Transmitter Empty

# -----------------------------------------------------------------------------
uart_init:
# -----------------------------------------------------------------------------
  push x5
  push x6

  #setup the UART config
  LI x5,UART0_BASE_ADDR
  LI x6,0x03
  SW x6,UART_REG_LCR(x5) # LCR <= 0x03, set to 8 bit mode, DIV registers inaccessible
  SW x0,UART_REG_IE(x5)  # IE <= 0
  LI x6,0x83
  SW x6,UART_REG_LCR(x5) # LCR <= 0x83, set bit 7 to access DIV registers

  #setup the baud rate
  LI x6,BAUD_DIV
  ANDI x6,x6,0xFF
  SW x6,UART_REG_DIVLSB(x5)

  LI x6,BAUD_DIV
  SRLI x6,x6,8
  ANDI x6,x6,0xFF
  SW x6,UART_REG_DIVMSB(x5)

  LI x6,0x03
  SW x6,UART_REG_LCR(x5) # LCR <= 0x03, set to 8 bit mode, DIV registers inaccessible
  #done setup

  pop x6
  pop x5

  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-emit"
serial_emit: # ( c -- ) Emit one character
# -----------------------------------------------------------------------------
  push x1

1:call serial_qemit
  popda x15
  beq x15, zero, 1b

  li x14, UART0_BASE_ADDR
  sw x8,  UART_REG_DR(x14)
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
  li x14, UART0_BASE_ADDR
  lw x8,  UART_REG_DR(x14)
  andi x8, x8, 0xFF

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-emit?"
serial_qemit:  # ( -- ? ) Ready to send a character ?
# -----------------------------------------------------------------------------
  push x1
  call pause

  pushdatos
  li x8, UART0_BASE_ADDR
  lw x8, UART_REG_LSR(x8)
  andi x8, x8, UART_LSR_TEMT
  #andi x8, x8, 0x60

  sltiu x8, x8, 1 # 0<>
  addi x8, x8, -1

  # sltiu x8, x8, 1 # 0=
  # sub x8, zero, x8

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "serial-key?"
serial_qkey:  # ( -- ? ) Is there a key press ?
# -----------------------------------------------------------------------------
  push x1
  call pause

  pushdatos
  li x8, UART0_BASE_ADDR
  lw x8, UART_REG_LSR(x8)
  andi x8, x8, UART_LSR_DR

  sltiu x8, x8, 1 # 0<>
  addi x8, x8, -1

  # sltiu x8, x8, 1 # 0=
  # sub x8, zero, x8

  pop x1
  ret

# -----------------------------------------------------------------------------
  Definition Flag_visible, "reset"
# -----------------------------------------------------------------------------
  csrrci zero, mstatus, 8 # Clear Machine Interrupt Enable Bit
  j Reset
