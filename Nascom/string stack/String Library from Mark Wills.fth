( Portable stack based string library for Nasforth )
( Original by Mark Wills 2014 )
( based on a string stack concept by Brian Cox 1988 )
( Adapted for Nasforth by Bob Edwards Nov 2023 )
( words in parenthesis are used internally by string stack )

( N.B. load throw-catch.fth before loading this file )

BASE @

DECIMAL

1 CONSTANT TRUE
0 CONSTANT FALSE

: WITHIN                    ( test low high -- flag )
    OVER - >R - R> U<
;

( duplicate nth item on the data stack, 0 pick = dup, 1 pick = over )
: PICK ( .... n - nth item )
    1+ CELLS SP@ + @
;

( drop 2nd item on stack )
: NIP   ( n1 n2 -- n2 )
    SWAP DROP
;

: <>
    = 0=
;

( Set up string stack. The stack grows downwards in memory )
( must be a multiple of the system CELL size )

256 CONSTANT ($SSIZE)       ( the string stack size in bytes )
HERE                        ( remember this location )
($SSIZE) ALLOT              ( reserve space for the string stack )

CONSTANT ($SEND)            ( set this to HERE above )
($SEND) ($SSIZE) +          ( initialise value for string stack pointer )
VARIABLE ($SP)              ( create the string stack pointer )
0 VARIABLE ($DEPTH)         ( count of string stack items )
0 VARIABLE ($TEMP0)         ( internal use )
0 VARIABLE ($TEMP1)         ( internal use )
0 VARIABLE ($TEMP2)         ( internal use )
0 VARIABLE ($TEMP3)         ( internal use )

 ( Increments the string stack item count )
: ($DEPTH+) ( -- ) 
    1 ($DEPTH) +!
;

( Returns address of current top of string stack )
: ($SP@) ( -- addr )
($SP) @
;

( Given an address of a transient string, compute the stack size in bytes )
( required to hold it, rounded up to the nearest cell size, and including )
( the length cell )
: (SIZEOF$) ( $addr - $size)
    @ ( ALIGNED ) CELL+
;

 ( Given the stack size of a transient string set the string stack pointer )
 ( to the new address required to accomodate it )
: (SET$SP) ( $size -- )
    MINUS DUP ($SP@) + ($SEND) < 
    IF
        9900 THROW
    THEN 
    ($SP) +!
;

 ( Given an index into the string stack, return the start address of the )
 ( string. addr points to the length cell. Topmost string is index 0, )
 ( next string is index 1 and so on )
: (ADDROF$) ( index -- addr )
    ($SP@) SWAP DUP 
    IF
        0 DO
            DUP (SIZEOF$) +
        LOOP
    ELSE
        DROP
    THEN
;

( Given the address of a transient string on the string stack, the address )
( of the length cell, return the length of the string )
: (LENOF$) ( $addr -- len )
    STATE @
    IF
        COMPILE @
    ELSE
        @
    THEN
; IMMEDIATE

 ( Returns the depth of the string stack )
: DEPTH$ ( -- $sDepth)
    ($DEPTH) @
;

( string constant )
: $CONST ( max_len tib:"name" -- ) ( runtime: -- $Caddr) 
    <BUILDS
        DUP ,
        0 ,
        ALLOT
    DOES>
;

( string constant length )
: CLEN$ ( $Caddr -- len )
    CELL+ @
;

( maximum length of string )
: MAXLEN$ ( $Caddr -- max_len )
    [COMPILE] (LENOF$)
;

( display string constant )
: .$CONST           ( $Caddr -- )
    CELL+           ( $cADDR+2 -- ) 
    DUP (LENOF$)    ( $cADDR+2 clength -- )
    SWAP CELL+      ( clength $cAddr+4 )
    SWAP            ( $cAddr+4 clength )
    TYPE            ( -- )
;

( assign string constant )
( e.g. msg :=" hello mother!" )
: :=" ( $Caddr "string" -- )
    DUP @               ( constadr constmaxlength )
    34 WORD             ( read string to HERE )
    HERE C@             ( read the new string length )
    < 
    IF                  ( constadr )
        9901 THROW      ( if too large, throw an error )
    THEN
    HERE C@ OVER CELL+ ! ( save new CONST length )
    HERE 1+ SWAP [ 2 CELLS ] LITERAL +
    HERE C@ CMOVE       ( copy the string )
;    

: ($") ( addr len -- ) ( ss: -- str )
     DUP CELL+ (SET$SP)
     DUP ($SP@) ! ($SP@) CELL+ SWAP CMOVE ($DEPTH+)
;

: (DO$")    ( -- adr length )
   34 WORD HERE DUP C@ >R 1+ R> 
;

( string to string stack )
: $" ( tib:"string" -- ) ( ss: -- str)
    STATE @ IF
        COMPILE (DO$") COMPILE ($")
    ELSE
        (DO$") ($")
    THEN
; IMMEDIATE 

( Moves a string constant to the string stack )
: >$ ( $Caddr -- ) ( ss: -- str)
    CELL+ DUP (LENOF$) SWAP CELL+ SWAP ($")
;

( copy the indexed string to the top )
: PICK$ ( n -- ) ( ss: -- strN)
    DEPTH$ 0= 
    IF
        9902 THROW
    THEN 
    (ADDROF$) DUP (LENOF$) SWAP CELL+ SWAP ($")
;

( duplicate string )
: DUP$ ( -- ) ( ss: s1 -- s1 s1)
    DEPTH$ 0=
    IF
        9902 THROW
    THEN 
    0 PICK$
;

( drop string )
: DROP$ ( -- ) ( ss: str -- )
    DEPTH$ 0=
    IF
        9900 THROW
    THEN
    ($SP@) (SIZEOF$) MINUS (SET$SP) -1 ($DEPTH) +!
;

( swap string )
: SWAP$ ( -- ) ( ss: s1 s2 -- s2 s1)
    DEPTH$ 2 <
    IF
        9903 THROW
    THEN 
    ($SP@) DUP (SIZEOF$) HERE SWAP CMOVE
    1 (ADDROF$) DUP (SIZEOF$) ($SP@) SWAP CMOVE
    HERE DUP (SIZEOF$) ($SP@) DUP (SIZEOF$) + SWAP CMOVE
;

( nip string )
: NIP$ ( -- ) ( ss: s1 s2 -- s2)
    DEPTH$ 2 <
    IF
        9903 THROW
    THEN 
    SWAP$ DROP$
;

( over string )
: OVER$ ( -- ) ( ss: s1 s2 -- s1 s2 s1)
    DEPTH$ 2 <
    IF 
        9903 THROW
    THEN
    1 PICK$
;

( rotate strings )
: ROT$ ( -- ) ( ss: s3 s2 s1 -- s2 s1 s3 )
    ($SP@)                      ( save this addr for stack pointer )
     2 PICK$                    ( ss: s3 s2 s1 s3 )
     3 (ADDROF$) DUP (SIZEOF$) + 1- ( end of string3 is destination )
     2 (ADDROF$) DUP (SIZEOF$) + 1- ( end of string2 is source )
     ($SP@) (SIZEOF$)   1 (ADDROF$) (SIZEOF$)   2 (ADDROF$) (SIZEOF$) + +
     0 DO
        2DUP
        C@ SWAP C!                  ( move a byte )
        1- SWAP 1- SWAP             ( decr the byte ptrs )
     LOOP
     DROP DROP
     ($SP) !                        ( save stack pointer )
     -1 ($DEPTH) +!                 ( and fix depth )
;

( rotate strings )
: -ROT ( -- ) ( ss: s3 s2 s1 -- s1 s3 s2)
     ($SP@)
     2 PICK$ 2 PICK$
     4 (ADDROF$) DUP (SIZEOF$) + 1- ( end of string4 is destination )
     2 (ADDROF$) DUP (SIZEOF$) + 1- ( end of string2 is source )
     ($SP@) (SIZEOF$) 1 (ADDROF$) (SIZEOF$) 2 (ADDROF$) (SIZEOF$) + +
     0 DO
        2DUP
        C@ SWAP C!                  ( move a byte )
        1- SWAP 1- SWAP             ( decr the byte ptrs )
     LOOP
     DROP DROP
     ($SP) !                        ( save stack pointer )
     -2 ($DEPTH) +!                 ( and fix depth )
;

( length of string )
: LEN$ ( -- len ) ( ss: -- )
     DEPTH$ 1 <
     IF
        9902 THROW
     THEN 
     ($SP@) @ 
;

( to string constant )
: >$CONST ( $Caddr -- ) ( ss: str -- )
     >R DEPTH$ 1 <
     IF
        9902 THROW
     THEN
     LEN$ R @ >
     IF
        9904 THROW
     THEN
     ($SP@) DUP (SIZEOF$) R> CELL+ SWAP CMOVE DROP$
;

( concatenate strings )
: +$ ( -- ) ( ss: s1 s2 -- s2+s1 ) 
     DEPTH$ 2 <
     IF
        9903 THROW
     THEN 
     1 (ADDROF$) CELL+ HERE 1 (ADDROF$) (LENOF$) CMOVE
     ($SP@) CELL+ 1 (ADDROF$) (LENOF$) HERE + LEN$ CMOVE
     HERE LEN$ 1 (ADDROF$) (LENOF$) + DROP$ DROP$ ($")
;

( mid-string )
: MID$ ( start len -- ) ( ss: str1 -- str1 str2)
     DEPTH$ 1 <
     IF
        9902 THROW
     THEN 
     DUP LEN$ > OVER 1 < OR
     IF
        9905 THROW
     THEN
     OVER DUP LEN$ > SWAP 0< OR
     IF
        9908 THROW
     THEN 
     SWAP ($SP@) CELL+ + SWAP ($")
;

( left of string )
: LEFT$ ( len -- ) ( ss: str1 -- str1 str2)
     DEPTH$ 1 <
     IF
        9902 THROW
     THEN 
     DUP LEN$ > OVER 1 < OR
     IF
        9905 THROW
     THEN 
     0 ($SP@) CELL+ + SWAP ($")
;

( right of string )
: RIGHT$ ( len -- ) ( ss: str1 -- str1 str2)
    DEPTH$ 1 <
    IF
        9902 THROW
    THEN 
    DUP LEN$ > OVER 1 < OR
    IF
        9905 THROW
    THEN 
    ($SP@) (LENOF$) OVER - ($SP@) CELL+ + SWAP ($")
;

( find character in string )
: FINDC$ ( char -- pos|-1 ) ( ss: -- )
     DEPTH$ 1 <
     IF
        9902 THROW
     THEN 
     ($SP@) CELL+ ($SP@) (LENOF$) 0   (  findchr chraddr length 0  )
     DO                               (  findchr chradr )
        DUP C@                        (  findchr chradr chr )
        2 PICK =                      (  findchr chradr flag )
        IF                            (  findchr chradr )
            I -2 LEAVE                (  findchr chradr I -2 ) 
        THEN
        1+                            (  findchr chradr+1 )
     LOOP
     -1 =
     IF
        NIP NIP
     ELSE
        DROP -1
     THEN
;

( Searches string s1, beginning at offset, for the substring s2 )
: FIND$ ( offset -- pos|-1 ) ( ss: s1 s2 -- s1)
     DEPTH$ 2 <
     IF
        9903 THROW
     THEN 
     LEN$ ($TEMP1) ! 1 (ADDROF$) (LENOF$) ($TEMP0) !
     DUP ($TEMP0) @ >
     IF
        DROP -1 FALSE
     ELSE
        TRUE
     THEN
     IF
         1 (ADDROF$) CELL+ + ($TEMP2) ! ($SP@) CELL+ ($TEMP3) !
         ($TEMP1) @ ($TEMP0) @ >
         IF
            DROP -1 FALSE
         ELSE
            TRUE
         THEN
         IF       
             0 ($TEMP0) @ 0
             DO
                 ($TEMP3) @ OVER + C@ 
                 ($TEMP2) @ I + C@ =
                 IF
                    1+ DUP ($TEMP1) @ =
                    IF 
                        DROP I ($TEMP1) @ - 1+ -2 LEAVE
                    THEN 
                 ELSE
                    DROP 0
                 THEN
             LOOP 
             DUP -2 =
             IF
                DROP
             ELSE
                DROP -1
             THEN
             DROP$
         THEN
     THEN
;

( display string )
: .$ ( -- ) ( ss: str -- )
    DEPTH$ 0=
    IF
        9902 THROW
    THEN 
    ($SP@) CELL+ ($SP@) (LENOF$) TYPE DROP$
;

( reverse string ) 
: REV$ ( -- ) ( ss: s1 -- s2 )
    DEPTH$ 0=
    IF
        9902 THROW
    THEN 
    ($SP@) DUP CELL+ >R (LENOF$) R> SWAP HERE SWAP CMOVE 
    ($SP@) (LENOF$) HERE 1- +
    ($SP@) CELL+ DUP ($SP@) (LENOF$) + SWAP
    DO
        DUP C@ I C! 1-
    LOOP
    DROP
;

( left trim string )
: LTRIM$ ( -- ) ( ss: s1 -- s2 )
    DEPTH$ 0=
    IF
        9902 THROW
    THEN 
    ($SP@) DUP (LENOF$) >R HERE OVER (SIZEOF$) CMOVE
    0 R> HERE CELL+ DUP >R + R>
    DO
        I C@ BL =
        IF
            1+
        ELSE
            LEAVE
        THEN
    LOOP 
    DUP 0 >
    IF 
        >R ($SP@) (LENOF$) DROP$
        HERE CELL+ R + SWAP R> - ($")
    ELSE
        DROP 
    THEN
;

( right trim string )
: RTRIM$ ( -- ) ( ss: s1 -- s2 )
    DEPTH$ 0=
    IF
        9902 THROW
    THEN
    REV$ LTRIM$ REV$
;

( trim string )
: TRIM$ ( -- ) ( ss: s1 -- s2 )
    RTRIM$ LTRIM$
;

( In string s2 find s3 and replace with s1, resulting in s4 )
: REPLACE$ ( -- pos | -1 )
( found: ss: s1 s2 s3 -- s4 not found: s1 s2 s3 -- s1 s2)
    DEPTH$ 3 <
    IF
        9906 THROW
    THEN
    LEN$ >R
    0 FIND$
    DUP ($TEMP0) ! -1 >
    IF
        ($SP@) CELL+ HERE ($TEMP0) @ CMOVE 
        1 (ADDROF$) CELL+ HERE ($TEMP0) @ + 
        1 (ADDROF$) (LENOF$) CMOVE
        ($SP@) CELL+ ($TEMP0) @ + R + 
        HERE ($TEMP0) @ + 1 (ADDROF$) (LENOF$) +
        LEN$ R> - ($TEMP0) @ - DUP >R CMOVE
        R> ($TEMP0) @ + 1 (ADDROF$) (LENOF$) +
        DROP$ DROP$ HERE SWAP ($")
    ELSE
        R> DROP
    THEN
    ($TEMP0) @
;

( convert to upper case )
: UCASE$ ( -- ) ( ss: str -- STR )
DEPTH$ 1 <
    IF
        9902 THROW
    THEN
    ($SP@) DUP (LENOF$) + CELL+ ($SP@) CELL+
    DO
        I C@ DUP 97 123 WITHIN
        IF
            32 - I C!
        ELSE
            DROP
        THEN
    LOOP
;

( convert to lower case )
: LCASE$ ( -- ) ( ss: STR -- str)
    DEPTH$ 1 <
    IF
        9902 THROW
    THEN 
    ($SP@) DUP (LENOF$) + CELL+ ($SP@) CELL+
    DO
        I C@ DUP 65 91 WITHIN
        IF
            32 + I C!
        ELSE
            DROP
        THEN
    LOOP
;

( is equal to string )
: ==$? ( -- flag ) ( ss: -- )
    DEPTH$ 2 <
    IF
        9903 THROW
    THEN
    LEN$ 1 (ADDROF$) (LENOF$) =
    IF
        1 (ADDROF$) CELL+
        ($SP@) CELL+ LEN$ + ($SP@) CELL+ 
        DO
            DUP C@ I C@ <>
            IF
                DROP FALSE LEAVE
            THEN
            1+
        LOOP
        DUP
        IF
            DROP TRUE
        THEN 
    ELSE
        FALSE
    THEN
;

( Non-destructively displays the string stack )
: $.S ( -- ) ( ss: -- )
    CR DEPTH$ 0 >
    IF
        ($SP@) DEPTH$
        ." Index|Length|String" CR
        ." -----+------+------" CR 
        0 
        BEGIN
            DEPTH$ 0 > WHILE
            DUP 5 .R ." |" LEN$ 6 .R ." |" .$ 1+ CR
        REPEAT 
        DROP
        ($DEPTH) ! ($SP) ! CR
    ELSE
        ." String stack is empty" CR
    THEN
    ." Allocated stack space:" ($SEND) ($SSIZE) + ($SP@) - 4 .R ."  bytes" CR
    ."     Total stack space:" ($SSIZE) 4 .R ."  bytes" CR
    ." Stack space remaining:" ($SP@) ($SEND) - 4 .R ."  bytes" CR
;

2 $CONST ENDNUM
ENDNUM :="  "

( Convert top of string stack to a double number )
: $>N ( -- d ) ( ss: str -- )
    ENDNUM >$ +$    ( terminate number with a space )
    ($SP@)
    DUP C@
    SWAP 1+
    C!
    ($SP@) 1+ NUMBER
    0 ($SP@) 1+ C!
    DROP$
;

: $DUMP
    ($SP@) 50 DUMP
;

( Pushes the signed number on the data stack to the string stack )
: N>$ ( n -- ) ( ss: -- str )
    SWAP OVER DABS <# #S SIGN #> ($")
;

BASE !
