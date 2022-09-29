--- GY-GPS6MV2 GPS positioning sensor version 1 for TAQOZ 2.8 - Bob Edwards, March 2022

IFDEF *GY-GPS6MV2* FORGET *GY-GPS6MV2* }
pub *GY-GPS6MV2*		PRINT" GY-GPS6MV2 gps position sensor ver 1" ;

( TAQOZ )

0 := unlocked
1 := timelocked
2 := positionlocked

long longitude
long latitude
word olddepth
word altitude
byte ew
byte ns
byte hours
byte minutes
byte seconds
byte day
byte month
byte year
byte trackangle
byte speedknots
byte lockstate
byte satnum
byte 2D3D
byte geoid
byte numtracked
byte groundspeedkm
byte groundspeedkn
byte groundspeedkn
byte headingm
byte headingt

DEPTH 1+ olddepth W!		--- initialise olddepth

--- return the difference in stack depth since last time it was called
pub #PARAMS?	( -- n )
	DEPTH olddepth W@ - 1+ DEPTH olddepth w!
	;

--- remember the stack depth as olddepth
pub !#PARAMS	( -- )
	#PARAMS? DROP
	
--- drop n stack values
pub DROPS	( n -- )
	FOR DROP NEXT
	;

Single letter parameters in messages

5 := A
1 := N
2 := E
3 := S
4 := W
6 := T
7 := M
8 := K
9 := V

--- Decode n as time and store at hours,mins & seconds
pub GPSTIME! ( n -- )
	100 /						--- time is received as e.g. 153520.00
	100 U// SWAP seconds C!
	100 U// SWAP minutes C!
	hours C!
	;

--- Decode n as date and store at year,month & day
pub GPSDATE! ( n -- )
	100 U// SWAP day C!
	100 U// SWAP month C!
	year C!
	;

--- display day, month, year
pub GPSDATE. ( -- )
	day C@ .DEC2 ." /"
	month C@ .DEC2 ." /"
	year C@ .DEC2
	;

--- display hours, minutes, seconds 
pub GPSTIME.	( -- )
	hours C@ .DEC2 ." :"
	minutes C@ .DEC2 ." :"
	seconds C@ .DEC2
	;

pub ALLDATA.
	CRLF CRLF
	." Date: " GPSDATE. ."  Time: " GPSTIME. CRLF
	." Latitude: " latitude @ . ."  Longitude: " longitude @ . CRLF
	." Altitude: " altitude W@ . ."  Heading: " headingt C@ .
	." Ground Speed: " groundspeedkm C@ . CRLF
	." Satellites tracked: " numtracked C@ . CRLF
	;

--- Sentence Decoders
--- Track made good and ground speed
pub GPVTG
	!#PARAMS -> #PARAMS? 10 =
	IF
		3DROP
		groundspeedkm C!
		DROP
		groundspeedkn C!
		DROP
		headingm C!
		DROP
		headingt C!
	ELSE
		!SP
	THEN
	;

--- Fix Data	
pub GPGGA
	!#PARAMS -> #PARAMS? 14 =
	IF
		3DROP
		geoid C!
		DROP
		altitude W!
		DROP
		numtracked C!
		6 DROPS
	ELSE
		!SP
	THEN
	;

--- Active Satellites	
pub GPGSA
	!#PARAMS -> #PARAMS? 18 =
	IF
		16 DROPS
		2D3D C!
		DROP
	ELSE
		!SP
	THEN
	;
	
--- Satellites in view - we don't bother with position details for now, just the number in view	
pub GPGSV
	!#PARAMS -> #PARAMS? 20 =
	IF
		17 DROPS
		satnum C!
		2DROP
	ELSE
		!SP
	THEN
	;

--- Position Latitude and Longitude
pub GPGLL
	!#PARAMS -> #PARAMS? 8 =
	IF
		3DROP
		GPSTIME!			--- save the time in hours, minutes, seconds
		ew C!				---	save east / west
		longitude !			--- save longitude
		ns C!				--- save north / south
		latitude !			--- save latitude
	ELSE
		!SP					--- if number of params <> 8 just discard as the message is corrupt
	THEN
	;

--- Recommended Minimum Coordinates	
pub GPRMC
	!#PARAMS -> #PARAMS? 13 =
	IF
		4 DROPS
		GPSDATE!
		trackangle C!
		speedknots C!
		ew C!
		longitude !
		ns C!
		latitude !
		DROP
		GPSTIME!
	ELSE
		!SP
	THEN
	;


 ( VOCAB GPS *GY-GPS6MV2*			--- Create special vocabulary GPS for the sensor )


( END )

GPGLL 5126.78969 N 00205.90746 W 094632.00 A A $73
GPRMC 094632.00 A 5126.78969 N 00205.90746 W 1.337 0 040322 0 0 A $6B
GPGSV 2 2 08 19 33 089 21 21 01 350 0 23 28 252 19 24 82 293 29 $76
GPGSA A 3 24 12 13 15 0 0 0 0 0 0 0 0 7.56 4.12 6.34 $03
GPGGA 094635.00 5126.78913 N 00205.90777 W 1 04 4.12 81.6 M 48.0 M 0 $7E
GPVTG 0 T 0 M 0.312 N 0.579 K A $28
ALLDATA.


