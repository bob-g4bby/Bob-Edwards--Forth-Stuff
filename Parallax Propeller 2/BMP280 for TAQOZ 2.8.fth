--- BMP280 air pressure / temperature driver for TAQOZ 2.8
--- Version 1
--- N.B. requires the assembler loaded as part of the forth tool set

ALIAS I2C.START <I2C

--- cast signed word to signed long
pub W>SL	( word -- signedlong )
	DUP 32767 >
	IF
		65563 -
	THEN
	;

--- signed double maths 

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
pub UD/MOD	( dividend divisor -- remainder quotient )
	DUP 0=
	IF							--- is divisor 32 bit or less?
		DROP UM// 0 -ROT
	ELSE
		(UD/)
	THEN
;

--- quotient = d1 / d2 with remainder - all signed doubles
pub D/MOD	( dividend divisor -- remainder quotient )
	DABS 2* >R 2SWAP DABS R> + >R 2SWAP				--- convert d1 and d2 to +ve, remembering original signs
	UD/MOD
	R> SWITCH										--- bit1 set if divisor was -ve, bit0 = true for dividend 
		1 CASE DNEGATE 2SWAP DNEGATE 2SWAP BREAK
		2 CASE DNEGATE BREAK
;

--- quotient = d1 / d2 - all signed doubles
pub D/	( dividend divisor -- quotient )
	D/MOD 2SWAP 2DROP
;


--- BMP280 driver
	
$EC := i2cadr								--- set the BMP280 chip address
3   := t_sb									--- time between readings 0 fastest 7 slowest 

--- variables
double var1
double var2
double calpress
long rawpress
long dig_T1
long dig_T2
long dig_T3
long dig_P1
long dig_P2
long dig_P3
long dig_P4
long dig_P5
long dig_P6
long dig_P7
long dig_P8
long dig_P9
long rawtemp
long calibtemp
long t_fine

--- Read byte at i2c register adr
pri I2CREAD ( adr -- byte )
	<I2C i2cadr I2C! I2C!					--- select the register at 'addr' 
	<I2C i2cadr 1+ I2C! nakI2C@ I2C>		--- read the contents
	;
	
--- Write byte to i2c register adr
pri I2CWRITE ( byte adr -- )
	<I2C i2cadr I2C! I2C! I2C! I2C>
	;

--- TEMPERATURE MEASUREMENT

--- Read the temperature factory calibration constants
pub READtempcal ( -- )
	$88 I2CREAD
	$89 I2CREAD 8 << OR
	dig_T1 !
	$8A I2CREAD
	$8B I2CREAD 8 << OR W>SL
	dig_T2 !
	$8C I2CREAD
	$8D I2CREAD 8 << OR W>SL
	dig_T3 !
	;

--- read 'measuring' in bit 3 and 'im_update' in bit 0
pub READstatus ( -- status )
	$F3 I2CREAD
	;

--- Wait until measurement is complete
pub MEASUREWAIT ( -- )
	BEGIN
		READstatus
		8 AND 0=
	UNTIL
	BEGIN
		READstatus
		8 AND 8 =
	UNTIL
	;

--- set up the BMP280 configuration to do one measurement per second 
pub SETUP
	t_sb 5 <<   
	$F5 I2CWRITE
	5 5 <<			--- oversampling for temperature
	5 2 << OR		--- oversampling for pressure
	3 OR			--- power mode set to continuous measurement
	$F4 I2CWRITE
	;

--- display the three temperature factory calibration constants
pub tempcal.	( -- )
	READtempcal
	CRLF
	." dig_T1=" dig_T1 @ . CRLF
	." dig_T2=" dig_T2 @ . CRLF
	." dig_T3=" dig_T3 @ . CRLF
	;

--- read the raw temperature, save in rawtemp
pub READtemp	( -- )
	$FA I2CREAD 16 <<
	$FB I2CREAD 8 << OR
	$FC I2CREAD OR 4 >>
	rawtemp !
	;

--- read rawtemp and calculate true temp, save in calibtemp
--- shifts << or >> are not used as they don't work with signed longs
pub CALCtemp	( -- )
		rawtemp @ 8 /
		dig_T1 @ 2 * -
		dig_T2 @ *
		2048 /
		var1 !
		rawtemp @ 16 /
		dig_T1 @ -
		DUP * 4096 /
		dig_T3 @ *
		16384 /
		var2 !
		var1 @ var2 @ +
		DUP t_fine !
		5 * 128 +
		256 /
		calibtemp !
	;

--- display the raw and calibrated temperature until a key is pressed	
pub READtemp.	( -- )
	CRLF
	READtempcal
	SETUP
	BEGIN
		MEASUREWAIT
		READtemp 
		." Raw temperature value =  " rawtemp @ . SPACE
		CALCtemp
		." Calibrated temperature value = " calibtemp @ <# # # 46 HOLD #S #> PRINT$ CRLF
	KEY UNTIL
	;

--- PRESSURE MEASUREMENT

--- read the raw pressure, save in rawpress
pub READpress	( -- )
	$F7 I2CREAD 16 <<
	$F8 I2CREAD 8 << OR
	$F9 I2CREAD OR 4 >>
	rawpress !
	;

--- Read the pressure factory calibration constants
pub READpresscal ( -- )
	$8E I2CREAD
	$8F I2CREAD 8 << OR
	dig_P1 !
	$90 I2CREAD
	$91 I2CREAD 8 << OR W>SL
	dig_P2 !
	$92 I2CREAD
	$93 I2CREAD 8 << OR W>SL
	dig_P3 !
	$94 I2CREAD
	$95 I2CREAD 8 << OR W>SL
	dig_P4 !
	$96 I2CREAD
	$97 I2CREAD 8 << OR W>SL
	dig_P5 !
	$98 I2CREAD
	$99 I2CREAD 8 << OR W>SL
	dig_P6 !
	$9A I2CREAD
	$9B I2CREAD 8 << OR W>SL
	dig_P7 !
	$9C I2CREAD
	$9D I2CREAD 8 << OR W>SL
	dig_P8 !
	$9E I2CREAD
	$9F I2CREAD 8 << OR W>SL
	dig_P9 !
	;

--- display the pressure calibration constants
pub presscal.	( -- )
READpresscal
	CRLF
	." DIG_p1=" dig_P1 @ . CRLF
	." DIG_p2=" dig_P2 @ . CRLF
	." DIG_p3=" dig_P3 @ . CRLF
	." DIG_p4=" dig_P4 @ . CRLF
	." DIG_p5=" dig_P5 @ . CRLF
	." DIG_p6=" dig_P6 @ . CRLF
	." DIG_p7=" dig_P7 @ . CRLF
	." DIG_p8=" dig_P8 @ . CRLF
	." DIG_p9=" dig_P9 @ . CRLF
;

--- set calibrations to test values for conversion calculation check as per page 23 of the DMP280 datasheet
pub testcalset	( -- )
	27504	dig_T1 !
	26435	dig_T2 !
	-1000	dig_T3 !
	36477	dig_P1 !
	-10685	dig_P2 !
	3024	dig_P3 !
	2855	dig_P4 !
	140		dig_P5 !
	-7		dig_P6 !
	15500	dig_P7 !
	-14600	dig_P8 !
	6000	dig_P9 !
	519888	rawtemp !
	415148	rawpress !
;

--- convert rawpress to calpress, the true pressure in pascals
pub CALCpress	( -- )
	t_fine @ 2 / 64000 - var1 !														--- var1 = ((t_fine)>>1) – 64000;
	var1 @ 4 / DUP * 2048 / dig_P6 @ * var2 !										--- var2 = (((var1>>2) * (var1>>2)) >> 11 ) * (dig_P6);
	var1 @ dig_P5 @ * 2 * var2 @ + var2 !											--- var2 = var2 + ((var1*(dig_P5))<<1);
	var2 @ 4 / dig_P4 65536 * + var2 !												--- var2 = (var2>>2)+((dig_P4)<<16);
	var1 @ 4 / DUP * 8192 / dig_P3 @ * 8 / dig_P2 @ var1 @ * 2 / + 262144 / var1 !	--- var1 = (((dig_P3 * (((var1>>2) * (var1>>2)) >> 13 )) >> 3) + (((dig_P2) * var1)>>1))>>18;
	var1 @ 32768 + dig_P1 @ * 32768 / var1 !										--- var1 =((((32768+var1))*(dig_P1))>>15);
	var1 @ 0=
	IF
		0 calpress !
	ELSE
		1048576 rawpress @ - var2 @ 4096 / - 3125 * calpress !						--- p = ((((1048576)-adc_P)-(var2>>12)))*3125;
		calpress @ $80000000 <
		IF
			calpress @ 2 / var1 @ / calpress !										--- p = (p << 1) / (var1);
		ELSE
			calpress @ var1 @ / 2 * calpress !										--- p = (p / var1) * 2;
		THEN
		calpress @ 8 / DUP * 8192 / dig_P9 @ * 4096 / var1 !						--- var1 = ((dig_P9) * ((((p>>3) * (p>>3))>>13)))>>12;
		calpress @ 4 / dig_P8 @ * 8192 / var2 !										--- var2 = (((p>>2)) * (dig_P8))>>13;
		var1 @ var2 @ + dig_P7 @ + 8 / calpress @ + calpress !						--- p = (p + ((var1 + var2 + dig_P7) >> 4));
	THEN
	;


--- convert rawpress to calpress using mixture of 32 and 64 bit arithmetic as per page 22 of the BMP280 datasheet
pub	CALCpress1	( --  )
	t_fine @ L->D 128000. D- var1 D!													--- var1 = ((BMP280_S64_t)t_fine) – 128000;
	." 1 var1 =  " var1 D@ SD. CRLF
	var1 D@ DSQR dig_P6 @ L->D D* var2 D!												--- var2 = var1 * var1 * (BMP280_S64_t)dig_P6;
	." 2 var2 =  " var2 D@ SD. CRLF
	var1 D@ dig_P5 @ L->D D* 131072. D* var2 D@ D+ var2 D!								--- var2 = var2 + ((var1*(BMP280_S64_t)dig_P5)<<17);
	." 3 var2 =  " var2 D@ SD. CRLF
	dig_P4 @ L->D 34359738368. D* var2 D@ D+ var2 D!									--- var2 = var2 + (((BMP280_S64_t)dig_P4)<<35);
	." 4 var2 =  " var2 D@ SD. CRLF
	var1 D@ DSQR dig_P3 @ L->D D* 256. D/ var1 D@ dig_P2 @ L->D D* 4096. D* D+ var1 D!	--- var1 = ((var1 * var1 * (BMP280_S64_t)dig_P3)>>8) + ((var1 * (BMP280_S64_t)dig_P2)<<12);
	." 5 var1 =  " var1 D@ SD. CRLF
	$800000000000. var1 D@ D+ dig_P1 @ L->D D* 8589934592. D/ var1 D!					--- var1 = (((((BMP280_S64_t)1)<<47)+var1))*((BMP280_S64_t)dig_P1)>>33;
	." 6 var1 =  " var1 D@ SD. CRLF
	var1 D@ OR 0=
	IF
		0. calpress D!
	ELSE
		1048576 rawpress @ - L->D calpress D!											--- p = 1048576-adc_P;
		calpress D@ 2147483648. D* var2 D@ D- 3125. D* var1 D@ D/ calpress D!			--- p = (((p<<31)-var2)*3125)/var1;
		dig_P9 @ L->D calpress D@ 8192. D/ DSQR D* 33554432. D/ var1 D!				 	--- var1 = (((BMP280_S64_t)dig_P9) * (p>>13) * (p>>13)) >> 25;
		dig_P8 @ L->D calpress D@ D* 524288. D/ var2 D!									--- var2 = (((BMP280_S64_t)dig_P8) * p) >> 19;
		calpress D@ var1 D@ D+ var2 D@ D+ 256. D/ dig_P7 @ L->D 16. D* D+ calpress D!	--- p = ((p + var1 + var2) >> 8) + (((BMP280_S64_t)dig_P7)<<4);
	THEN
	;

--- display the raw pressure in Pascals until a key is pressed	
pub READpress.	( -- )
	CRLF
	READtempcal
	READpresscal
	SETUP
	BEGIN
		MEASUREWAIT
		READtemp								--- needed to compensate the pressure reading
		READpress
		CALCpress
		." Raw pressure value =  " rawpress @ . SPACE
		." Calibrated pressure =  " calpress @ . ." Pascal" CRLF
	KEY UNTIL
	;
	
	--- display the raw pressure in Pascals until a key is pressed	
pub READpress1.	( -- )
	CRLF
	READtempcal
	READpresscal
	SETUP
	BEGIN
		MEASUREWAIT
		READtemp
		." Calibrated temperature value = " calibtemp @ <# # # 46 HOLD #S #> PRINT$ CRLF
		CALCtemp
		READpress
		CALCpress1 .S CRLF
		." Raw pressure value =  " rawpress @ . SPACE
		." Calibrated pressure =  " calpress D@ 128. D/ SD. ."  units?" CRLF
	KEY UNTIL
	;
	