--- Straight line algorithm for Tachyon 5v7
--- Useful for anywhere where a bunch of numbers have to change in fixed non-integer ratios to arrive simultaneously at a target
--- e.g. vector graphics, multi-stepper control, sound synthesis, lighting faders
--- This version keeps a down counter on the stack to tell when the line is done

PUBLIC
3  := AXES		--- number of axes to run
AXES 4* := AXESL	--- byte loop count for the arrays of longs
AXES longs POSN		--- Start and present position array
AXES longs GOAL		--- the target array
AXES longs ACC		--- axis accumulator
AXES longs INCR		--- value to be added to POSN on each step (1 or -1)

PRIVATE
AXES longs DELTA	--- set to GOAL minus initial POSN
long TBASE		--- timebase, set from the biggest DELTA



--- inc or dec the I'th member of POSN, by adding I'th member of INCR
pri STEPPOSN ( -- )
POSN I 4* + DUP @
INCR I 4* + @
+ SWAP !
;


--- initialise DELTA and INCR
pri !DELTA&INCR	( -- )
AXES FOR
	I 4* >R
	GOAL R@ + @
	POSN R@ + @
	- DUP 0<
	INCR I 4* + >R		--- INCR = -1 if GOAL<POSN, else = 1
	IF -1 ELSE 1 THEN
	R> ! 
	ABS DELTA R> + !	--- DELTA = |GOAL - POSN| 
     NEXT
;

--- TBASE set to the largest DELTA
pri !TBASE	( --  )
0 AXES
FOR
	DELTA I 4* + @ MAX
NEXT
TBASE !
;

--- initialise straight line engine for new line
pub !SLINIT	( starts goals -- stepcount )
ACC AXESL 0 FILL	--- zero the accumulators
GOAL AXESL CMOVE	--- set the target position
POSN AXESL CMOVE	--- set the starting position
!DELTA&INCR		--- calculate all goals minus starts and set up directions
!TBASE			--- TBASE set to the largest DELTA
TBASE @ 1+		--- A stepcount left on stack. ready for SLSTEP to decrement
;

--- step one place along the 'straight line', POSN is set to new position
--- flg returned true if arrived at GOAL, else false
pub SLSTEP	( stepcount -- stepcount )
AXES FOR
	ACC I 4* + DUP @
	DELTA I 4* + @ ABS +
	DUP
	TBASE @ >
	IF			--- if ACC[I[ is > than TBASE, then time to step POSN[I] on 
		TBASE @ -
		POSN I 4* + DUP @
		INCR I 4* + @
		+ SWAP !	--- POSN[I]=POSN[I]+INCR[I]	
	THEN
	SWAP !			--- and save new ACC[I] value 		 	
     NEXT
1-				--- decrement the stepcount
;

--- Test words

TABLE MYSTART -15 , 10 , 13 ,	--- test start values
TABLE MYGOAL 15 , 21 , -7 ,	--- test goal values


--- print AXES size array of longs
pub .ARR ( adr -- )
AXES FOR
	DUP I 4* + @ . SPACE
     NEXT
     DROP
;

--- Print all variables
pub .SL	( -- )
CR
." POSN    = " POSN .ARR CR
." GOAL    = " GOAL .ARR CR
." DELTA   = " DELTA .ARR CR
." INCR    = " INCR .ARR CR
." TBASE   = " TBASE @. CR
;

--- demo that straight line alg. works
pub SLDEMO	( -- )
." STRAIGHT LINE DEMO" CR
MYSTART MYGOAL !SLINIT		--- initialise straight line engine ( -- loopcount )
.SL CR
." POSN steps by coordinates ..." CR
BEGIN
	SLSTEP			( -- loopcount )
	POSN .ARR CR		( -- loopcount )
	?DUP 0=
UNTIL
." End of straight line" CR	( -- )
;

--- time the demo, so no printing in the loop
pub SLTIME	( -- )
MYSTART MYGOAL !SLINIT		--- initialise straight line engine
." STRAIGHT LINE TIMING DEMO" CR
.SL CR
LAP
BEGIN
	SLSTEP			( -- loopcount )
	?DUP 0=
UNTIL
LAP
TBASE @ . ." Steps in " AXES . ."  Axes took" CR
.LAP CR
." End of straight line" CR
;
So this takes 71% of the time of the