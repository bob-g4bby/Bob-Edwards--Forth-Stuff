\ Memory dump displays data in longs ver 1 - Bob Edwards Oct 2025

hex
forth
forth definitions

\ part of dumpl - display n as an eight digit unsigned number
: long. ( n -- )
    <# # # # # # # # # #> type
;

\ displays memory contests in hex starting from addr, for n longs
: dumpl     ( addr n -- )
    base @ -rot hex         ( base addr n )     \ save number base and set hex display
    8 -rot                  ( base 8 addr n )   \ count per display line 
    over + swap             ( base 8 endaddr startaddr )
    do                      ( base dispcount )
        dup 8 = if
            cr i long. ." :  "  \ start a new line with an address display
        then
        i @ long. space     \ display data stored at i memory address
        1-                  ( base dispcount ) \ increment data/line count
        dup 0= if
            drop 8          \ reset the dispcount
        then
    loop
    drop
    base !                  \ restore number base
    cr
;
