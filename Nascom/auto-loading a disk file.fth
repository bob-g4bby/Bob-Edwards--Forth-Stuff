( Nasforth reading Polydos text files from disk - Bob Edwards Nov 2023 - ver 1 )

( If a word on the input stream is not recognised, a file with the )
( same name, extension .TX, is searched for on the disk and the text )
( read in as if from the terminal. After the end-of-file is reached, )
( terminal input is switched back to normal - keyboard/serial-in port )
( if no drive number is specified, the master drive is assumed, just )
( like Polydos )

( before loading this file, load at least, files :- )
( dforth.fth )
( throw-catch.fth )
( String Library from Mark Wills.fth )
( nasforth expansion.fth )

HEX
( Polydos workspace 'command file' variables )
C000    CONSTANT    MDRV    ( master drive number )
C001    CONSTANT    DDRV    ( current file drive number )
C00B    CONSTANT    CFFLG   ( command file flag )
C00C    CONSTANT    CFDRV   ( command file drive )
C00D    CONSTANT    CFSEC   ( command file sector address )
C00F    CONSTANT    CFNSC   ( command file sector counter )
C010    CONSTANT    CFSBP   ( command file buffer pointer )

DECIMAL

( extend filename to 8 bytes )
: NAMEPAD   ( -- ss: filename -- filename' )
    8 LEN$ - 0
    DO
        $"  " +$
    LOOP
;

( attempt to strip off the drive number from a filename )
: DRIVENO? ( -- driveno ss: filename -- filename' )
    UCASE$          ( convert filename to uppercase )
    58 FINDC$       ( search for : in filename )
    DUP -1 =
    IF              ( : was not found )
        DROP 0      ( driver number not found, assume drive 0 )
    ELSE            ( : was found )
        DUP
        LEFT$    ( strip off drive number )
        SWAP$
        1+ 1 MID$   ( isolate drive number )
        SWAP$ DROP$
        $>D DROP    ( convert to number )
    THEN
;

( attempt to strip off the file extension from a filename )
: EXT?  ( -- ss: filename -- filename' extension )
    46 FINDC$       ( search for . in filename )
    DUP -1 =
    IF              ( . not found )
        DROP $" TX" ( assume TX extension )
    ELSE            ( . found )
        DUP
        LEFT$    ( strip off extension )
        SWAP$
        1+ 2 MID$   ( isolate extension )
        SWAP$ DROP$
    THEN
;


( top of string stack loaded to fcb )
: FILENAME>FCB  ( fcbaddress -- )
    NAMEPAD
    ($SP@) 2+
    SWAP FNAM
    8 CMOVE
    DROP$
;

( top of string stack loaded to fcb )
: EXT>FCB       ( fcbaddress -- )
    ($SP@) 2+
    SWAP FEXT
    2 CMOVE
    DROP$
;

( display a file control block for debug )
: .FCB  ( addr -- )
    BASE @ >R
    HEX
    CR ."  FCB at address: " DUP U.
    DUP FNAM
    CR ."       filename : " 8 TYPE
    DUP FEXT
    CR ."      extension : " 2 TYPE
    DUP FSFL
    CR ."   system flags : " C@ U.
    DUP FUFL
    CR ."     user flags : " C@ U.
    DUP FSEC
    CR ." sector address : " @ U.
    DUP FNSC
    CR ." no. of sectors : " @ U.
    DUP FLDA
    CR ."   load address : " @ U.
    FEXA
    CR ."   exe. address : " @ U.
    R> BASE !
;

: FILE>FCB  ( fcbaddress -- fcbadr newfcbadr flags’ status )
            (  ss: filename -- filename            )
    DUP$                ( save a copy of the filename )
    UCASE$              ( convert filename to uppercase )
    DRIVENO?            ( check for drive number in filename )
    EXT?                ( check for extension in filename )
    S1FCB EXT>FCB       ( copy filename to fcb )
    S1FCB FILENAME>FCB  ( copy file extension to fcb )
    DUP CFDRV C!        ( set command file drive number )
    RDIR 0= IF          ( read directory )
        0 16 LOOK       ( look up file in the directory )
    THEN
;

HEX

( start a command file running )
: (CMDFILE)   ( fcbadr -- )
    DUP FSEC @              ( the  file's start sector )
    CFSEC !                 ( set CFSEC )
    FNSC C@                 ( the file's sector count )
    CFNSC C!                ( set CFNSC )
    0 CFSBP C!              ( indicate sector buffer empty )
    FF CFFLG C!             ( set command file mode active )
;

( the unknown word appearing at the input stream is stored )
( as a counted string at HERE - so we can use that )
( as our filename to search for )

( copy unknown word at HERE to string stack )
: UNKNOWN>$     ( ss: -- unknownword )
    HERE 1+ HERE C@ ($")
;

( convert file to fcb and start it as command file else )
( if not found clean up and emit error message )
: CMDFILEGO
    UNKNOWN>$           ( move unknown name to string stack )
    S1FCB FILE>FCB      ( fcb = file details if found )
    0= IF               ( file was found )
        DROP DROP DROP$ ( clean up stacks )
        (CMDFILE)       ( start the command file running )
    ELSE                ( else file not found )
        DROP DROP DROP
        .$ ." ? Unknown word"   ( error message )
    THEN
    DROP DROP DROP DROP ( mystery why this is needed )
    QUIT                ( and wait for new commands )
;

' CMDFILEGO CFA ' (ABORT) !  ( add in cmd file start to abort process ) 

( Enable or disable command file load )
: CMDFILE   ( true | false -- )
IF
    -1
ELSE
    0
THEN
WARNING !
;
