\ emits half byte in hexadecimal
: hhout ( n -- )
  15 and
  dup 9 > if 55 else 48 then \ offset of '0' or 'A'
  + emit ;
\ emits a byte in hexadecimal followed by space
: hexout ( n -- )
  dup 4 rshift
  hhout hhout
  space ;
\ dumps 16 bytes in hexadecimal format
: dump16 ( addr -- addr )
  16 0 do
    \ put separator on the middle of the row
    i 8 = if [char] - emit space then
    dup i + c@ hexout
  loop ;
\ emits character if it is printable, otherwise emit a dot
: cprnt ( c -- )
  dup bl < if
    drop [char] .
  else
    dup $7f > if drop [char] . then
  then emit ;
\ dump row of 16 characters
: dump16a ( addr -- addr )
  16 0 do
    dup i + c@ cprnt
  loop ;
\ print the address in the hexadecimal format followed by space
: dumpaddr ( addr -- addr )
  4 0 do
    3 i - 8 * over swap rshift dup 4 rshift hhout hhout
  loop
  space ;
\ show the memory in hexadecimal form and as characters as well
: dump ( addr len -- )
  cr 15 + 16 / 0 do
    dumpaddr ." - " dump16 2 spaces dump16a cr
  16 + loop
  drop ;
