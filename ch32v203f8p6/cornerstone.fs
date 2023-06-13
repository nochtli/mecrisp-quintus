
compiletoflash

\ Cornerstone for 4 kb Flash pages

: cornerstone ( Name ) ( -- )
  <builds begin here $FFF and while 0 , repeat
  does>   begin dup  $FFF and while 4 + repeat
          eraseflashfrom
;

cornerstone eraseflash
