--- Batch File ver 2 for Taqoz Reloaded v2.8 - Bob Edwards June 2022

IFDEF *BATCHFILE*
	FORGET *BATCHFILE*
}

pub *BATCHFILE* ." If word not found, load file of same name from SD card ver 2"
;

--- If word not found in dictionary, attempt to load SD card source code file of same name
--- e.g. TEST would attempt to load TEST then TEST.FTH then TEST.TXT from SD card
--- To turn feature on use ON BATCH , to turn off OFF BATCH
--- Supports nested files, so an unknown word within a file will trigger the load of
--- another file of the same name. When that is all loaded, the parent file continues
--- to load. Useful to include libraries of files in source code

--- leftmost len chars of str - destructive, uses same string
pub LEFT$ ( str len -- str )
OVER+ C~
;

--- Push 3 params to L stack to remember input stream settings
pri BFPUSH	( -- )
	filesect @ >L
	_fread @ >L
	ukey W@ >L
;

--- Pop 3 params from L stack to restore input stream settings
pri BFPOP	( -- )
	L> ukey W!
	L> _fread !
	L> filesect !
;

--- load file as console input then restore on zero (0) char that marks file end to previous input setting
pub FLOADSS ( sector -- ) 				
	OPEN-SECTOR							--- set the starting sector for file access
	KEY:								--- redirect (using ukey) all character input to the code that follows
pub FGETS ( -- ch ) 					--- Read the next byte from the file
	_fread @							--- fetch the file read pointer
	SDC@								--- fetch char from SD virtual memory in current file
	DUP
	IF									--- if the 0 end-of-file hasn't been reached
		_fread ++						--- increment the file pointer
		EXIT							--- Exit word now - pops return stack into IP
	THEN
	BFPOP								--- Restore input stream settings
	;

13 bytes SFILE							--- source file on SD card

--- search for unknown word as file on SD card and load
--- files ending with no extension, .FTH or .TXT 
--- NB this word will not run directly from the terminal
pub SDEXEC	( -- TRUE | FALSE )
	@WORD SFILE $!						--- save unknown word
	BFPUSH								--- save current input stream settings
	SFILE FOPEN$						--- attempt to open the file
	DUP 
	IF
		FLOADSS TRUE					--- load file with no extension if it exists
	ELSE
		DROP
		" .FTH" SFILE $+!
		SFILE FOPEN$
		DUP 
		IF
			FLOADSS TRUE				--- else load file ending in .TXT
		ELSE
			DROP
			SFILE DUP LEN$ 3 - LEFT$	--- remove FTH from the filename
			" TXT" SWAP $+!				--- and add TXT
			SFILE FOPEN$
			DUP
			IF
				FLOADSS TRUE			--- else loads file ending in .FTH
			ELSE
				DROP FALSE				--- no file found, signal failure
			THEN
		THEN
	THEN
;

--- enable / disable unknown word search on SD card
pub BATCH	( ON | OFF -- )	
	IF
		' SDEXEC unum W!				--- if unknown word, attempt execute from SD card
	ELSE
		0 unum W!						--- else return normal operation
	THEN
;

