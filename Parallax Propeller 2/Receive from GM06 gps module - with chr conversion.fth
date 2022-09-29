9600 := BRATE				--- Smartpin async operation at this baudrate only works at 20 MHz clock rate ie RCFAST
55   := RXPIN				--- Serial data input  - NB P2 IO input voltage must be no greater 3.3 volts
byte lastchr				--- used to remember if last chr was a comma
0 lastchr C!

pub SDRX ( -- char )		--- RX char from smart pin serial - first attempt - seems to work
    WAITPIN
    RDPIN					--- receive smartpin char on RXPIN
    #24 >>					--- shift data from bits 31-24 to 7-0
;

pub RXINIT ( -- )			--- initialise smartpin for ASYNC serial RX at BRATE baud rate
    RXPIN PIN MUTE
    RXPIN PIN BRATE RXD H	--- H - set pin high needed to enable smartpin operation?
;

pub zerolastchr	( -- )
	0 lastchr C!
	;

--- a filter to convert NMEA to more forth friendly words and numbers
--- , is replaced by SPACE or ,, is replaced by 0
--- any * is replaced by $
--- any $ is deleted e.g. $GPGLL becomes GPGLL
pub (GPS.) ( chr -- )
	SWITCH
			',' CASE
					lastchr C@ ',' = 
					IF ."  0 " ELSE SPACE THEN
					',' lastchr C!
				BREAK
			'*' CASE
					SPACE '$' EMIT
					zerolastchr
				BREAK
			'$' CASE
					zerolastchr
				BREAK
				CASE@ EMIT					--- default action	
				zerolastchr
	;

pub GPS. ( -- )				--- Repeat incoming serial stream to the terminal until key pressed
	RXINIT					--- initialise serial input
	CRLF
	BEGIN
		SDRX				--- read chr from gps
		(GPS.)				--- convert to forth friendly words
	KEY UNTIL				--- until the user presses a key
	;

{

An NMEA sentence can be parsed by the Taqoz interpreter (rather than creating another special one)
Each NMEA command is defined as a TAQOZ word and deferred to execute at the end of the line using ->
Best to check the stack size as the number of parameters with each NMEA command varies

}
	