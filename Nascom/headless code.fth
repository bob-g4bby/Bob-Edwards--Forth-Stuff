( headless code for Nasforth )

HEX

15FE CONSTANT (:)           ( the inner interpreter cfa )
1434 CONSTANT (;)

( Headless words are assigned to methods after a CLASS is defined )
: :NONAME
    ?EXEC HERE !CSP (:) , [COMPILE] ]
;

: NONAME;
    [ (;) ,
;

( TEST )

:NONAME 3 * . ;           ( -- startaddr )

30 SWAP EXECUTE
