--- Mini-OOF ver 6 - adapted for TAQOZ Reloaded v2.8 by Bob Edwards July 2022
--- Use only when a more elegant non-OOF solution can't be found
--- Mini-OOF was originally written by Bernd Paysan 1998 
--- see https://bernd-paysan.de/mini-oof.html for more details


IFDEF *MINI-OOF*
	FORGET *MINI-OOF*
}
pub *MINI-OOF* ." Mini object oriented forth version 6 for Taqoz Reloaded v2.8" ;

pub CREATE	( -- )
	[C] GRAB
	[C] CREATE:             			--- Using the next word in the input stream as the name, create a VARIABLE type dictionary entry
    [C] GRAB               				--- make sure CREATE: has run before anything more
    HERE 2- 0 REG W!	    			--- save the address of the code after DOES> in the REG scratchpad area
;
										--- set new cfa to point back to DOES: code (skipped by DOES: itself)
pub DOES>	( -- )
    R>                     				--- the first word location in the new word being defined
    0 REG W@               				--- retrieve the address stored on scratchpad
    W!                      			--- set the first word to execute as the address of the code after DOES>
;

--- remove the first n bytes / chars from the string at addr1
pub /STRING ( addr1 cnt1 n -- addr2 cnt2 )
  DUP >R -								--- reduce cnt1
  SWAP R> +								--- increase start address
  SWAP									--- cleanup
 ;

--- this 'do nothing' action is loaded into the CLASS vtable for all methods to start with
' NOP := 'NOP

2 := INSTR								--- one TAQOZ instruction is two bytes
pub INSTRS INSTR * ;	( n -- 2*n )	---	compute the number of bytes for n instructions 
pub INSTR+ INSTR + ;	( n -- n+2 )	--- increment n by one instructions worth of bytes in hub ram

--- Start a CLASS definition
pub CLASS ( class -- class methods varis )
  DUP W@ OVER INSTR+ W@	SWAP			--- copy methods and instvars to the stack 
;

--- All classes are based on this skeleton class
CREATE: OBJECT 1 INSTRS || 2 INSTRS ||

--- declare a method within a class definition / run the method on a specific object
pre METHOD 
	CREATE ( m v -- m' v )
		OVER [C] || SWAP INSTR+ SWAP	--- compile m, then m' = m + cell			
	DOES> ( ... O -- ... )
		DUP W@							--- vtable address read from 1st word in object
		R> W@							--- read this methods offset number
		+								--- this is reqd address in the vtable
		W@								--- read the address of the method's code
		JUMP							--- and run the method
;

--- declare a variable within a class definition / return the variable address in an object
pre VARI  
	CREATE ( m v size -- )				--- size - in bytes
		OVER [C] || +
	DOES> ( o -- addr ) 
		R> W@ +							--- read the VARIs offset and add that to the object address
;

--- close the class definition
pre END-CLASS  ( CLASS methods varis "name" -- )
	[C] GRAB
	[C] CREATE:							--- create the class entry in the dict. with the name that follows
	[C] GRAB
	HERE >R								--- remember the current compilation address - contains VARtotalspace
	[C] || DUP [C] ||					--- compile VARtotalspace, then METHODtotalspace ( CLASS METHODtotalspace -- )
	2 INSTRs
	2DUP <> IF							--- If the new class defines any methods
		DO
			'NOP [C] ||					--- compile a temporary NOP for each method defined
		INSTR +LOOP						( CLASS -- )
    ELSE
		2DROP
	THEN								( CLASS -- )
	INSTR+ DUP INSTR+ R>				( CLASS+2 CLASS+4 HERE -- )
	ROT									( CLASS+4 HERE CLASS+2 -- )
	W@									( CLASS+4 HERE METHODbytescnt -- )
	2 INSTRS							( CLASS+4 HERE METHODbytescnt 4 -- )
	2DUP <> IF							--- if parent class has any methods
		/STRING							--- exclude the varis or methods byte cnts
		CMOVE	 						--- copy across the XTs from the parent class
	ELSE
		2DROP 2DROP
	THEN
;

--- assigns a word to one of the method "names" within a class, replacing the 'do nothing' placeholder
pre DEFINES ( xtanon class 'methodname" -- )
  [C] '									--- find xt of the method whose word follows in the input stream
  [G]									--- ( xtanon class pointertooffset )
  2+									--- point to the method offset value ( xt class methodoffset+2 )
  W@									--- read the method offset ( xt class methodnumber )
  + 									--- add the offset to the vtable start address
  W!									--- store the new method at that offset
;

--- create a new object of a class
pub NEW ( class -- o )
  HERE									--- ( class here ) get address of next compilation location
  OVER W@ 								--- ( class here objsize ) read the required size of the new object from the vtable
  2 ALIGN								--- ( class here objsize' ) ALLOT only takes even numbers
  ALLOT 								--- ( class here ) allocate that in code space
  SWAP									--- ( here class )
  OVER W!								--- ( here ) save the address of the vtable at the start of the object
;

--- Read a method address, given the class and method name
pre :: ( class "methodname" -- adr )
  [C] '									--- find xt of the method whose word follows in the input stream
  [G]									--- ( xtanon class pointertooffset )
  2+									--- point to the method offset value ( xt class methodoffset+2 )
  W@									--- read the method offset ( xt class methodnumber )
  +										--- add the offset to the vtable start address
  W@									--- get the address of the required method							
 ;
 
 --- this is an 'early binding' method selection, as the addr is resolved during compilation
 --- Use: MYOBJECT MYCLASS :: MYMETHOD
 --- e.g. : TEST TIMER1 [ TIMER :: TPRINT GRAB ] [W] CRLF ;

--- Used to create an anonymous word - it is normal code, but has no dictionary entry
--- removes the dictionary entry of the last defined word - leaves it's code field address on the stack
pub ANON ( -- cfa ) 					--- Remove dictionary entry of last word defined, leaves xt of code on stack
	@WORDS								--- point to name of latest word in dictionary
	CPA									--- convert to it's code pointer address
	W@									--- reading the code field address, left on the stack
	@WORDS CPA 2+						--- now we're pointing to the name field address of the last but one word 
	names !								--- 'names' now points to last but one word in the dictionary
;										--- thus the name of the latest word is 'forgotten'


--- On entry to a method, Mini-OOF grammar places the 'current object' top of data stack
--- Mini-OOF expects the method to consume the 'current object' before it exits
--- BUT - having the 'current object' top of stack all the time is a nuisance
--- especially when accessing the data stack entries underneath
--- So, we dedicate the L stack to store the 'current object', so that methods can call other methods 
--- and the current object is saved and restored in a nested fashion
--- These three words utilise the L stack as the 'current object' stack

--- push the current object onto the L stack
pub WITH 	    ( obj -- )
    >L ;

--- read the current object
pub THIS		( -- obj )
	L> DUP >L
;

--- unnest the current object and discard
pub ENDWITH		( -- )
	L> DROP
;

--- End of Mini-OOF 
