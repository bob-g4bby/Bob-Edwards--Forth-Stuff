--- State machine class using Mini-OOF ver 3 for Taqoz Reloaded v2.8 - Bob Edwards April 2022
--- N.B. Requires Mini-OOF to be loaded before loading this code
--- https://forums.parallax.com/discussion/174520/taqoz-reloaded-v2-8-mini-oof-object-oriented-programming-revisited

IFDEF *StateMC*
	FORGET *StateMC*
}
pub *StateMC* ." State machine using Mini-OOF ver 3" ;

--- Word to create a prototype state - it's just a constant set to 0 for now 
--- later set to point to some code. So 0 indicates an unassigned or 'idle' state
pre STATE
	0 [C] [G] [C] := [C] [G]
;

--- State machine class SM
--- This is just a 'program counter' and 'word launcher' - not a complete state machine
OBJECT CLASS
	2 VARI NEXTSTATE
	METHOD SMGOTO
	METHOD SMSTEP
END-CLASS SM

--- save state in the state machine 'progam counter'
pri NEXTSTATE!				( state -- )
	THIS NEXTSTATE W!
;

--- read the state machine 'program counter'
pri NEXTSTATE@				( -- state )
	THIS NEXTSTATE W@
;

--- Jump to 'state' - no need to return
pri noname					( state -- )
	WITH
		NEXTSTATE!
	ENDWITH
; ANON SM DEFINES SMGOTO

--- Execute one state in the state machine
pri noname
	WITH
		NEXTSTATE@
		?DUP IF EXECUTE THEN	--- if the state has been assigned code, execute it
	ENDWITH
; ANON SM DEFINES SMSTEP

--- End of class SM


--- We need some states for a state machine engine based on SM to work with so here they are
STATE STATE1
STATE STATE2
STATE STATE3

--- STATE1 to STATE3 need to do stuff, so we define that here
--- The start address of an anonymous word is stored in each STATE
--- For demo, each state displays it's identity and sets NEXTSTATE up for the next step
--- The states are set to run STATE1 -> STATE2 -> STATE3 -> STATE1 -> STATE2 ....
--- N.B. Each state must leave the data and return stack as it found them
pub noname 
	." State 1 "
	STATE2 NEXTSTATE!			--- STATE1 unconditionally sets STATE2 to run next
; ANON ' STATE1 :=!
pub noname
	." State 2 "
	STATE3 NEXTSTATE!			--- STATE2 unconditionally sets STATE3 to run next
; ANON ' STATE2 :=!
pub noname
	." State 3 "
	STATE1 NEXTSTATE!			--- STATE3 unconditionally sets STATE1 to run next
; ANON ' STATE3 :=!

--- End of state definitions 



--- this small demo runs SM1 starting at STATE3, SM2 starting at STATE1, SM3 starting at STATE2
public

SM NEW := SM1
SM NEW := SM2
SM NEW := SM3

pub MAIN						( -- )
	STATE3 SM1 SMGOTO			--- We initialise SM1 to start at STATE3 
	STATE1 SM2 SMGOTO			--- and SM2 to start at STATE1
	STATE2 SM3 SMGOTO
	BEGIN
		CRLF ." SM1 "
		SM1 SMSTEP				--- execute one state of SM1
		100 ms					--- slow things down for demo
		CRLF ." SM2 "
		SM2 SMSTEP				--- execute one step of SM2
		100 ms					--- slow things down for demo and loop until
		CRLF ." SM3 "
		SM3 SMSTEP				--- execute one step of SM3
		100 ms					--- slow things down for demo and loop until
		KEY						--- the user presses a key
	UNTIL
;


