( driver for OKI MSM5832 clock chip - Bob Edwards 1982, 2023 )
( Version 2 - fixes bug with months register )
( Months are counted as 1-12. I had assumed they would be 0-11, which is wrong )
( clock is connected to the standard pio on a nascom )
( N.B. this is set as a 24 hr clock )

FORTH DEFINITIONS
HEX

80 CONSTANT HOLDCLOCK
40 HOLDCLOCK + CONSTANT READ
10 CONSTANT 30ADJ
20 CONSTANT WRITE
0C29 CONSTANT CURSOR

DECIMAL

( Move cursor to x,y on screen, 0,0 being top left of the screen )
: ATXY                        ( x y -- )
    DUP 47 U<
    IF 
        SWAP DUP 14 U<
        IF
            64 * + 2058 + CURSOR !
        ELSE
            DROP DROP
        THEN
    THEN ;
   
HEX    

( Clear the screen )
: CLEARSCREEN                   ( -- )
0C EMIT
;

( read 4 ls bits from port 4 )
: REGREAD 0F 4 P@ AND ;         ( -- n )        

( Do nothing for n time periods )
: MS 10 * 0 DO LOOP ;           ( n -- )

( n=0, Initialise PIO for writing to the clock )
( n=1, initialise PIO for reading from the clock )
: INITPIO                       ( n -- )
    0 4 P! 
    0 5 P!
    0FF 6 P!
    IF
        0F 6 P!
    ELSE
        0 6 P!
    THEN
    0F 7 P! ;

: SETHOLD HOLDCLOCK 4 P! 10 MS ;

: READCLOCK                      ( -- year month day weekday hr min sec )
    1 INITPIO                    ( 4 bit i/p from clock )
    SETHOLD                      ( stop clock count )
    READ 4 P!                    ( set clock to read )
    -1 0C DO                     ( this loop produces C A 8 7 5 3 1 )
        I 5 P!                   ( set register addr reqd )
        5 MS
        REGREAD
        I 5 = I 8 = OR           ( mask off 2 MS bits for these bytes )
        IF
            3 AND
        THEN
        I 6 = 
        IF
                R> 1+ >R         ( adjust the loop count because of weekday )
        ELSE
                I 1 - 5 P! REGREAD ( read ls digit )
                SWAP 0A * +       ( form whole value )
        THEN
    -2 +LOOP
    0 4 P! ;                      ( drop read & hold )

: CASE <BUILDS SMUDGE ] DOES> SWAP 2 * + @ EXECUTE ;

: MON ." Mon" ; : TUES ." Tues" ; : WED ." Wednes" ;
: THURS ." Thurs" ; : FRI ." Fri" ; : SAT ." Satur" ;
: SUN ." Sun" ;
CASE DAY SUN MON TUES WED THURS FRI SAT ;
: DAY. DAY ." day" ;

: JAN ." January" ; : FEB ." February" ; : MAR ." March" ;
: APR ." April" ; : MAY ." May" ; : JUN ." June" ;
: JUL ." July" ; : AUG ." August" ; : SEP ." September" ;
: OCT ." October" ; : NOV ." November" ; : DEC ." December" ;
CASE MONTH. 0 JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC ;

HEX

0 VARIABLE SECS

: REGWRITE 0F AND HOLDCLOCK + DUP DUP 4 P! WRITE + 4 P! 4 P! ;

( Set the clock )
( 23 1 27 0 14 32 0 WRITECLOCK = 27th January 2023 Sunday 2:32:00 pm )
: WRITECLOCK                    ( year month day weekday hr min sec -- )
                                ( N.B. weekday 0-6 , month 1 - 12 )
    0 INITPIO                   ( set for 4 bits o/p )
    SETHOLD
    0D 0 DO
        0A /MOD
        I 6 = 
        IF
            DROP I 5 P! REGWRITE
            R> 1 - >R
        ELSE
            I 4 = IF
                8 OR           ( SET CLOCK FOR 24 HR WORKING )
            THEN
            I 1+ 5 P! REGWRITE
            I 5 P! REGWRITE
        THEN
    2 +LOOP
    0 4 P! ;

DECIMAL

( display the time and date )
: TIME.                         ( year month day weekday hr min sec -- )
    >R >R 2 .R ."  Hrs "
    R> 2 .R ."  Mins "
    R> 2 .R ."  Secs " CR
    DAY. SPACE 2
    .R SPACE MONTH.
    ."  20" DUP 10 <
    IF
        ." 0"
    THEN .
;

HEX

( display the time and date at the top of the screen )
( back to forth prompt when a key is pressed )
: CLOCKTEST                          ( -- )
    CLEARSCREEN
    DECIMAL
    BEGIN
        0 0 ATXY
        READCLOCK DUP SECS @ =
        IF
            SP!
        ELSE
            DUP SECS ! TIME.
        THEN
        200 MS
        ?TERMINAL
    UNTIL ;
 
DECIMAL


 