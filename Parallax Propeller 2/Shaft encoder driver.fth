--- Quadrature encoder driver ver 3 - for Taqoz Reloaded ver 2.8 Bob Edwards July 2022
--- NB check the assembler P2ASM is loaded before loading this code
--- This is adapted from source code in Jon Titus's paper on Smartpin Programming

IFDEF *QUADENC*
	FORGET *QUADENC*
}
pub *QUADENC* ." Quadrature Encoder reader for Taqoz Reloaded v2.8" ;

%0000_0001_000_00000_00000000_00_01011_0 := qesetup
8 := qeaddr							--- encoder attached to smartpins 8,9, edit to suit

--- set up quadrature encoder to measure encoder pulses during 'period' clock pulses
--- if P2 clock is 20MHz, for 1 sec measurement, set period = 20,000,000
--- encoder signals are assumed connected to smartpins pin and pin+1
code QE!		( period pin -- )
	dirl a							--- hold the smartpin in reset
	wrpin #qesetup,a				--- set the two pins for quadrature encoder mode
	wxpin b,a						--- set the period expressed as system clocks
	dirh a							--- and release the smartpin to run
	jmp #@2DROP
end

--- Read the n pulses that occurred during the last measurement period
code QESPEED	( pin -- n )
.l1 testp a wc						--- test carry at the pin
	if_nc jmp #l1					--- wait until carry detected, measurement period is over
	_ret_ rqpin a,a					--- return the quadrature encoder pulse result
end

--- Display the quadrature encoder speed result until key pressed
pub SPEEDTEST	( -- )
	20000000 qeaddr QE!				--- encode connected to pin 8,9, measuring for 1s
	BEGIN
		qeaddr QESPEED . CRLF		--- measure pulses and display result
		100 ms
	KEY UNTIL						--- until any key is pressed
CRLF
;

--- Read the absolute position of the quadrature encoder
code QEPOS		( pin -- n )
	_ret_ rqpin a,a					--- read the accumulated counts since last read
end

--- Display the quadrature encoder position until a key is pressed
pub POSTEST		( -- )
	0 qeaddr QE!					--- setup encoder on smartpin 8,9 for position mode
	BEGIN
		qeaddr QEPOS				--- read the encoder
		. CRLF						--- and display the position
	KEY UNTIL
;

