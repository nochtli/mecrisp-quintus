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

# -----------------------------------------------------------------------------
# Swiches for capabilities of this chip
# -----------------------------------------------------------------------------
.option arch, +zicsr

.option norelax
.option rvc
.equ compressed_isa, 1

# -----------------------------------------------------------------------------
# Speicherkarte für Flash und RAM
# Memory map for Flash and RAM
# -----------------------------------------------------------------------------

# Konstanten für die Größe des Ram-Speichers

.equ RamAnfang,  0x20000000  # Start of RAM           Porting: Change this !
.equ RamEnde,    0x20005000  # End   of RAM.   20 kb. Porting: Change this !

# Konstanten für die Größe und Aufteilung des Flash-Speichers

.equ FlashAnfang, 0x00000000 # Start of Flash           Porting: Change this !
.equ FlashEnde,   0x0000F800 # End   of Flash.   62 kb. Porting: Change this !

.equ FlashDictionaryAnfang, FlashAnfang + 0x5000 # 20 kb reserved for core.
.equ FlashDictionaryEnde,   FlashEnde

# -----------------------------------------------------------------------------
# Core start
# -----------------------------------------------------------------------------

    .text
    .align  4
    j Reset
    # Exceptions and interrupts come here before the
    # "Vector table of interrupt and exception" is proper initialized.
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    .word     0x00000013    # nop
    j Reset
# -----------------------------------------------------------------------------
# Vector table
# -----------------------------------------------------------------------------
    .align  4
_vector_base: # Aligned on 4 Byte boundary.
    .option push
    .option norvc;
    .word   Reset
    .word   0
    .word   irq_collection             /* 2 - NMI */
    .word   irq_fault                  /* 3 - HardFault */
    .word   0
    .word   irq_collection             /* 5 - Ecall-M */
    .word   0
    .word   0
    .word   irq_collection             /* 8 - Ecall-U */
    .word   irq_collection             /* 9 - BreakPoint */
    .word   0
    .word   0
    .word   irq_systick                /* 12 - SysTick */
    .word   0
    .word   irq_software               /* 14 - SW */
    .word   0
    /* External Interrupts */
    .word   irq_collection             /* 16 - WWDG */
    .word   irq_collection             /* 17 - PVD */
    .word   irq_collection             /* 18 - FLASH */
    .word   0
    .word   irq_exti7_0                /* 20 - EXTI7_0 */
    .word   irq_collection             /* 21 - AWU */
    .word   irq_collection             /* 22 - DMA1_CH1 */
    .word   irq_collection             /* 23 - DMA1_CH2 */
    .word   irq_collection             /* 24 - DMA1_CH3 */
    .word   irq_collection             /* 25 - DMA1_CH4 */
    .word   irq_collection             /* 26 - DMA1_CH5 */
    .word   irq_collection             /* 27 - DMA1_CH6 */
    .word   irq_collection             /* 28 - DMA1_CH7 */
    .word   irq_adc1                   /* 29 - ADC1 */
    .word   irq_collection             /* 30 - I2C1_EV */
    .word   irq_collection             /* 31 - I2C1_ER */
    .word   irq_collection             /* 32 - USART1 */
    .word   irq_collection             /* 33 - SPI1 */
    .word   irq_collection             /* 34 - TIM1BRK */
    .word   irq_collection             /* 35 - TIM1UP */
    .word   irq_collection             /* 36 - TIM1TRG */
    .word   irq_collection             /* 37 - TIM1CC */
    .word   irq_collection             /* 38 - TIM2UP */
    .word   irq_collection             /* 39 - USART2 */
    .word   irq_collection             /* 40 - EXTI15_8 */
    .word   irq_collection             /* 41 - EXTI25_16 */
    .word   irq_collection             /* 42 - USART3 */
    .word   irq_collection             /* 43 - USART4 */
    .word   irq_collection             /* 44 - DMA1_CH8 */
    .word   irq_collection             /* 45 - USBFS */
    .word   irq_collection             /* 46 - USBFS_WKUP */
    .word   irq_pioc                   /* 47 - PIOC */
    .word   irq_opa                    /* 48 - OPA */
    .word   irq_collection             /* 49 - USBPD */
    .word   irq_collection             /* 50 - USBPD_WKUP */
    .word   irq_collection             /* 51 - TIM2CC */
    .word   irq_collection             /* 52 - TIM2TRG */
    .word   irq_collection             /* 53 - TIM2BRK */
    .word   irq_collection             /* 54 - TIM3 */
    .option pop

# -----------------------------------------------------------------------------
# Include the Forth core of Mecrisp-Quintus
# -----------------------------------------------------------------------------

  .include "../common/forth-core.s"

# -----------------------------------------------------------------------------
Reset: # Forth begins here
# -----------------------------------------------------------------------------

# Microprocessor configuration registers (corecfgr)
# This register is mainly used to configure the microprocessor pipeline, instruction prediction and other related
# features, and generally does not need to be operated. The relevant MCU products are configured with default
# values in the startup file.

  li x15, 0x1f
  csrw 0xbc0, x15 # corecfgr

  # Enable nested and hardware stack
# PMTCFG:  0b00: No nesting, the number of preemption bits is 0.
# INESTEN: Interrupt nesting function enabled
# HWSTKEN: HPE function enabled;
  li x15, 0x3
  csrw 0x804, x15 # INTSYSCR ;

  la x15, _vector_base
  ori x15, x15, 3
  csrw mtvec, x15

  # Enable interrupt
  li x15, 0x88 + (3<<11)
  csrs mstatus, x15

# After reset, the high-speed internal oscillator (48 MHz) is enabled,
# and the HB clock source prescaler is set to divide by 6, resulting
# in an HB bus peripheral clock (HCLK) of 8 MHz. There is no need to
# reconfigure anything.

  # Initialisations for flash controller
  # call flash_init
	
  # Initialisations for terminal hardware, without stacks
  call uart_init

  # Catch the pointers for Flash dictionary
  .include "../common/catchflashpointers.s"

  welcome " for RISC-V RV32IMAC on CH32X035 by Matthias Koch"

  # Ready to fly !
  .include "../common/boot.s"
