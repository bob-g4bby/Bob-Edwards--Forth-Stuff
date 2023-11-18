( More String stuff for Polydos NasForth - Bob Edwards Nov 2023 )

( flag -- flag' )
: NOT
    1 XOR
;

( the following words are from 'The Complete Forth' by Alan Winfield )

( load a string variable with a following string, terminate with $ )
( e.g. FILENAME PUT$ myfile$ )
: PUT$                  ( <string> --  )
    DROP 1-
    DUP 1- C@
    36 WORD
    HERE C@
    < IF
        ." String too big"
        DROP QUIT
    THEN
    HERE DUP C@ 1+
    ROT SWAP CMOVE
;

: -MATCH                 ( addr1 n addr2 -- flag )
    OVER OVER               ( dup length and addr2 )
    + SWAP DO                ( loop thru chrs )
            DROP 1+ DUP 1- C@   ( get chr from str1 )
            I C@ - DUP
            IF                  ( not equal? )
                DUP ABS / LEAVE
            THEN
        LOOP
        SWAP DROP
;

( test two strings are equal )
: $=        ( addr1 n1 addr2 n2 -- flag )
    ROT OVER =
    IF
        SWAP -MATCH NOT
    ELSE
        DROP DROP DROP 0
    THEN
;

( the following words are from Marc Petremann )

( get maxlength of a string )
: MAXLEN$  ( strvar --- strvar maxlen ) 
    OVER CELL - CELL - @ 
    ; 
 
( extract n chars right from string )
: RIGHT$  ( str1 n --- str2 ) 
    0 MAX OVER MIN >R + R@ - R> 
    ; 
 
( extract n chars left from string ) 
: LEFT$  ( str1 n --- str2 ) 
    0 MAX MIN 
    ; 
 
( extract n chars from pos in string ) 
: MID$  ( str1 pos len --- str2 ) 
    >R OVER SWAP - RIGHT$ R> LEFT$ 
    ; 
 
( append char c to string ) 
: C+$!  ( c str1 -- ) 
    OVER >R 
    + C! 
    R> CELL - DUP @ 1+ SWAP ! 
    ; 
 