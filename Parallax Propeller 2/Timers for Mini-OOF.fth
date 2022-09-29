--- Periodic Timers using Mini-OOF ver 3 by Bob Edwards July 2022
--- this code allows multiple words to execute periodically, all with different time periods, 
--- on one cog.
--- Run MAIN for a demo, which terminates on any key being pressed 

IFDEF *TIMERS*
	FORGET *TIMERS*
}
pub *TIMERS* ." Timers version 3 for Taqoz Reloaded v2.8" ;

--- TIMER class definition
OBJECT CLASS
	4 VARI STARTTIME
	4 VARI PERIOD
	2 VARI TCODE
	METHOD TSET
	METHOD TRUN
	METHOD TPRINT
END-CLASS TIMER

pub noname 
	WITH 
		THIS PERIOD !								--- save the reqd period in ms
		THIS TCODE W!								--- save the cfa of the word that will run periodically
		GETMS THIS STARTTIME !						--- save the current time since reset
	ENDWITH
; ANON TIMER DEFINES TSET	( codetorun period -- ) --- initialises the TIMER

pub noname
	WITH
		GETMS DUP									--- read the present time
		THIS STARTTIME @							--- read when this TIMER last ran
		-											--- calculate how long ago that is 
		THIS PERIOD @ =>							--- is it time to run the TCODE?
		IF
			THIS STARTTIME !						--- save the present time
			THIS TCODE W@ EXECUTE					--- run cfa stored in TCODE
		ELSE
			DROP									--- else forget the present time
		THEN
	ENDWITH
; ANON TIMER DEFINES TRUN	( -- )					--- run TCODE every PERIOD ms

pub noname
	WITH
		CRLF
		." STARTTIME = " THIS STARTTIME @ . CRLF
		." PERIOD = " THIS PERIOD @ . CRLF
		." TCODE = " THIS TCODE W@ . CRLF
	ENDWITH
; ANON TIMER DEFINES TPRINT	( -- )					--- print timer variables for debug
--- end of TIMER class definition

--- Example application
TIMER NEW := TIMER1
TIMER NEW := TIMER2
TIMER NEW := TIMER3

pub HELLO1 ." Hi from HELLO1" CRLF ;
pub HELLO2 ." HELLO2 here !" CRLF ;
pub HELLO3 ." Watcha there from HELLO3" CRLF ;

--- Print all timer variables
pub .VARIS	( -- )
	CRLF ." The current state of the object variables is ..." 
	CRLF CRLF ." Timer1" CRLF
	TIMER1 TPRINT
	CRLF ." Timer2" CRLF
	TIMER2 TPRINT
	CRLF ." Timer3" CRLF
	TIMER3 TPRINT
;

--- An example of the 'early binding' method call ( the methods' addr is resolved during compilation )
--- e.g. : TEST TIMER1 [ TIMER :: TPRINT GRAB ] [W] CRLF ;

--- So .VARIS could be rewritten as:-
{
pub .VARIS1
	CRLF ." The current state of the object variables is ..."
	CRLF CRLF ." Timer1" CRLF
	TIMER1 [ TIMER :: TPRINT GRAB ] [W]
	CRLF ." Timer2" CRLF
	TIMER2 [ TIMER :: TPRINT GRAB ] [W]
	CRLF ." Timer3" CRLF
	TIMER3 [ TIMER :: TPRINT GRAB ] [W]
;
}

--- One example of where early binding is useful is in calling a parent method instead of the
--- current method

--- Demo that runs three timers on one cog and halts after any key press
pub MAIN	( -- )									--- demo runs until a key is pressed
	CRLF
	' HELLO1 2000 TIMER1 TSET
	' HELLO2 450 TIMER2 TSET
	' HELLO3 3500 TIMER3 TSET
	0
	BEGIN
		1+
		TIMER1 TRUN
		TIMER2 TRUN
		TIMER3 TRUN
	KEY UNTIL
	CRLF ." The three timers were run a total of " . ." times" CRLF
	.VARIS
;

