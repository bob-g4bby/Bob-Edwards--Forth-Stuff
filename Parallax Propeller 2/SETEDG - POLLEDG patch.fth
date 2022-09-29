--- SETEDG and POLLEDG use setse1, but this is already in use by the terminal input
--- this patch redefines the two words to use setse2 and pollse2
--- Bob Edwards May 2021

--- useful edge definitions
1 := rising
2 := falling
3 := changing

--- sets event for 'edge' = rising, falling, changing, on SmartPin 'pin'
--- original SETEDG used se1 which is already used in the serial port 
code SETEDG		( edge pin -- )
	shl     b,#6
	add     a,b
	setse2  a
	2DROP;
end
--- e.g. use as 'rising 6 SETEDG' etc

--- redefinition of POLLEDG - polls for the SETEDG event
--- flag = TRUE if event occurred, else flag = FALSE 
code POLLEDG	( -- flag )
			>PUSHX
			pollse2 wc
			wrnc a
	_ret_ 	sub a,#1
end

