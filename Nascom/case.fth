( CASE FOR NASFORTH - Bob Edwards 1983ish )

( e.g. CASE <newword> <oldword1> <oldword2> <oldword3> ;
( 1 <newword would execute oldword2 )

: CASE
    <BUILDS
        SMUDGE ]
    DOES>
        SWAP 2 * + @
        EXECUTE
;

( test )

: oldword0
    ."  oldword0"
    CR
;

: oldword1
    ."  oldword1"
    CR
;

: oldword2
    ."  oldword2"
    CR
;

: oldword3
    ."  oldword3"
    CR
;

CASE MYCASE oldword0 oldword1 oldword2 oldword3 ;

0 MYCASE
1 MYCASE
2 MYCASE
3 MYCASE

