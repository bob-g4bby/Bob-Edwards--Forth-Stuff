( Nasforth reading Polydos text files from disk - Bob Edwards Nov 2023 - ver 2 )

( If a word on the input stream is not recognised, a file with the )
( same name, extension .TX, is searched for on the disk and the text )
( read in as if from the terminal. After the end-of-file is reached, )
( terminal input is switched back to normal - keyboard/serial-in port )
( if no disk is specified, the disks specified in DISKPATH )
( are searched for the filename )

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

( string that defines disk search path )
10 $CONST DISKPATH
DISKPATH :=" 0 1 2 3 "

( place next disk in search path on stack and flag=0, else flag=-1 last one )
: NEXTDISK? ( -- n flag )
    TRIM$           ( trim off any leading spaces )
    32 FINDC$       ( find next space between numbers )
    DUP -1 <> IF    ( if a space found )
        LSPLIT$     ( split off the first disk drive )
        $>D         ( next disk drive top of stack )
    ELSE
        DROP
        LEN$ 1 =
        IF
            $>D DROP
            -1
        THEN
    THEN
;

( extend filename to 8 bytes )
: NAMEPAD   ( -- ss: filename -- filename' )
    8 LEN$ - 0
    DO
        $"  " +$
    LOOP
;

( attempt to strip off the drive number from a filename )
( returns driveno=-1 if no number found )
: DRIVENO? ( -- driveno | -1 ss: filename -- filename' )
    UCASE$          ( convert filename to uppercase )
    58 FINDC$       ( search for : in filename )
    DUP -1 <>
    IF              ( : was not found )
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

( look for S1FCB filename in directory )
: (FINDFILE)  ( disknum -- 0 found | nozero not found )
    RDIR DROP
    S1FCB 0 16 LOOK
    >R DROP DROP DROP R>
;

( scan disks for file, if found CFDRV set to disk, else CFDRV=-1 )
: FINDFILE  ( -- )
    DEPTH$                  ( remember string stack depth )
    DISKPATH >$             ( read the disk path )
    BEGIN
        NEXTDISK?           ( -- disk endpathflag )
        SWAP                ( -- endpathflag disk )
        DUP (FINDFILE) 0 =  ( -- endpathflag disk foundflag )
        DUP >R
        IF                  ( -- endpathflag disk )
            CFDRV C!
        ELSE
            DROP
        THEN                ( -- endpathflag )
        -1 =
        R>
        OR
    UNTIL
    DEPTH$ SWAP -
    DUP 0 > IF
        0 DO DROP$ LOOP  ( clean up string stack )
    ELSE
        DROP
    THEN
;

( search for cmd file, either on specified disk )
( or DISKPATH if no disk specified )
( CFDRV set to disk if successful, else -1 ))
: SEARCHFILE    ( -- ss: filename -- FILENAME )
    -1 CFDRV C!         ( signal file not found )
    UCASE$              ( filename to uppercase )
    DUP$
    DRIVENO?            ( check for drive number in filename )
    EXT?                ( check for extension type in filename )
    S1FCB EXT>FCB
    S1FCB FILENAME>FCB  ( S1FCB now contains filename )
    DUP -1 =            ( was drive number specified? )
    IF                  ( no drive number )
        DROP
        FINDFILE        ( search the DISKPATH disks )
    ELSE                ( drive number was specified )
        DUP
        (FINDFILE)
        0=
        IF
            CFDRV C!    ( file found )
        ELSE
            DROP        ( no file found )
        THEN
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

HEX

( convert file to fcb and start it as command file else )
( if not found clean up and emit error message )
: CMDFILEGO
    UNKNOWN>$           ( move unknown name to string stack )
    SEARCHFILE
    CFDRV C@
    FF = IF             ( file was not found )
        .$ ." ? Unknown word"   ( error message )
    ELSE                ( else file was found )
        S1FCB (CMDFILE) ( start the command file running )
        DROP$
    THEN
    DROP DROP DROP DROP ( tidy data stack )
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
