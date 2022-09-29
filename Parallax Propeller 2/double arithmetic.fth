--- Double Arithmetic ver 3 for Taqoz Reloaded v2.8 by Bob Edwards Dec 2021

IFDEF *64bitMaths* FORGET *64bitMaths* }
pub *64bitMaths*		PRINT" Double length maths for TAQOZ ver 3" ;

TAQOZ


--- duplicate top 4 stack entries
: 4DUP	( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 n3 n4 )
	4 0 DO 4TH LOOP
;

--- flg=true if d1=d2 else flg=false
pub D=	( d1 d2 -- flg )
ROT = -ROT = + -2 =
;

--- cast signed long to signed double
pub L->D	( n -- d )
	DUP 0<
	;

--- multiply two signed doubles, result is signed double
pub D*	( d1 d2 -- d3 )
	>R SWAP >R
	2DUP UM* 2SWAP
	R> * SWAP R> * + +
	;

--- square signed double d2 = d1 squared
pub DSQR	( d1 -- d2 )
	2DUP D*
	;

--- d2 = absolute value of d1, flg = true if d1 was negative
pub DABS	( d1 -- d2 flg )
	DUP 0<
	IF
		-1 -1 D* 1
	ELSE
		0
	THEN
;

--- d2 = -d1
pub DNEGATE
	-1 -1 D*
;

--- if flg is true, d2 = -d1
pub ?DNEGATE	( d1 flg -- d2 )
	0<>
	IF
		DNEGATE
	THEN
;

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

--- logic shift double d1 left by 1 position
pub D<shift	( d1 -- d2 )
	SWAP				--- Dhigh Dlow
	DUP 0< >R			--- is top bit of Dlow set?
	2* SWAP 2*			--- Dlow*2 Dhigh*2
	R> IF				--- if carry over to high long is reqd
		1+				--- Dhigh + 1
	THEN
;

--- add signed doubles d3 = d1 + d2	
code D+	( d1 d2 -- d3 )
	add d,b wc
	addx c,a
	jmp #@2DROP
end

--- subtract signed doubles d3 = d1 - d2
code D-	( d1 d2 -- d3 )
	sub d,b wc
	subx c,a
	jmp #@2DROP 
end

--- left shift UD until the MS bit is 1, leftshifts is the number of shifts
pub UDNORMAL	( UD1 -- UD2 leftshifts )
0 >R								--- set up shift count
BEGIN
	DUP $80000000 AND 0=
WHILE
	D<shift  R> 1+ >R
REPEAT
R>
;

 --- create a 'double' type variable (64 bits )
pre double	( -- )
	8 [C] [G] [C] bytes [C] [G]
	;

private
double Quotient
double Remainder
double Divisor
public

--- quotient = d1 / d2 with remainder - all unsigned doubles
pri (UD/)	( dividend divisor -- remainder quotient )
		Divisor D!
		Quotient D!
		0. Remainder D!
		64 FOR
			Quotient D@  DUP 0< >R D<shift Quotient D!
			Remainder D@ D<shift R> IF 1. D+ THEN Remainder D!
			Remainder D@ Divisor D@ D-
			DUP $80000000 AND 0=
			IF
				Remainder D!
				Quotient D@ 1. D+ Quotient D!
			ELSE
				2DROP
			THEN
		NEXT
		Remainder D@
		Quotient D@
;

--- quotient = d1 / d2 with remainder - all unsigned doubles
pub UD/	( dividend divisor -- remainder quotient )
	DUP 0=
	IF							--- is divisor 32 bit or less?
		DROP UM// 0 -ROT
	ELSE
		(UD/)
	THEN
;

--- quotient = d1 / d2 with remainder - all signed doubles
pub D/	( dividend divisor -- remainder quotient )
	DABS 2* >R 2SWAP DABS R> + >R 2SWAP				--- convert d1 and d2 to +ve, remembering original signs
	UD/
	R> SWITCH										--- bit1 set if divisor was -ve, bit0 = true for dividend 
		1 CASE DNEGATE 2SWAP DNEGATE 2SWAP BREAK
		2 CASE DNEGATE BREAK
;

--- arithmetic shift signed double d1 right by n positions, result is d2
code D>>	( d1 n -- d2 )
.l1
	sar b,#1 wc
	rcr c,#1
	djnz a,#l1
	jmp #@DROP
end

{
--- test D>> function by shifting d repeatedly and displaying the result
pub D>>TEST		( d -- )
	CRLF
	64 1 DO
		2DUP I DUP . SPACE D>>
		SD. CRLF
	LOOP
	2DROP
;
}

--- arithmetic shift signed double d1 left by n positions, result is d2
code D<<	( d1 n -- d2 )
.l1
	shl c,#1 wc
	rcl b,#1
	djnz a,#l1
	jmp #@DROP
end

{
--- test D>> function by shifting d repeatedly and displaying the result
pub D<<TEST		( d -- )
	CRLF
	64 1 DO
		2DUP I DUP . SPACE D<<
		SD. CRLF
	LOOP
	2DROP
;
}

END
