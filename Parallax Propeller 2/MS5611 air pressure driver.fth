--- MS5611 barometric pressure sensor chip i2c driver ver 3 - Bob Edwards G4BBY Feb 2022
--- For TAQOZ Reloaded v2.8
--- This code requires my Double Arithmetic words ver 3 or higher being loaded prior to this file
--- See forums.parallax.com/discussion/174163/taqoz-reloaded-v2-8-double-arithmetic-64-bit-words
--- Refers to Measurement Specialties doc. DA5611-01BA03_011 000056111624 ECN1742 Oct 26, 2012

IFDEF *MS5611* FORGET *MS5611* }
pub *MS5611*		PRINT" MS5611 barometric pressure sensor ver 3" ;

TAQOZ

ALIAS I2C.START <I2C						--- Matches the stop alias, I2C>

--- create constant to hold current i2c chip address 
0 := i2cadr

--- variables - some names are similar to those in the application paper
6 words  C			--- to hold the six MS5611 calibration words
C :=     C1
C 2+ :=  C2
C2 2+ := C3
C3 2+ := C4
C4 2+ := C5
C5 2+ := C6
long RAWTEMP		--- referred to as D2 in the application guide
long RAWPRESS		--- referred to as D1 in the application guide
long dT
long CALTEMP		--- referred to as TEMP in the application guide
long CALPRESS		--- referred to as P in the application guide
long T2
long OFF2
long SENS2
double OFFSET		--- referred to as OFF in the application guide
double SENS

--- set the i2c address for subsequent i2c transfers ( like PIN does for smartpins )
pub I2CADR	( n -- )
' i2cadr :=!
;

--- comment out the address setup that doesn't apply to your hardware
--- I2C address of the MS5611 with pin CSB connected to 0V
$EE I2CADR
--- I2C address of the MS5611 with pin CSB connected to Vdd
--- $ED	I2CADR

--- MS5611 reset sequence
pub 5611RESET	( -- )
	i2cadr I2CWR		--- send device address to select the MS5611
	%00011110 I2C!		--- send the reset cmd
	I2C.STOP
	5 ms 
	;

--- MS5611 read the prom - promaddr in the range 1 to 7, 1-6 being coefficents, 7 being serial code and CRC
pub 5611PROM	( promaddr -- promdata )
	i2cadr I2CWR		--- send device address to select the MS5611
	2* %10100000 + I2C!	--- send the read prom command
	I2C.STOP
	i2cadr I2CRD
	I2C@ 8 <<			--- read the MS byte of the PROM
	nakI2C@ +			--- read the LS byte and combine into 16 bits
	I2C.STOP
	;

--- MS5611 save all 6 PROM coefficients in array C
pub 5611PROMRDALL	( -- )
	5611RESET
	CRLF
	7 1 DO
			I 5611PROM
			I 1- 2* C + W!
		LOOP
	;

--- MS5611 display all PROM coefficients
pub 5611PROM.	( -- )
	5611PROMRDALL
	6 0 DO
		." PROM address " I 1+ .
		." = "
		I 2* C + W@ . CRLF
	LOOP
	;

--- MS5611 start temperature conversion command, oversampling ratio 4096
pub 5611CONVTEMP	( -- )
	i2cadr I2CWR		--- send device address to select the MS5611
	$58 I2C!			--- send the start conversion cmd
	I2C.STOP
    10 ms				--- wait for the converion to complete
;

--- MS5611 start pressure conversion command, oversampling ratio 4096
pub 5611CONVPRESS	( -- )
	i2cadr I2CWR		--- send device address to select the MS5611
	$48 I2C!			--- send the start conversion cmd
	I2C.STOP
    10 ms				--- wait for the converion to complete
;

--- MS5611 read back pressure or temperature result
pub	5611READDATA	( -- data )
	i2cadr I2CWR		--- send device address to select the MS5611
	0 I2C!				--- send the read data command
	I2C.STOP
	i2cadr I2CRD		--- send the device address for data read
	I2C@ 16 <<			--- read the MS byte of data
	I2C@ 8 << +			--- read the middle byte of the data
	nakI2C@ +			--- read the LS byte
	I2C.STOP
;

--- MS5611 Read raw pressure data
pub 5611READPRESS	( -- )
	5611CONVPRESS
	5611READDATA
	RAWPRESS !
	;
	
--- MS5611 Read raw temp data
pub 5611READTEMP	( -- )
	5611CONVTEMP
	5611READDATA
	RAWTEMP !
	;	

--- Convert RAWTEMP to deg C x 100 and save at CALTEMP, so 2001 = 20.01 degC
pub 5611CALTEMP	( -- )
	RAWTEMP @
	C5 W@ 8<< -
	DUP dT !
	L->D					--- here we have to use doubles as the max
	C6 W@ L->D D* 23 D>>	--- intermediate value could be up to 41 bits
	2000. D+
	DROP					--- as the result is always less than 32 bits
	CALTEMP !				--- we drop the top 32 bits
	;
	
--- Convert RAWPRESS to mbar x 100 and save at CALPRESS, so 100009 = 1000.09 mbar
pub 5611CALPRESS	( -- )
	C4 W@ L->D
	dT @ L->D D* 7 D>>
	C2 W@ L->D 16 D<< D+
	OFFSET D!				--- save OFF value
	dT @ L->D
	C3 W@ L->D D* 8 D>>
	C1 W@ L->D 15 D<< D+
	SENS D!					--- save SENS value
	RAWPRESS @ L->D
	SENS D@ D* 21 D>>
	OFFSET D@ D- 15 D>>
	DROP CALPRESS !			--- save true pressure in mbar x 100
	;

--- n2 = n1*n1
pub SQUARE	( n1 -- n2 )
	DUP *
	;
	
--- MS5611 apply second order temperature compensation to increase accuracy below 20C
pub 5611SECORDER	( -- )
	CALTEMP @ 2000 <
	IF
		dT @ L->D DSQR 31 D>>
		DROP T2 !
		CALTEMP @ 2000 - SQUARE 5 * DUP 
		2/ OFF2 !
		4/ SENS2 !
		CALTEMP @ -1500 <
		IF
			CALTEMP @ 1500 + SQUARE DUP
			7 * OFF2 @ + OFF2 !
			11 * 2/ SENS2 @ + SENS2 !
		THEN
		CALTEMP @ T2 @ - CALTEMP !
		OFFSET D@ OFF2 @ L->D D- OFFSET D!
		SENS D@ SENS2 @ L->D D- SENS D!
	THEN
	;

--- Display the raw temp and pressure
pub UNCALVAL. ( -- )
	." Raw pressure = "
	RAWPRESS @ .					--- Display raw pressure data
	." Raw temp = "
	RAWTEMP @ .						--- and raw tempdata
	;
	
--- Display the calibrated temp and pressure
pub CALVAL. ( -- )
		." Conversion ... "
		CALTEMP @
		DUP 1000 < IF
				.AS"  #.## deg C "
			ELSE
				.AS" ##.## deg C "
			THEN						--- display temp in deg C
		CALPRESS @
		DUP 100000 < IF
				.AS"  ###.## mbar"
			ELSE
				.AS" ####.## mbar"
			THEN
	;

--- MS5611 read back raw and corrected data until key press
pub 5611READALL.	( -- )
	5611RESET							--- Reset the MS5611
	5611PROMRDALL						--- Read in all the calibration constants
	CRLF
	BEGIN
		5611READPRESS					--- Start the pressure A/D conversion and read in the data
		150 ms
		5611READTEMP					--- Start the temp A/D conversion and read in the data
		150 ms
		5611CALTEMP						--- Convert the raw temp data to deg C
		5611CALPRESS					--- Convert the raw pressure data to mbar = hPa
		5611SECORDER					--- Apply 2nd order compensation below 20 deg C
		UNCALVAL.						--- display raw data
		CALVAL.							--- display calibrated data
		CRLF
	KEY UNTIL							--- repeat until a keystroke
	;

{
--- Arithmetic check against example data in the application guide

pub .truefalse	( f -- )
	if
		." ok"
	else
		." not ok"
	then
;

--- Load up the variables with the example data from the application sheet
40127 C1 W!
36924 C2 W!
23317 C3 W!
23282 C4 W!
33464 C5 W!
28312 C6 W!
9085466 RAWPRESS !
8569150 RAWTEMP !

CRLF
5611CALTEMP
." dT calculation is " dT @ 2366 = .truefalse CRLF
." TEMP calculation is " CALTEMP @ 2007 = .truefalse CRLF
5611CALPRESS
." OFF calculation is " OFFSET D@ 2420281617. D= .truefalse CRLF
." SENS calculation is " SENS D@ 1315097036. D= .truefalse CRLF
." CALPRESS calculation is " CALPRESS @ 100009 = .truefalse CRLF
}

END

 