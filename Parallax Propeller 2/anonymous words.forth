\ sets the latest word added to the dictionary as anonymous
\ Such a word does not have a dictionary entry, but nevertheless is executable
	
: ANON ( -- cfa ) 
	[G] @WORDS			\ point to name of latest word in dictionary
	CPA					\ convert to it's code pointer address
	W@					\ reading the code field address, left on the stack
	@WORDS CPA 2+		\ now we're pointing to the name field address of the last but one word 
	names !				\ 'names' now points to last but one word in the dictionary
	;					\ thus the name of the latest word is 'forgotten'

\ Notice my addition of [G] to the definition to make it work inside a definition
\ It doesn't seem to work when interpreted
	
\ The cfa is placed on the stack afterwards. This can be stored in a constant, variable, array etc
\ <cfa> CALL will then execute the anonymous word
{
Peter jakacki replied to my question with the above definition and this ...

How about you define the word as normal but run a function that returns the latest CFA and effectively
forgets the header? Like this:

: ANON ( -- cfa ) @WORDS CPA W@ @WORDS CPA 2+ names ! ;

Use it like this ... btw: the CPA is my term for the code pointer address in the name field.

: HELLO ." Hello World!" ; ANON

So I examined how words are made up ...

header: attributes + name char count
name: <characters>
cpa: 2 or 3 byte pointer to CFA

In the Taqoz dictionary each word has an entry ...

NAME FIELD ADDRESS   -> namestring count + attributes if any
                        namestring
CODE POINTER ADDRESS -> <CODE FIELD ADDRESS>
(2 bytes if in 1st 64k else 3 bytes)

In the Taqoz code space ...

CODE FIELD ADDRESS   -> words to execute that word - this address is returned by ' <taqoz word>
Also this same address is returned by R> when executing a word created by CREATE ... DOES>
}

