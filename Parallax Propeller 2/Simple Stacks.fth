--- Adding simple stacks to TAQOZ RELOADED v2.8 - adapted from code found at
--- httpspub//rosettacode.org/wiki/Stack#Forth by Bob Edwards Aug 2022
--- No bounds checking

IFDEF *STACKS*
	FORGET *STACKS*
}
pub *STACKS* ." Simple Stacks version 1 for Taqoz Reloaded v2.8" ;

--- words missing from Taqoz

4 := cell

cell NEGATE := -cell

pub CELL+
	cell +
;

pub CELLS
	cell *
;



--- Stack words

pre STACK ( size -- )
  [C] CREATE:				--- make a new dictionary entry using the name of the stack	
  HERE CELL+ [C] ,			--- initialise the stack pointer as an empty stack 
  CELLS ALLOT				--- allocate the storage space for the stack
; 
 
pub PUSH ( n st -- )
	SWAP OVER				( st n st -- )
	@						--- read the stack pointer ( st n -- )
	!						--- store n on the top of stack ( st  -- )
	cell SWAP +!			--- and increment the stack pointer
;

pub POP ( st -- n ) 
	-cell OVER +!			--- decrement the stack pointer ( st -- )
	@						--- read the stack pointer
	@						--- read the value top of stack
;

pub TOS@	( -- tos_copy )
	@ cell - @				--- read a copy of the top of stack
;

pub EMPTY? ( st -- flag )	--- returns flag=true if stack is empty	
	DUP @ - CELL+ 0=
;
--- End of Stack words 


--- Test words
 
10 STACK ST
 
1 ST PUSH
2 ST PUSH
3 ST PUSH

ST TOS@ CRLF .					--- 3
ST EMPTY? CRLF .  				--- 0 (false)
ST POP CRLF . 
ST POP CRLF . 
ST POP CRLF .  					--- 3 2 1
ST EMPTY? CRLF .  				--- -1 (true)

