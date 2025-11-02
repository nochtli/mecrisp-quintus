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

# Note: After erasing is successful, word read - 0xe339e339, half word read - 0xe339, even address byte read - 0x39, odd address read 0xe3.

.equ erasedflashspecial, 1

.equ erasedbyte,     0x39
.equ erasedhalfword, 0xe339
.equ erasedword,     0xe339e339

.equ writtenhalfword, 0
.equ writtenword, 0

# -----------------------------------------------------------------------------
# Speicherkarte für Flash und RAM
# Memory map for Flash and RAM
# -----------------------------------------------------------------------------

# Konstanten für die Größe des Ram-Speichers

.equ RamAnfang,  0x20000000  # Start of RAM           Porting: Change this !
.equ RamEnde,    0x20010000  # End   of RAM.   64 kb. Porting: Change this !

# Konstanten für die Größe und Aufteilung des Flash-Speichers

.equ FlashAnfang, 0x00000000 # Start of Flash           Porting: Change this !
.equ FlashEnde,   0x00040000 # End   of Flash.  256 kb. Porting: Change this !

.equ FlashDictionaryAnfang, FlashAnfang + 0x5000 # 20 kb reserved for core.
.equ FlashDictionaryEnde,   FlashEnde

# -----------------------------------------------------------------------------
# Core start
# -----------------------------------------------------------------------------

.text
    .align  4
  j Reset
# Exceptions and interrupts come here before the "Vector table of interrupt and
# exception" is proper initialized.
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
    .word   irq_collection             /* 18 - TAMPER */
    .word   irq_collection             /* 19 - RTC */
    .word   irq_collection             /* 20 - FLASH */
    .word   irq_collection             /* 21 - RCC */
    .word   irq_exti0                  /* 22 - EXTI0 */
    .word   irq_exti1                  /* 23 - EXTI1 */
    .word   irq_exti2                  /* 24 - EXTI2 */
    .word   irq_exti3                  /* 25 - EXTI3 */
    .word   irq_exti4                  /* 26 - EXTI4 */
    .word   irq_collection             /* 27 - DMA1_CH1 */
    .word   irq_collection             /* 28 - DMA1_CH2 */
    .word   irq_collection             /* 29 - DMA1_CH3 */
    .word   irq_collection             /* 30 - DMA1_CH4 */
    .word   irq_collection             /* 31 - DMA1_CH5 */
    .word   irq_collection             /* 32 - DMA1_CH6 */
    .word   irq_collection             /* 33 - DMA1_CH7 */
    .word   irq_adc                    /* 34 - ADC1_2 */
    .word   irq_collection             /* 35 - USB_HP or CAN1_TX */
    .word   irq_collection             /* 36 - USB_LP or CAN1_RX0 */
    .word   irq_collection             /* 37 - CAN1_RX1 */
    .word   irq_collection             /* 38 - CAN1_SCE */
    .word   irq_collection             /* 39 - EXTI9_5 */
    .word   irq_collection             /* 40 - TIM1_BRK */
    .word   irq_collection             /* 41 - TIM1_UP */
    .word   irq_collection             /* 42 - TIM1_TRG_COM */
    .word   irq_collection             /* 43 - TIM1_CC */
    .word   irq_collection             /* 44 - TIM2 */
    .word   irq_collection             /* 45 - TIM3 */
    .word   irq_collection             /* 46 - TIM4 */
    .word   irq_collection             /* 47 - I2C1_EV */
    .word   irq_collection             /* 48 - I2C1_ER */
    .word   irq_collection             /* 49 - I2C2_EV */
    .word   irq_collection             /* 50 - I2C2_ER */
    .word   irq_collection             /* 51 - SPI1 */
    .word   irq_collection             /* 52 - SPI2 */
    .word   irq_collection             /* 53 - USART1 */
    .word   irq_collection             /* 54 - USART2 */
    .word   irq_collection             /* 55 - USART3 */
    .word   irq_collection             /* 56 - EXTI15_10 */
    .word   irq_collection             /* 57 - RTCAlarm */
    .word   irq_collection             /* 58 - USBWakeUp */
    .word   irq_collection             /* 59 - TIM8_BRK */
    .word   irq_collection             /* 60 - TIM8_UP */
    .word   irq_collection             /* 61 - TIM8_TRG_COM */
    .word   irq_collection             /* 62 - TIM8_CC */
    .word   irq_collection             /* 63 - RNG */
    .word   0
    .word   irq_collection             /* 65 - SDIO */
    .word   irq_collection             /* 66 - TIM5 */
    .word   irq_collection             /* 67 - SPI3 */
    .word   irq_collection             /* 68 - USART4 */
    .word   irq_collection             /* 69 - USART5 */
    .word   irq_collection             /* 70 - TIM6 */
    .word   irq_collection             /* 71 - TIM7 */
    .word   irq_collection             /* 72 - DMA2_CH1 */
    .word   irq_collection             /* 73 - DMA2_CH2 */
    .word   irq_collection             /* 74 - DMA2_CH3 */
    .word   irq_collection             /* 75 - DMA2_CH4 */
    .word   irq_collection             /* 76 - DMA2_CH5 */
    .word   irq_collection             /* 77 - ETH */
    .word   irq_collection             /* 78 - ETH_WKUP */
    .word   irq_collection             /* 79 - CAN2_TX */
    .word   irq_collection             /* 80 - CAN2_RX0 */
    .word   irq_collection             /* 81 - CAN2_RX1 */
    .word   irq_collection             /* 82 - CAN2_SCE */
    .word   irq_collection             /* 83 - OTG_FS */
    .word   irq_collection             /* 84 - USBHSWakeUp */
    .word   irq_collection             /* 85 - USBHS */
    .word   irq_collection             /* 86 - DVP */
    .word   irq_collection             /* 87 - USART6 */
    .word   irq_collection             /* 88 - USART7 */
    .word   irq_collection             /* 89 - USART8 */
    .word   irq_collection             /* 90 - TIM9_BRK */
    .word   irq_collection             /* 91 - TIM9_UP */
    .word   irq_collection             /* 92 - TIM9_TRG_COM */
    .word   irq_collection             /* 93 - TIM9_CC */
    .word   irq_collection             /* 94 - TIM10_BRK */
    .word   irq_collection             /* 95 - TIM10_UP */
    .word   irq_collection             /* 96 - TIM10_TRG_COM */
    .word   irq_collection             /* 97 - TIM10_CC */
    .word   irq_collection             /* 98 - DMA2_CH6 */
    .word   irq_collection             /* 99 - DMA2_CH7 */
    .word   irq_collection             /* 100 - DMA2_CH8 */
    .word   irq_collection             /* 101 - DMA2_CH9 */
    .word   irq_collection             /* 102 - DMA2_CH10 */
    .word   irq_collection             /* 103 - DMA2_CH11 */

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

#  SystemInit
   #   RCC->CTLR |= (uint32_t)0x00000001;
  li  x15,0x40021000
  lw  x14,0(x15)
  ori x14,x14,1
  sw  x14,0(x15)
   #   RCC->CFGR0 &= (uint32_t)0xF8FF0000;
  lw  x14,4(x15)
  li  x13,0xF8FF0000
  and x14,x14,x13
  sw  x14,4(x15)
   #   RCC->CTLR &= (uint32_t)0xFEF6FFFF;
  lw  x14,0(x15)
  li  x13,0xFEF6FFFF
  and x14,x14,x13
  sw  x14,0(x15)
   #   RCC->CTLR &= (uint32_t)0xFFFBFFFF;
  lw  x14,0(x15)
  li  x13,0xFFFBFFFF
  and x14,x14,x13
  sw  x14,0(x15)
   #   RCC->CFGR0 &= (uint32_t)0xFF80FFFF;
  lw  x14,4(x15)
  li  x13,0xFF80FFFF
  and x14,x14,x13
  sw  x14,4(x15)
   #   RCC->INTR = 0x009F0000;
  li  x14,0x009F0000
  sw  x14,8(x15)
   #   SetSysClock();
  nop # the HSI is used as System clock

  # Initialisations for terminal hardware, without stacks
  call uart_init

  # Catch the pointers for Flash dictionary
  .include "../common/catchflashpointers.s"

  welcome " for RISC-V RV32IMACF on CH32V307VCT6 by Matthias Koch"

  # Ready to fly !
  .include "../common/boot.s"
