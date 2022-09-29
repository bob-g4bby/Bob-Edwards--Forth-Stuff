--- Some useful Tachyon string functions, adapted for TAQOZ v2.8 - Bob Edwards Mar 2022
	
--- Locate the addr of the first instance of ch in the string str and return that, else null
pub LOCATE$	( ch str -- str | 0 )
	TRUE >L
	DUP LEN$		--- chr str count
	ADO
		DUP IC@ =
		IF
			DROP I
			L> DROP FALSE >L
			LEAVE
		THEN
	LOOP
	L>
	IF
		DROP 0
	THEN
	;

--- append str1 at the end of str2
pub APPEND$ ( str1 str2 -- )		DUP LEN$ + $! ;

--- add a character to a string
pub +CHAR ( ch str -- )		DUP LEN$ + OVER 1+ C~ C! ;

--- give a copy of the rightmost len chars of str
pub RIGHT$ ( str1 len -- str2 )		OVER LEN$ SWAP - + ;

--- Extract the substring of str starting at offset len chars long
pub MID$ ( str1 offset len -- str2 )	-ROT + SWAP

--- leftmost len chars of str - destructive, uses same string
pub LEFT$ ( str len -- str )		OVER+ C~ ;

{
--- Some test strings

20 bytes mystring
" Hello" mystring $!
5 bytes name
" Bob" name $!
}

