( Hex Dump word for Nasforth )

DECIMAL

( .BYTE is an internal component of DUMP )
: .BYTE                     ( n -- )
    DUP 15 >
    IF
        .
    ELSE
        0 1 .R .
    THEN
;

( .ASCII is an internal component of DUMP )
: .ASCII                    ( n -- )
    DUP 31 > OVER 127 < AND OVER 127 > OR
    IF
        EMIT
    ELSE
        ." ." DROP
    THEN
;

( Display an area of memory as hex, starting at adr )
( for at least n bytes )
: DUMP      ( adr n -- )
    BASE @ >R HEX CR
    BEGIN
        OVER U.                  ( print the memory address )
        8 0 DO                   ( 16 bytes per line )
            OVER I + C@ .BYTE    ( print the memory contents )
        LOOP
        8 0 DO
            OVER I + C@ .ASCII   ( if printable, ASCII letter )
        LOOP
        >R 8 + R> 8 -
        CR
    DUP 0= OVER 0< OR
    UNTIL
    DROP DROP
    R> BASE !
;

