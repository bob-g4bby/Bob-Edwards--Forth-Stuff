--- QMC5883 XYZ magnetic field sensor driver for Taqoz 2.8
--- Version 1 Nov 2021 by Bob Edwards


ALIAS I2C.START <I2C						--- Matches the stop alias, I2C>

--- create constant to hold current i2c chip address 
0 := i2cadr

--- set the i2c address for subsequent i2c transfers ( like PIN does for smartpins )
pub I2CADR	( n -- )
' i2cadr :=!
;

--- I2C address of the QMC5883 as reported by Taqoz
$1A I2CADR

--- Read byte at register i2cadr
pub I2CREAD ( adr -- byte )
	<I2C i2cadr I2C! I2C!					--- select the register at 'addr' 
	<I2C i2cadr 1+ I2C! nakI2C@ I2C>		--- read the contents
	;
	
--- Write byte to register i2cadr
pub I2CWRITE ( byte adr -- )
	<I2C i2cadr I2C! I2C! I2C! I2C>
	;

--- set QMC5883 for continuous reading	
pub SETUP
	1 $B I2CWRITE							--- define set/reset period
	$11 $9 I2CWRITE							--- OSR = 512
											--- full scale range = 8
											--- ODR = 10 Hz
											--- continuous mode
;

--- returns QMC5883 status
pub STATUS@	( -- status )
	6 I2CREAD
;

--- wait until a mag field reading is ready
pub RDY?	( -- )
	BEGIN
		STATUS@ 1 AND
	UNTIL
;

--- convert signed 16 bit value to signed long
pub W->L	( 16bitsigned -- 32bitsigned )
DUP 32767 >
IF
	65536 -
THEN
;

--- read the mag field in 3 axes
pub XYZ@	( --- X Y Z )
	0 I2CREAD
	1 I2CREAD 8<<
	OR W->L
	2 I2CREAD
	3 I2CREAD 8<<
	OR W->L
	4 I2CREAD
	5 I2CREAD 8<<
	OR W->L
;

--- read the raw temperature value
pub TEMP@	( --- temp )
	7 I2CREAD
	8 I2CREAD 8<<
	OR
;

--- test the mag field and temp readings
pub XYZtest
	SETUP
	BEGIN
		RDY?
		XYZ@
		." Z="  . SPACE
		."  Y=" . SPACE
		."  X=" . SPACE
		TEMP@
		." Temp=" .
		CRLF
		KEY
	UNTIL
;

--- read and compute the mag field in the XY plane
pub XYvec	( X Y Z -- ampl angle )
	XYZ@
	DROP QVECTOR
;

--- read and compute the mag field in the YZ plane
pub YZvec	( X Y Z -- ampl angle )
	XYZ@
	ROT
	DROP QVECTOR
;

--- read and compute the mag field in the XZ plane
pub XZvec	( X Y Z -- ampl angle )
	XYZ@
	SWAP 
	DROP QVECTOR
;

--- print compass bearing from raw angle output by QVECTOR
pub DEGS.	( rawangle -- )
	36000 4294967295 U*/
	DUP 100 / DUP 3 .DECS 46 EMIT 100 * -
	DUP 10 <
	IF
		48 EMIT
	THEN .
	;

--- test as a compass in the XZ plane
pub COMPASS	( -- )
	SETUP
	BEGIN
		RDY?
		XZvec
		." Mag Field Angle = " DEGS. SPACE  
		." Mag Field Amplitude = " .  CRLF
	KEY UNTIL
;
COMPASS
