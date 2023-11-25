HEX
: NEWQUIT
    [COMPILE] [                  ( set forth to interpret )
    BEGIN
        RP!
        .S
        CR
        QUERY
        INTERPRET
        STATE @ 0=
        IF                      ( if forth is interpretting )
            ." ok"
            4B00 E0 DUMP        ( dump some memory space of interest )
        THEN
    AGAIN
;

( clear the old USER variable area )
: CLR
    4BE0 4B00
    DO
        0 I C!
    LOOP
;

( this is the standard QUIT word )
: QUIT
    0 BLK 0
    [COMPILE] [                 ( set forth to interpret )
    BEGIN
        RP!
        .S
        CR
        QUERY
        INTERPRET
        STATE @ 0=
        IF                      ( if forth is interpreting )
            ." ok"
        THEN
    AGAIN
;
