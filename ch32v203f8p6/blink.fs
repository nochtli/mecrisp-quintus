\ io 
$00000000 constant GPIO.CFGLR
$00000004 constant GPIO.CFGHR
$00000008 constant GPIO.INDR
$0000000C constant GPIO.OUTDR
$00000010 constant GPIO.BSHR
$00000014 constant GPIO.BCR
$00000018 constant GPIO.LCKR
$40010800 constant R32_GPIOA_CFGLR


: bit ( u -- u )  \ turn a bit position into a single-bit mask
  1 swap lshift 1-foldable ;

: io ( port# pin# -- pin )  \ combine port and pin into single int
  swap 8 lshift or 2-foldable ;
: io# ( pin -- u )  \ convert pin to bit position
  $0F and  1-foldable ;
: io-mask ( pin -- u )  \ convert pin to bit mask
  io# bit  1-foldable ;
: io-port ( pin -- u )  \ convert pin to port number (A=0, B=1, etc)
  8 rshift  1-foldable ;
: io-base ( pin -- addr )  \ convert pin to GPIO base address
  $F00 and 2 lshift R32_GPIOA_CFGLR + 1-foldable ;
: io@ ( pin -- f )  \ get pin value (true or false)
  dup io-base GPIO.INDR + h@ swap io# rshift 1 and 0<> ;
: ioc! ( pin -- )  \ clear pin to low
  dup io-mask swap io-base GPIO.BCR +  h! ;
: ios! ( pin -- )  \ set pin to high
  dup io-mask swap io-base GPIO.BSHR + h! ;
: io! ( f pin -- )  \ set pin value
  dup io-mask swap io-base GPIO.BSHR + ( f mask addr )
  rot 0= GPIO.BCR GPIO.BSHR - and + ( mask addr )
  h! ;

: iox! ( pin -- )  \ toggle pin
  dup io-base GPIO.OUTDR + >R ( pin r: addr )
  r@ h@ swap io-mask xor  ( x r: addr )
  R> h! ;

%0000 constant IMODE-ADC    \ input, analog
%0100 constant IMODE-FLOAT  \ input, floating
%1000 constant IMODE-PULL   \ input, pull-up/down

%10 constant OMODE-SLOW   \ add to OMODE-* for 2 MHz drive
%01 constant OMODE-MEDIUM \ add to OMODE-* for 10 MHz drive
%10 constant OMODE-FAST   \ add to OMODE-* for 50 MHz drive

\ with 2 MHz driver
%0000 OMODE-SLOW or constant OMODE-PP     \ output, push-pull
%0100 OMODE-SLOW or constant OMODE-OD     \ output, open drain
%1000 OMODE-SLOW or constant OMODE-AF-PP  \ alternate function, push-pull
%1100 OMODE-SLOW or constant OMODE-AF-OD  \ alternate function, open drain

: io-mode! ( mode pin -- )  \ set the CNF and MODE bits for a pin
  dup io-base GPIO.CFGLR + over 8 and shr + >r ( R: crl/crh )
  io# 7 and 4 * ( mode shift )
  $F over lshift not ( mode shift mask )
  r@ @ and -rot lshift or r> ! ;

: io-modes! ( mode pin mask -- )  \ shorthand to config multiple pins of a port
  16 0 do
    i bit over and if
      >r  2dup ( mode pin mode pin R: mask ) $F bic i or io-mode!  r>
    then
  loop 2drop drop ;

: io. ( pin -- )  \ display readable GPIO registers associated with a pin
  cr
  ." PIN " dup io#  dup .  10 < if space then
  ." PORT " dup io-port [char] A + emit
  io-base
  ." CFGLR = " GPIO.CFGLR over +  @ hex. cr
  ." CFGHR = " GPIO.CFGHR over +  @ hex. cr
  ." INDR  = " GPIO.INDR  over + h@ hex. cr
  ." OUTDR = " GPIO.OUTDR over + dup 2+ h@ 16 lshift swap h@ or hex. cr
  ." LCKR  = " GPIO.LCKR  over + @ hex. cr
  drop ;

\ systick
$E000F000 constant R32_STK_CTLR  \ System count control register 0x00000000 
$E000F004 constant R32_STK_SR    \ System count status register 0x00000000 
$E000F008 constant R32_STK_CNTL  \ System counter low register 0x00000000 
$E000F00C constant R32_STK_CNTH  \ System counter high register 0x00000000 
$E000F010 constant R32_STK_CMPLR \ Count/compare low register 0x00000000 
$E000F014 constant R32_STK_CMPHR \ Count/compare high register 0x00000000
$E000E100 constant PFIC_IENR_BASE \ Interrupt enable setting register 
$E000E180 constant PFIC_IRER_BASE \ Interrupt enable clear register

: us ( n -- ) \ dalay for n us 
  R32_STK_CNTL @ +
  begin dup R32_STK_CNTL @ u<= until
  drop ;

\ read 64 bit timer w/o stopping it. 
: systick2@ ( -- d ) \ 64 bit systick
  0 0
  begin  ( l h )
	2drop
	R32_STK_CNTH @
	R32_STK_CNTL @
	over
	R32_STK_CNTH @ \ is H changed ? if yes, read again
  = until
  swap \ return double ( L H )
;

: ms ( n -- ) \ delay n ms
  1000 um* ( d ) 
  systick2@ d+ ( d2 )
  begin 2dup systick2@ d> not until
  2drop
;

: systick-init ( -- )
  1 R32_STK_CTLR ! \ start systick at HCLK/8 for time base.
;

\ blink, the embedded version of the "hello world!" program.
\ Assumptions:
\ 	no external quartz is required, the MCU works on HSI (8MHz)
\ 	A LED is connected between PA4 and GND.

\ available pins in CH32V203F8P6
0  0 io constant PA0
0  1 io constant PA1
0  2 io constant PA2
0  3 io constant PA3
0  4 io constant PA4
0  5 io constant PA5
0  6 io constant PA6
0  7 io constant PA7
0  8 io constant PA8
0  9 io constant PA9
0 10 io constant PA10
1  0 io constant PB0
1 13 io constant PB13
1 14 io constant PB14
1 15 io constant PB15

: blink10 ( -- )
  10 0 do 
	PA4 ioc! 90 ms
	PA4 ios! 10 ms
  loop 
;

: main ( -- )
  systick-init
  OMODE-PP PA4 io-mode!    

  begin 
   blink10 500 ms
  key?  until 
  PA4 ioc!
;
main

