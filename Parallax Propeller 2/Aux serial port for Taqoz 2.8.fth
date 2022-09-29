--- Auxiliary Serial port ver 1 for Taqoz 2.8 Bob Edwards April 2022
--- data format is 1 start bit, 8  data bits, no parity, 1 stop bit 
--- Requires PASM loaded

TAQOZ
IFDEF *AUXSER*
    FORGET *AUXSER*
}
pub *AUXSER* ." Auxiliary Serial I/O" ;

9600 := BRATE		--- Smartpin async operation at this baudrate only works at 20 MHz clock rate ie RCFAST
54   := TXPIN		--- Serial data output - NB inverted output for use with TTL-RS232 interface
55   := RXPIN		--- Serial data input  - NB P2 IO input voltage must be no greater 3.3 volts

--- flag=true if smartpin ack has occurred
pub PIN?	( -- flag )
	@PIN
	ASM:
		testp a wc
		nop
		mov a,#0
		if_c mov a,#-1
		ret
	end

--- Initialise serial input
: RXINIT ( -- )   --- initialise smartpin for ASYNC serial RX at BRATE baud rate
    ( CLKSET )
    RXPIN PIN MUTE
    RXPIN PIN BRATE RXD H  --- H - set pin high needed to enable smartpin operation?
;

--- Initialise smart pin for ASYNC serial TX at BRATE baud rate
: TXINIT ( -- )
    ( CLKSET )
    TXPIN PIN MUTE
    TXPIN PIN BRATE TXD
;

--- Wait until a char is received and return with char
--- NB If a char is never received, this word will hang
: SDRX ( -- char )  			--- RX char from smart pin serial
    WAITPIN						--- wait until a char has been received
    RDPIN           			--- receive smartpin char on RXPIN, shift data from bits 31-24 to 7-0
    #24 >>
;

8 bytes sdrxtimer				--- storage for receive character timeout

--- RX char from smart pin serial input. flag=true if no char received and timeout in ms passed
: SDRX-TO	( timeout -- char flag=FALSE | flag=TRUE )
	sdrxtimer TIMEOUT			--- start the timeout
	BEGIN
		PIN?
		sdrxtimer TIMEOUT?
		OR						--- wait until timeout or a char received
	UNTIL
	sdrxtimer TIMEOUT?
	IF
		TRUE					--- return flag=true if timeout occurred
	ELSE
		RDPIN
		#24 >>
		FALSE					--- else return flag=false and the char
	THEN
;

--- transmit char via the serial output port
: SDTX ( char -- )   			--- send char via smart pin serial TX
    WYPIN            			--- send char TX
    WAITPIN          			--- wait for char to be sent
;

END

