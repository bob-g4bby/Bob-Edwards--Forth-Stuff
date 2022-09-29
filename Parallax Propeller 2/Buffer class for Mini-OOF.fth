--- Buffer class ver 5 in Mini-OOF for Taqoz Reloaded v2.8 Bob Edwards July 2022
--- The buffer data type is long

IFDEF *BUFFERL*
	FORGET *BUFFERL*
}
pub *BUFFERL* ." Buffers of type long ver 5 using Mini-OOF" ;

4 := CELLS

--- BUFFER class definition

OBJECT CLASS
	4 VARI BUFADRL
	4 VARI BUFADRH
	4 VARI BUFHEAD
	4 VARI BUFTAIL
	1 VARI BUFSTATUS
	METHOD BUFINIT
	METHOD BUFEMPTY?
	METHOD BUFEMPTY
	METHOD BUFFULL?
	METHOD BUF!
	METHOD BUF@
	METHOD BUFPOP
	METHOD BUFADR@
	METHOD .BUF
END-CLASS BUFFER

private
--- buffer status
0 := partfull
1 := full
2 := empty
public

--- ensure buffer is circular, dir=1 is top address check, dir=0 bottom address check
pri PTRWRAP	( dir ptr -- ptr' )
	IF
		DUP	THIS BUFADRH @ =
		IF
			DROP THIS BUFADRL @
		THEN
	ELSE
		DUP	THIS BUFADRL @ <
		IF
			DROP THIS BUFADRH @ CELLS -
		THEN
	THEN
;

--- are HEAD and TAIL pointers equal?
pri PTR=	( -- flag )
	THIS BUFHEAD @
	THIS BUFTAIL @ =
;

--- create a buffer, n longs in size, and set it as empty
pri noname					( n -- )
	WITH
		org@ >R
		DUP CELLS * org@ + org				--- allocate the buffer storage in data space
		R> DUP THIS BUFADRL !				--- save start address of buffer
		SWAP CELLS * + THIS BUFADRH !		--- save the top limit address of buffer
		THIS BUFEMPTY						--- set HEAD and TAIL to ADDRL
	ENDWITH
; ANON BUFFER DEFINES BUFINIT

--- return true if the buffer is empty
pri noname					( -- flag )
	WITH
		THIS BUFSTATUS C@ empty = 			--- return true if buffer empty
	ENDWITH
; ANON BUFFER DEFINES BUFEMPTY?

--- empty the buffer of all data
pri noname					( -- )
	WITH
		THIS BUFADRL @ DUP					--- get the buffer start address
		THIS BUFHEAD !						--- initialise the data input pointer
		THIS BUFTAIL !						--- initialise the data output pointer
		empty THIS BUFSTATUS C!				--- set buffer status to empty
	ENDWITH
; ANON BUFFER DEFINES BUFEMPTY

--- return true if the buffer is full
pri noname					( -- flag )
	WITH
		THIS BUFSTATUS C@ full =			--- return true if buffer is full
	ENDWITH
; ANON BUFFER DEFINES BUFFULL?

--- write a long into the buffer
pri noname					( n -- )
	WITH
		THIS BUFFULL?
		IF THIS BUF@ DROP THEN				--- if the buffer is alreay full, make room
		THIS BUFHEAD @ CELLS +
		1 PTRWRAP
		DUP THIS BUFHEAD !					--- increment the buffer head pointer
		!									--- and write the data n
		PTR=
		IF full ELSE partfull THEN
		THIS BUFSTATUS C!					--- and update buffer status
	ENDWITH
; ANON BUFFER DEFINES BUF!

--- read a long from the front of the buffer (first in, first out)
pri noname					( -- n )
	WITH
		THIS BUFEMPTY?
		IF
			0									--- overreading, just return 0
		ELSE
			THIS BUFTAIL @ CELLS +
			1 PTRWRAP
			DUP THIS BUFTAIL !					--- increment the buffer head pointer
			@									--- and read the data n
			PTR=
			IF empty ELSE partfull THEN
			THIS BUFSTATUS C!					--- and update buffer status		
		THEN
	ENDWITH
; ANON BUFFER DEFINES BUF@

--- read a long from the back of the buffer like a stack ( first in, last out )
pri noname					( -- n )
	WITH
		THIS BUFEMPTY?
		IF
			0									--- overreading, just return 0
		ELSE
			THIS BUFHEAD @ DUP @ SWAP			--- read the data n ( n [BUFHEAD] -- )
			CELLS - 0 PTRWRAP THIS BUFHEAD !	--- decrement the HEAD pointer
			PTR=
			IF empty ELSE partfull THEN			--- update buffer status
			THIS BUFSTATUS C!					--- and update buffer status
		THEN
	ENDWITH
	; ANON BUFFER DEFINES BUFPOP

--- returns address of nth element, for use as a normal array
pri noname			( -- adr )
	BUFADRL @ 
; ANON BUFFER DEFINES BUFADR@

pri noname 
	WITH
		CRLF ." BUFADRL   = " THIS BUFADRL @ .L
		CRLF ." BUFADRH   = " THIS BUFADRH @ .L
		CRLF ." BUFHEAD   = " THIS BUFHEAD @ .L
		CRLF ." BUFTAIL   = " THIS BUFTAIL @ .L
		CRLF ." BUFSTATUS = " THIS BUFSTATUS C@
		SWITCH
			partfull	CASE ." partfull" BREAK
			full		CASE ." full" BREAK
			empty		CASE ." empty" BREAK
	ENDWITH
; ANON BUFFER DEFINES .BUF

--- end of BUFFER class definition

--- Test of the buffer class
10 := bufsize
BUFFER NEW := MYBUF

pub TEST	( -- )
CRLF CRLF
bufsize MYBUF BUFINIT 					CRLF ." Buffer initialised " bufsize . ." longs in size (do once only as space is allotted)"
MYBUF BUFEMPTY? 						CRLF ." BUFEMPTY? returns " .
MYBUF BUFFULL? 							CRLF ." BUFFULL? returns " .
bufsize 2+ FOR I MYBUF BUF! NEXT 		CRLF ." Buffer overfilled on purpose"
MYBUF BUFEMPTY? 						CRLF ." BUFEMPTY? returns " .
MYBUF BUFFULL? 							CRLF ." BUFFULL? returns " .
										CRLF ." Now read all buffer, as a buffer"
bufsize FOR MYBUF BUF@ CRLF . NEXT		CRLF ." All buffer read as a buffer - note values 0,1 are lost" 
MYBUF BUFEMPTY?							CRLF ." BUFEMPTY? returns " .
MYBUF BUFFULL? 							CRLF ." BUFFULL? returns " .
bufsize FOR I MYBUF BUF! NEXT 			CRLF ." Buffer filled up again and now read again as a stack"
bufsize FOR MYBUF BUFPOP CRLF . NEXT	CRLF ." All buffer read as a stack"
MYBUF BUFEMPTY? 						CRLF ." BUFEMPTY? returns " .
MYBUF BUFFULL? 							CRLF ." BUFFULL? returns " .
;





