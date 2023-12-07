( Throw and Catch error management for Nasforth )

( duplicate only if n<>0 )
: ?DUP      ( n -- n n | 0 )
    DUP IF DUP THEN
;

( RP! & SP! used to mean reset stack pointers to R0 or S0 )
( Modern forths have the following definitions )
( Set data stack pointer = addr )
CODE SPSET  ( addr -- )
    H POP
    H LSPX
    NEXT JMP
END-CODE

HEX

( Set return stack pointer = addr )
CODE RPSET   ( addr -- )
    H POP
    1024 H SXD
    NEXT JMP
END-CODE

DECIMAL

0 VARIABLE CATCH-RP ( return stack pointer at run-time )

: CATCH ( xt -- exception# | 0  return addr on stack )
  SP@ >R                ( save data stack pointer )
  CATCH-RP @ >R         ( and previous handler )
  RP@ CATCH-RP !        ( set current handler )
  CFA EXECUTE           ( execute returns if no THROW )
  R> CATCH-RP !         ( restore previous handler )
  R> DROP               ( discard saved stack pointer )
  0                     ( signal normal completion )
 ;

: THROW ( ??? exception# -- ??? exception# )
  ?DUP IF               ( 0 THROW is no-op )
      CATCH-RP @ RPSET  ( restore previous return stack )
      R> CATCH-RP !     ( restore previous handler )
      R> SWAP >R        ( exc# on return stack )
      SPSET DROP R>     ( restore stack )
  THEN
 ;
  
( A simple test )

-10 CONSTANT DIV0ERROR
  
: / ( A B -- A/B with added divide by zero protection )
  DUP 0= IF
    DIV0ERROR THROW
  THEN / ( previous unprotected version of divide )
;

( divide top two numbers on stack and print the result )
: /. ( A B -- )
  OVER . ." DIVIDED BY " DUP . ." IS "
  [ ' / ] LITERAL CATCH 
  DIV0ERROR = IF
    DROP DROP
    ." INFINITY "
  ELSE
    .
  THEN
;
 