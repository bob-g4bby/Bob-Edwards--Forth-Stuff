( headless code for Nasforth )

HEX

15FE CONSTANT (:)           ( the inner interpreter cfa )

: NONAME:
    HERE !CSP (:) , [COMPILE] ]
;

( TEST )

HEADLESS: 3 * . ;           ( -- startaddr )

30 SWAP  EXECUTE
