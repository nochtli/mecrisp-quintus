\ hex output
\ adapted from mecrisp 2.0.2 (GPL3)


: u.4 ( u -- ) 0 <# # # # # #> type ;
: u.2 ( u -- ) 0 <# # # #> type ;

: h.4 ( u -- ) base @ hex swap  u.4  base ! ;
: h.2 ( u -- ) base @ hex swap  u.2  base ! ;

$E339 constant hex.empty  \ needs to be variable, some flash is zero when empty

: hexdump ( -- ) \ dumps entire flash as Intel hex
  cr
  $10000 $0000  \ Complete image with Dictionary
  do
    \ Check if this line is entirely empty:
    0                 \ Not worthy to print
    i #16 + i do      \ Scan data
      i h@ hex.empty <> or  \ Set flag if there is a non-empty byte
    2 +loop

    if
      ." :10" i h.4 ." 00"  \ Write record-intro with 4 digits.
      $10           \ Begin checksum
      i          +  \ Sum the address bytes
      i 8 rshift +  \ separately into the checksum

      i #16 + i do
        i c@ h.2  \ Print data with 2 digits
        i c@ +    \ Sum it up for Checksum
      loop

      negate h.2  \ Write Checksum
      cr
    then

  #16 +loop
  ." :00000001FF" cr
;

