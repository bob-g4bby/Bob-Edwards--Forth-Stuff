--- print a signed double
pub SD.	( d -- )
	DUP 0< IF
		SWAP
		-1 XOR 1+ DUP 0= >R
		SWAP
		-1 XOR R> IF 1+ THEN
		45 EMIT
	THEN
	D.										--- then print the absolute value
	;

--- convert unsigned long to unsigned double
pub S->D
	0
;

--- subtract signed doubles d3 = d1 - d2
code D-	( d1 d2 -- d3 )
	sub d,b wc
	subx c,a
	jmp #@2DROP 
end

--- flg = true if d1 < d2
pub D<	( d1 d2 -- flg )
	D- SWAP DROP 0< 
;

--- multiply two signed doubles, result is signed double
pub D*	( d1 d2 -- d3 )
	>R SWAP >R
	2DUP UM* 2SWAP
	R> * SWAP R> * + +
;

--- d2 = absolute value of d1
pub DABS	( d1 -- d2 )
	DUP 0<
	IF
		-1 -1 D*
	THEN
;

--- d2 = -d1
pub DNEGATE	( d1 -- d2 )
	-1 -1 D*
;

--- dquot = d1/u, drem = the remainder converted to a double
pub DM/MOD	( d1 u -- drem dquot )
	UM//					--- do the division
	0 -ROT					--- convert remainder to a double
;

--- dquot = d1 / d2, with drem remainder, all signed doubles
pub D/	( d1 d2 -- drem dquot )
	2DUP 0 0 D<							--- is d2 < 0 ?
	>R									--- save that question for later
	2DUP DABS SWAP DROP					--- is d2 > 2^32 ?
	IF									--- yes, d2 > 2^32 
		>R DUP R>						--- was d2 -ve ?
		IF								--- yes, d2 was -ve
			>R >R DNEGATE R> R> DNEGATE --- negate both d1 and d2
		THEN
		SWAP >R U// R> SWAP >R
		0 R> DUP >R S->D D* D- R> S->D
	ELSE								--- no, d2 < 2^32
		>R DUP R>
		IF
			>R >R DNEGATE R> R>
		THEN
		DROP ABS DM/MOD
	THEN
	R>
	IF
		>R >R DNEGATE R> R>
	THEN
;
