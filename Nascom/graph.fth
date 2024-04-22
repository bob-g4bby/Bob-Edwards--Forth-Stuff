( VGRA programmable graphics characters from Nasforth - Bob Edwards 1983,2024 )
( Requires VGRA.OV be present on Polydos master disk )

: VGRA ;                    ( MARKER IN CASE WE WANT TO FORGET )

HEX
 
0C29 CONSTANT CURSOR    ( CURRENT DISPLAY ADDRESS OF DISPLAY CURSOR ) 
0C92 CONSTANT WSP       ( SUBR. TO STORE STACK POINTER - USE AS STWSP CALL )
                                     

CODE WSP! 
    LABEL STWSP 6 H LXI
    SP  DAD                 ( HL=HL+SP ) 
    WSP H SXD               ( WSP=HL )
    RET
    END-CODE

( VGRA graphics library )

( INITIALISE THE GRAPHICS PACKAGE BEFORE USE )    
CODE HIRES                  ( INVOKES "VGRA.OV OVERLAY )
    I PUSH                  ( SAVE BC )
    3 RST HEX 88 C,         ( SCAL ZCOV )
    56 C, 47 C, 52 C, 41 C, ( VGRA )
    I POP NEXT JMP 
    END-CODE
    
C804 CONSTANT OVRLY ( OVERLAY START ADDR )

( MARK ALL PROGRAMMABLE CHARS AS UNUSED )
CODE FIXFRAME
    I PUSH OVRLY 3 + CALL I POP
    NEXT JMP
    END-CODE

CODE FINISH
    LABEL EXIT I POP H POP H POP NEXT JMP
    END-CODE

( SET THE GRAPHICS CURSOR TO Xaxis, Yaxis ABSOLUTE )
CODE MOVETO ( Yaxis Xaxis --- )
    STWSP CALL I PUSH OVRLY 6 + CALL EXIT JMP
    END-CODE

(  SET THE GRAPHICS CURSOR TO Xaxis, Yaxis RELATIVE )  
CODE MOVEBY ( dYaxis dXaxis --- )
    STWSP CALL I PUSH OVRLY 9 + CALL
    EXIT JMP
    END-CODE

( PLOT A POINT AT Xaxis, Yaxis ABSOLUTE )   
CODE POINTAT ( Yaxis Xaxis --- )
    STWSP CALL I PUSH OVRLY C + CALL
    EXIT JMP
    END-CODE

( PLOT A POINT AT Xaxis, Yaxis RELATIVE )    
CODE POINTBY ( dYaxis dXaxis --- )
    STWSP CALL I PUSH OVRLY F + CALL
    EXIT JMP
    END-CODE

( PLOT A LINE FROM CURRENT LOCATION TO Xaxis, Yaxis ABSOLUTE )    
CODE LINETO ( Yaxis Xaxis --- )
    STWSP CALL I PUSH OVRLY 12 + CALL
    EXIT JMP
    END-CODE

( PLOT A LINE FROM CURRENT LOCATION TO Xaxis, Yaxis RELATIVE )    
CODE LINEBY ( dYaxis dXaxis --- )
    STWSP CALL I PUSH OVRLY 15 + CALL
    EXIT JMP
    END-CODE

( PLOT A CIRCLE radius AT CURRENT X,Y AXIS )   
CODE CIRCLE ( radius -- )
    2 H LXI
    SP DAD                  ( HL -> CIRCLE RADIUS )
    I PUSH                  ( SAVE BC )
    OVRLY 18 + CALL         ( CALL CIRCLE DRAW )
    I POP                   ( RESTORE BC )
    H POP                   ( CONSUME RADIUS )
    NEXT JMP
    END-CODE

( RETURNS NUMBER OF UNUSED PROGRAMMABLE CHARS LEFT  )    
CODE RESOURCE ( --- CHARS LEFT )
    H POP H PUSH H PUSH      ( MAKE ROOM FOR ANSWER )
    2 H LXI SP DAD WSP H SXD ( SET WSP TO POINT TO ANSWER )
    OVRLY 1B + CALL NEXT JMP
    END-CODE
    
( SET BACKGROUND PATTERN AND NUMBER OF PROGRAMMABLE GRAPHICS CHARACTERS )    
CODE BACKGROUND ( CHARNO PATTERN --- )
    STWSP CALL I PUSH OVRLY 1E + CALL
    EXIT JMP
    END-CODE
      

( End of VGRA graphics library )

( Some test programs )
    
DECIMAL

: TEST
    HIRES
    128 192 MOVETO
    BEGIN
        126 0 DO
            FIXFRAME
            I DUP CIRCLE 4 - CIRCLE
            I MINUS 126 + DUP CIRCLE 4 - CIRCLE
        LOOP
    PAUSE
    UNTIL ;
    
 : CHECKRESOURCE
    RESOURCE 0= IF FIXFRAME THEN ;
    
0 VARIABLE SEED

: (RND)
    SEED @ 259 * 3 + 32767 AND DUP SEED ! ;
    
: RND (RND) 32767 */ ;

: BUBBLE
    HIRES
    BEGIN
        CHECKRESOURCE
        255 RND 383 RND MOVETO 30 RND CIRCLE
        PAUSE
    UNTIL ;
    
: H
    0 -5 -8 0 0 -8 8 0 0 -5 -21 0 0 5 8 0 0 8 -8 0 0 5 21 0 12 0 DO LINEBY LOOP 0 23 MOVEBY ;
    
: E
    0 -18 -5 0 0 13 -3 0 0 -5 -5 0 0 5 -3 0 0
    -13 -5 0 0 18 21 0 12 0 DO LINEBY LOOP 0 23 MOVEBY ;
    
: SQ
    0 -3 -3 0 0 3 3 0 4 0 DO LINEBY LOOP ;
    
: L 0 -18 -5 0 0 13 -16 0 0 5 21 0 6 0 DO LINEBY LOOP 0 23 MOVEBY ;

: O 0 -18 -21 0 0 18 21 0 4 0 DO LINEBY LOOP 5 5 MOVEBY 0 -8 -11 0 0 8 11 0 4 0 DO LINEBY LOOP -5 18 MOVEBY ;

: B 0 -15 -3 -3 -5 0 -3 3 -3 -3 -4 0 -3 3 0 15 21 0
    9 0 DO LINEBY LOOP
    4 7 MOVEBY
    SQ 10 0 MOVEBY
    SQ -14 16 MOVEBY ;

: HELLO H E L L O 0 10 MOVEBY B O B ;

( Move cursor to x,y on screen, 0,0 being top left of the screen )
: ATXY                        ( y x -- )
    DUP 47 U<
    IF 
        SWAP DUP 14 U<
        IF
            64 * + 2058 + CURSOR !
        ELSE
            DROP DROP
        THEN
    THEN ;
  
: HI
 HIRES
 BEGIN
    CHECKRESOURCE
    255 RND 383 RND MOVETO
    HELLO
    10 1 ATXY
    ." RESOURCE = " RESOURCE 4 .R 
    PAUSE
 UNTIL ;

: WELCOME
    HIRES
    BEGIN
        FIXFRAME
        5000 0 DO LOOP
        12 EMIT
        5000 0 DO LOOP
        110 75 MOVETO HELLO
        PAUSE
    UNTIL ;
  
0 VARIABLE XAXIS
0 VARIABLE YAXIS

( -- CHR  --- WAITS FOR CHARACTER FROM KEYBOARD )
CODE WAITKEY
    I PUSH 1 RST I POP
    A L MOV 0 H MVI
    HPUSH JMP
    END-CODE ( --- 0 or KEY )
 
HEX 
 
: WAITKEYTEST
    0C EMIT
    BEGIN
       5 5 ATXY
       ." WAITKEY RETURNS " WAITKEY DUP
       4 .R
    0D = UNTIL
;
 
: dXAXIS XAXIS +! ;
: dYAXIS YAXIS +! ;

: MS 10 * 0 DO LOOP ;

: RULE
<BUILDS SMUDGE ]
DOES> 2 - >R BEGIN R> 2+ DUP >R
@ EXECUTE UNTIL R> DROP ;

( Original hardware long gone, but it connected to port 3 )
: JOYSTICK ( --- Y X )
    20 3 P! 20 MS 3 P@ 0 3 P! 20 MS 3 P@ ;                          

: CUU DUP 13 = IF 1 dYAXIS 1 ELSE 0 THEN ;
: CUD DUP 14 = IF -1 dYAXIS 1 ELSE 0 THEN ;
: CUL DUP 11 = IF -1 dXAXIS 1 ELSE 0 THEN ;
: CUR DUP 12 = IF 1 dXAXIS 1 ELSE 0 THEN ;

: JOY
    DUP 20 = IF JOYSTICK 80 - -8 / dXAXIS
    80 - 8 / dYAXIS THEN 1 ;
    
RULE dXYAXIS CUU CUD CUL CUR JOY ;

DECIMAL

: CURDRAW
    YAXIS @ XAXIS @ POINTAT
    3 3 MOVEBY 5 5 LINEBY -16 0 MOVEBY 5 -5 LINEBY
    0 -6 MOVEBY -5 -5 LINEBY 16 0 MOVEBY -5 5 LINEBY
    -3 3 MOVEBY ;
    
DECIMAL

( joystick test moves cursor around until ENTER then ESC pressed )
: CURTEST
    HIRES 20 20 XAXIS ! YAXIS !
    BEGIN
        dXYAXIS CURDRAW
        FIXFRAME
        5 5 ATXY
        ." CURSOR "
        ." X=" XAXIS @ 4 .R
        ."  Y=" YAXIS @ 4 .R
        PAUSE 
    UNTIL ;
