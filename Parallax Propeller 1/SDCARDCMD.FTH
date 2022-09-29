--- Tachyon 5v7 - Extension to dictionary search to include running files on SD card

--- Enable or disable SD card search for unknown dictionary words
pub BATCHFILE	( on/off -- )	
IF
	' FRUN undef W!
ELSE
	0 undef W!
THEN ;

--- 	Usage:
--- ON BATCHFILE    If a word is not in the dictionary, a search
--- is made on SD card for a file of the same name
--- OFF BATCHFILE   Tachyon will only search the dictionary for words,
--- the SD card search is turned off

ON QUIET

--- Tachyon 5v7 - Experimental WWORDS debug command that loads from SD card,
--- then is forgotten again after executing
--- Because this is forgotten afterwards, we can afford to
--- fit some user information


pre WW
	[CON
	BEGIN KEY 0= UNTIL
	ERSCN HOME
	." Enter the first letter of the words or RETURN for all the words"
	SPACE WKEY
	DUP $0D =
	IF
		DROP 0
	ELSE
		DUP EMIT
	THEN

	CR CR ." Key to data: Each entry consists of: "
	." Name field address "
	." | Code field address " 
	." | Key field "
	." | Word name"
	CR ." Key to colours: " 
	BOLD red PEN ." Module Marker " 
	PLAIN green PEN ." Public words "
	red PEN ." Private words "
	BOLD green PEN ." Preemptive words "
	PLAIN cyan PEN ." Public data "
	yellow PEN ." Private data" white PEN CR

	@NAMES 0 SWAP
	BEGIN
	  PLAIN DUP C@
	  KEY $1B <> AND
	  2 REG W-- 2 REG W@ 0<> AND
	WHILE ( match wcnt nfa )
	  3RD OVER 1+ C@ =
	  4TH 0= OR
	  IF
	  	OVER 3 AND 0= 
		IF
			CR
		THEN
	  	SWAP 1+ SWAP
	  	lsword
		16 OVER C@ $1F AND - SPACES
	  THEN
	  +NFA
	REPEAT
	CR ." Number of words was " OVER . CR CR
	3DROP CR 2 REG W~
	CON]	
;
OFF QUIET 
WW
0 XTAB FORGET WW ERLINE
