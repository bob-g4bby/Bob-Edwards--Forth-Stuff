
\ convert a chr on top of stack to upper case
: chrtoCHR	( chr -- CHR )
	dup [char] a >=
	dup [char] z <= and
	if
		 $5F and
	then
;

\ convert zstring to upper case
: >UPPER		( zstring -- )
	z>s
	0 DO
		DUP
		I +
		DUP C@
		chrtoCHR SWAP c!
	LOOP
	DROP
;

\ convert two counted strings to upper case and compare, alters the strings
: UPPER$=		( str1 cnt1 str2 cnt2 )
		>R >R >R DUP >UPPER
		R> R> DUP >UPPER R>
		str=
;

: MOVE$			( str1 cnt1 str2 )
	swap cmove	
;


\ Records the incoming stream to spiffs file named a,n, until the RECORDSTOP word is found, then close file
: RECORDFILE  ( a n -- )
    W/O CREATE-FILE                         \ create the file to record to
    \ tib input-limit accept                  \ read line of input - maybe
;

\ create a file
\ read a line from the input stream
\ if it doesn't contain the end word save it in the file
\ else close the file

\ If string contains the word RECORDSTOP, flag=true, else false
: RECORDEND?        ( a n -- a n flag )
    2DUP S" RECORDEND" UPPER$=
;
