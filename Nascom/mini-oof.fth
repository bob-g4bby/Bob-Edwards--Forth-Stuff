( Mini-OOF for Nasforth ver. 2 - adapted from )
( Bernd Paysan's original design by Bob Edwards - Nov 2023 )
( see https://bernd-paysan.de/mini-oof.html )

( Compatibility words )

: CREATE
    0 VARIABLE -2 ALLOT
;

( No. of bytes per 'long' in Nasforth )
2 CONSTANT CELL

: 2DUP  ( n1 n2 -- n1 n2 n1 n2 )
    OVER OVER
;

( flag=true if n1<>n2 )
: <>    ( n1 n2 -- flag )
    = 1 XOR
;

( remove n chrs from the front of the counted byte block )
: /STRING       ( addr1 cnt1 n -- addr2 cnt2 ) 
  DUP >R -
  SWAP R> +
  SWAP
 ;

HEX

15FE CONSTANT (:)           ( the inner interpreter start address )

( Headless words are assigned to methods after a CLASS is defined )
: :NONAME
    ?EXEC HERE !CSP (:) , SMUDGE ]
;

DECIMAL


( MINI-OOF words )

: METHOD
    <BUILDS              ( m v -- m' v )
        OVER ,          ( compile m )
        SWAP CELL+ SWAP ( m' = m + cell )
    DOES>               ( ... O --- ... )
        @ OVER @ +      ( calc the reqd method addr from the object ref )
        @ EXECUTE       ( read the method's xt and execute it )
;

( VAR enables creating variables - this an object's data )
: VAR ( m v size -- m v' )
    <BUILDS
        OVER , +
    DOES> ( O -- ADDR )
        @ +
;

( This empty object is the root of all objects we create )
CREATE OBJECT  1 CELLS , 2 CELLS ,

( CLASS begins the definition of our 'recipe' for making objects )
: CLASS ( CLASS -- CLASS METHODS VARS )
    DUP 2@
;

( END-CLASS terminates the definition of a 'recipe' for making objects )
: END-CLASS  ( class methods vars -- )
    CREATE HERE >R , DUP , 2 CELLS 
    2DUP <>
        IF
            DO
                [ ' NOOP ] LITERAL , 
                1 CELLS
            +LOOP
        ELSE
            DROP DROP
        THEN
    CELL+ DUP CELL+ R> ROT @ 2 CELLS /STRING CMOVE
;

( DEFINES enables creating new methods in our 'recipe' for making objects )
( USAGE - after a nameless method definition - )
( :noname .... ; classname DEFINES methodname )
: DEFINES ( xt class -- )
    [COMPILE] ' 2+ @ + !
;

( NEW enables the creation of new objects from our CLASS recipe )
: NEW ( class -- o )
    HERE OVER @ ALLOT SWAP OVER !
;

( And sometimes derived classes want to )
( access the method of the parent object )
( There are two ways to achieve this with this OOF: first, )
( you could use named words, )
( and second, you could look up the vtable of the parent object )
( NB use this early binding word within a definition only, )
( it doesn't work outside a definition )
: :: ( class "methodname" -- )
  [COMPILE] ' 2+ @ + @ ,
;
( this is an 'early binding' method selection, as the addr is resolved )
( during compilation. Use: MYOBJECT MYCLASS :: MYMETHOD )
( e.g. : TEST TIMER1 [ TIMER :: TPRINT ] CR ; )

( Example code )

( create a PET class )
OBJECT CLASS
    CELL VAR TEETH#
    CELL VAR HEIGHT
    METHOD SPEAK
    METHOD GREET
    METHOD WALK
    METHOD ADD.
END-CLASS PET

( define all the actions for the PET methods )
:NONAME ." pet speaks" DROP ; PET DEFINES SPEAK
:NONAME ." pet greets" DROP ; PET DEFINES GREET
:NONAME ." pet walks"  DROP ; PET DEFINES WALK
:NONAME  DROP + ." n1 + n2 = " . ; PET DEFINES ADD.

( create a DOG class which varies from PET slightly )
PET CLASS
    CELL VAR LENGTH  ( dogs have an extra VAR )
END-CLASS DOG

( create a CAT class which varies slightly from PET )
PET CLASS
    METHOD  HAPPY    ( cats have one more method than pets )
END-CLASS CAT

:NONAME ." cat purrs" DROP ; CAT DEFINES HAPPY

( cats 'override' pets - they do something different for these two methods )
:NONAME ." cat says meow" DROP   ; CAT DEFINES SPEAK
:NONAME ." cat raises tail" DROP ; CAT DEFINES GREET

( create a cat and dog object to work with )
CAT NEW CONSTANT TIBBY
DOG NEW CONSTANT FIDO

( set the variables in TIBBY and FIDO )
20 TIBBY TEETH# !
30 FIDO TEETH# !
50 TIBBY HEIGHT !
75 FIDO HEIGHT !
120 FIDO LENGTH !


( run some of the methods in TIBBY and FIDO )
TIBBY GREET
FIDO SPEAK
TIBBY HAPPY         ( the cat does more than the dog object )

( read back the variables in TIBBY and FIDO )
TIBBY TEETH# @ . CR
FIDO HEIGHT @ . CR
FIDO LENGTH @ . CR

( inheritance - doing stuff your parent CLASS can do )
TIBBY WALK          ( notice tibby is a pet so she can walk OK )
34 56 FIDO ADD.     ( the parent methods in PET are 'inherited' )

