--- Serial Input with timeout Bob Edwards April 2022
--- If a serial input word waits indefinitely for a character with no means of escape
--- that may leave a product locked up, reset being the only way out
--- This serial input only waits for a number of milliseconds to receive a char
--- after which time it will indicate chr received or timeout

921600 := BRATE \ Smartpin async operation at this baudrate only works at 20 MHz clock rate ie RCFAST
55   := RXPIN	\ Serial data input  - NB P2 IO input voltage must be no greater 3.3 volts

--- checks whether smartpin ack has occurred
pub PIN?	( -- flag=true if ack occurred )
	@PIN
	ASM:
		testp a wc
		nop
		mov a,#0
		if_c mov a,#-1
		ret
	end

--- initialise smartpin for ASYNC serial RX at BRATE baud rate
: RXINIT ( -- )
    ( CLKSET )
    RXPIN PIN MUTE
    RXPIN PIN BRATE RXD H	--- H - set pin high needed to enable smartpin operation?
;

--- serial input timeout data
8 bytes sdrxtimer

--- RX char from smart pin serial with timeout in ms
: SDRX-TO	( timeout -- chr flag=FALSE | flag=TRUE )
	sdrxtimer TIMEOUT		--- start the timeout
	BEGIN					--- leave this loop if
		PIN?				--- a chr arrived at the serial input
		sdrxtimer TIMEOUT?	--- or there's been no chr for 5s or more
		OR
	UNTIL
	sdrxtimer TIMEOUT?		--- has a chr been received
	IF
		TRUE				--- no, signal timeout occurred
	ELSE
		RDPIN				--- yes, read the chr
		#24 >>				--- adjust it to the LS byte
		FALSE				--- signal no timeout
	THEN
;

--- test of SDRX-TO
--- receive and display chrs on serial port until keypress
--- display alarm if 5s timeout occurs
--- requires serial data applying to smartpin 55
--- 921600 baud, 8 bit, no parity, 1 stop bit

: TEST
RXINIT
CRLF
BEGIN
	5000 SDRX-TO
	IF
		."  timeout! "
	ELSE
		EMIT
	THEN
KEY UNTIL
;

