\ Stopping the VGA display controller in COG7 and reclaiming pins P0 - P4 for user programs
\ Bob Edwards Aug 2022


\ print a COG ram register in hex
pub .REGH   ( addr -- )
    COG@ .H CRLF
;

\ print a COG ram register in binary
pub .REGB   ( addr -- )
    COG@ .BIN CRLF
;


\ print all the named COG ram registers
pub COGREGS.    ( -- )
    ." IJMP3 = " IJMP3 .REGH
    ." IRET3 = " IRET3 .REGH
    ." IJMP2 = " IJMP2 .REGH
    ." IRET2 = " IRET2 .REGH
    ." IJMP1 = " IJMP1 .REGH
    ." IRET1 = " IRET1 .REGH
    ." PA    = " PA    .REGH
    ." PB    = " PB    .REGH
    ." PTRA  = " PTRA  .REGH
    ." PTRB  = " PTRB  .REGH
    ." DIRA  = " DIRA  .REGB
    ." DIRB  = " DIRB  .REGB
    ." OUTA  = " OUTA  .REGB
    ." OUTB  = " OUTB  .REGB
    ." INA   = " INA   .REGB
    ." INB   = " INB   .REGB
;

\ stop anything running in COGS 1-7
8 1 DO I COGSTOP LOOP

\ Attempt at resetting pin P0 to P4 to non-smartpin inputs
pub VGArelease
    100 ms CRLF ." Before ..." CRLF
    COGREGS.
    0 OUTA COG!
    0 OUTB COG!
    0 DIRA COG!
    0 DIRB COG!
    32 0 DO I MUTE LOOP
    0 PIN FLOAT
    1 PIN FLOAT
    2 PIN FLOAT
    3 PIN FLOAT
    4 PIN FLOAT
    ." After VGArelease ..." CRLF
    COGREGS.
;

7 RUN: VGArelease

2000 ms

0 PIN H
1 PIN H
1 MUTE
1 PIN H
2 PIN H
2 MUTE
2 PIN H
3 PIN H
3 MUTE
3 PIN H
4 PIN H


\ This does free off pins P0-P4 - they're all high outputs at the end of this sequence
\ Found by trial and error - Now needs cutting down to the minimum
\ Resetting Taqoz with ^C does not reinstate the VGA controller, but ^Z does as you would expect

