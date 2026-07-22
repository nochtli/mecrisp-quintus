\ ch32vlx_led_blink_irq.fs
\ Tested with the following MCUs: CH32L103, CH32V203, CH32X035
\ 3.3V --- 1k --- LED --- PB0
\ 3.3V --- 1k --- LED --- PB1

require qingke/pfic.fs
require qingke/systick.fs
require ch32vl/rcc.fs
require ch32vl/gpiob.fs

: gpio-init
    $00000008 R32_RCC_APB2PCENR bis!  \ Enable IO port B clock
    $44444466 R32_GPIOB_CFGLR !       \ Open drain output on port pins PB0 & PB1
    $44444444 R32_GPIOB_CFGHR !       \ Floating input mode on all other pins
    $00000002 R32_GPIOB_OUTDR !       \ LED on PB0 on, LED on PB1 off
    ;

: led-toggle
    $00000003 R32_GPIOB_OUTDR xor!    \ Toggle port pins PB0 & PB1
    $00000000 R32_STK_SR !    	      \ Clear count value compare flag
    ;

: systick-init
    ['] led-toggle irq-systick !      \ Setup handler
    $0007A120 R32_STK_CMPLR !	      \ Set count comparison value
    $00000000 R32_STK_CMPHR !         \ Set count comparison value
    $0000000B R32_STK_CTLR !          \ Select clock source (HCLK/8),
                                      \ start timer and enable interrupt
    $00001000 R32_PFIC_IENR1 ! 	      \ Enable systick interrupt
    ;

: start gpio-init systick-init ;

\ start
