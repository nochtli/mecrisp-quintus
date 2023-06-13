$E000F000 constant R32_STK_CTLR  \ System count control register 0x00000000 
$E000F004 constant R32_STK_SR    \ System count status register 0x00000000 
$E000F008 constant R32_STK_CNTL  \ System counter low register 0x00000000 
$E000F00C constant R32_STK_CNTH  \ System counter high register 0x00000000 
$E000F010 constant R32_STK_CMPLR \ Count/compare low register 0x00000000 
$E000F014 constant R32_STK_CMPHR \ Count/compare high register 0x00000000
$E000E100 constant PFIC_IENR_BASE \ Interrupt enable setting register 
$E000E180 constant PFIC_IRER_BASE \ Interrupt enable clear register


$1000 PFIC_IENR_BASE !

$e000e000 @ hex.

0 variable stck

: incstck
  stck @ 1+ stck !
  \ ." inrtp " stck @ . cr
  0 R32_STK_SR !
;

: systick-init
  ['] incstck irq-systick !
  8000 0 swap R32_STK_CMPLR 2!
  15 R32_STK_CTLR !
  1 2 lshift R32_STK_CTLR @ or R32_STK_CTLR  !
;

: sys.
  cr
  ." eint = " eint? . cr
  ." R32_STK_CMPLR L " R32_STK_CMPLR @ hex. cr
  ." R32_STK_CMPLR H " R32_STK_CMPLR 4 + @ hex. cr
  ." R32_STK_CTLR " R32_STK_CTLR @ hex. cr
  ." R32_STK_CNTL " R32_STK_CNTL 2@ swap hex. hex.
  ." R32_STK_CNTL " R32_STK_CNTL 2@ swap hex. hex.
  ." stck: " stck @ . stck @ . stck @ . stck @ . stck @ . stck @ . stck @ . cr
;
systick-init
sys.
