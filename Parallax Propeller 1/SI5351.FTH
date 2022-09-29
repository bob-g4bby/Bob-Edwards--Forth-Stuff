--- SI5351 DRIVER version 2 FOR TACHYON 5V7 Bob Edwards Dec 2020
--- Optimised for radio tuning by minimising the number of bytes sent to the SI5351
--- when a tuning step is demanded

TACHYON V5

IFDEF SI5351
	FORGET SI5351
}
module SI5351 ." SI5351 dual channel RF oscillator driver" ;


--- Record types

--- start a record definition, leave zero offset into the record tos
0	:=	[FIELDS		( 0 -- )

--- define a new field within a record
pre FIELD				  
	CREATE OVER W, +        ( offset1 datasize -- offset2 )
	DOES> R> W@ +           ( recaddr -- recaddr+offset )
	;

--- finalise a record definition
ALIAS := FIELDS]


--- define a record array type
pre RECORDS ( fielddef recordnumber <arrayname> -- ; arrayindex -- adr )
	GRAB 
	CREATE			--- in the dictionary entry...
		org@ W,		--- save start address of data
		OVER W,		--- and save the record size
		* @org W+!  --- then in the dataspace allot reqd no. of bytes
	DOES>
		R@ W@		--- read the start address of the data
		R> 2+ W@	--- read the record size
		ROT * +		--- and compute the start address of the reqd record
;
	
--- constants
$C0      	:= vfoadr				--- SI5351 i2c address
25008325 	:= fref					--- nominal crystal frequency driving the si5351
750000000	:= pllmid				--- PLL frequency midrange
600000000	:= pllmin				--- PLL minimum permitted frequency
900000000	:= pllmax				--- PLL maximum permitted frequency
1048575		:= C					--- FMD parameter C is maintained as a constant 	

--- variables
long frequency						--- required o/p frequency for the active channel
long Rfreq							--- reqd OMD o/p frequency, before R divider
long pllfreq						--- reqd pll frequency 
long A								--- A parameter of the FMD divider
long B								--- B parameter of the FMD divider
byte R								--- The R divider parameter
byte LASTREG						--- address of SI5351 register last written to in autoincrement mode
byte pllreset						--- pllreset set 1 if pll reset needed
byte RFactive						--- set to 0 or 1 to select CLK0 or CLK1 as active channel for cmds

--- Storage definition for one RF channel - remember word and long boundaries
--- the size of the record has to be maintained a multiple of 4, so all records will be aligned
--- This can be achieved by an extra dummy entry if need be
--- NB keep .msx_p1, .msna_p2 and .msna_p1 in this order and together
--- This ordering is relied on to speed up register transmission to the SI5351

[FIELDS
	4 FIELD .frequency		--- output frequency
	4 FIELD .OMD			--- OMD
	4 FIELD .msx_p1			--- OMD intermediate value + rx_div + msx_divby4
	4 FIELD .msna_p2		--- FMD intermediate value
	4 FIELD .msna_p1		--- FMD intermediate value
FIELDS] RFparam


--- Create a 3 record array for the two independent RF sources + another record as scratchpad

4 ALIGNORG								--- Ensure array starts on a long boundary
RFparam 3 RECORDS RFparams				--- record 0 = CLK0 params, record 1 = CLK1 params
										--- record 3 = copy of last params of active channel
										--- to allow SI5351 register changes to be detected

--- CLK0, CLK1 are used to select the active channel to be worked on, this state stored in variable RFactive

pri RFparams@ RFactive C@ RFparams ; 	( -- adr ) --- start adr of active channel params
pri RFoldparams@ 2 RFparams ;			( -- adr ) --- start adr of params from last cycle
pub CLK0 0 RFactive C! ;				( -- ) --- select CLK0 as the active channel
pub CLK1 1 RFactive C! ;				( -- ) --- select CLK1 as the active channel

--- Calculation of SI5351 register values

--- from the new output frequency and old OMD setting - the latter is allowed to be any number on start up
--- calculate the new OMD as d + e=0 / f=1, which is just d, and new pll frequency required

--- calculate R divider and equivalent o/p frequency
pri RCALC	( freq1 -- R freq2 )
	DUP 500000 <
	IF
	  2							--- R = 2 seed value 
	  7 FOR 
			2DUP * 500000 >		--- check if freq1 * R > 500kHz
			IF
				LEAVE			--- yes, f now > 500kHz,so leave loop
			ELSE
				2*				--- no, then set R = R * 2
			THEN 
		NEXT 					--- and try again
		SWAP 2DUP * SWAP DROP
	ELSE
		1 SWAP					--- R is 1 for frequencies over 500000, freq2 is no change
	THEN
;

--- calculate the new Output Multisynth Divider, flg=1 if pll reset reqd.
pri OMD		( freq oldOMD -- newOMD pllfreq flg )
	2DUP *
	DUP pllmin pllmax WITHIN	
	IF					( freq oldOMD pllfreq )
		ROT DROP 0
	ELSE				( freq oldOMD pllfreq )
		DROP DROP DUP	( freq freq )
		pllmid SWAP /	( freq newOMD )
		DUP 1 AND
		IF
			1+
		THEN			( freq newOMD' )
		SWAP OVER * 1	( newOMD pllfreq )						
	THEN
;


--- calculate a,b for parameters  a + b / c for the Feedback Multisynth Divider from the pll frequency
--- C is a constant, $FFFFF, the largest value permitted, so that widest b range gives best frequency precision
pri FMD					( pllfreq -- a b )
	DUP fref / SWAP			( -- a pllfreq )
	C fref */				( -- a c*pllfreq/Fref )
	OVER C * - 				( -- a b )
	;						( -- a b )

--- The SI5351 requires the above parameters to be packed in the following way...

--- calculate msna_p1
pri msna_p1!
	A @ 7 <<		--- A*128
	B @ 7 <<
	C /				--- 128*B/C
	+
	512 -
	RFparams@ .msna_p1 !
	;

--- calculate msna_p2
pri msna_p2!
	B @ 7 << DUP				--- 128*B
	C /							--- (128*B)/C
	C *							--- C*((128*B)/C)
	- 
	$F00000 +					--- Set top four bits of msna_p3, which is a constant $FFFFF
	RFparams@ .msna_p2 !		--- 128*B-C*((128*B)/C)
	;


--- calculate msx_p1, complete with msx_divby4 and rx_div bit fields
pri msx_p1!		( -- )
	RFparams@ >R
	R@ .OMD @
	128 * 512 -
	Rfreq @ 150000000 >
		IF
			$0C0000 +			--- MS0_DIVBY4
		THEN
	R C@ DUP 1 =
		IF
			DROP 0
		ELSE
			>| 20 <<			--- R0_DIV
		THEN
	+
	R> .msx_p1 !
	;

--- Copy the active channel params record to the scratchpad record
pri OLDPARAM!	( -- )
	RFparams@ RFoldparams@ RFparam CMOVE
	;

--- calculate and store all parameters in the currently selected channel record
pri PARAM!	( frequency -- )
	RFparams@ >R
	DUP frequency !			--- o/p frequency in active channel record
	RCALC SWAP
	R C!						--- save the R divider parameter
	DUP 
	Rfreq !						--- save the OMD divider o/p frequency
	R@ .OMD @
	OMD
	pllreset C!					--- save pllreset - 1 = reset needed
	DUP pllfreq !				--- save pllfreq
	FMD
	B !							--- save A
	A !							--- save B
	R> .OMD !					--- save OMD
	msna_p1!					--- calculate msna_p1
	msna_p2!					--- calculate msna_p2
	msx_p1!						--- calculate msx_p1
;

--- SI5351 I2C words

--- Read byte at register adr in si5351
pri VFOC@ ( adr -- byte )
	<I2C vfoadr I2C! I2C!				--- select the register at 'addr' 
	<I2C vfoadr 1+ I2C! nakI2C@ I2C>	--- read the contents
	;
	
--- Write byte to register adr in si5351
pri VFOC! ( byte adr -- )
	<I2C vfoadr I2C! I2C! I2C! I2C>
	;

--- Write a byte to SI5351 register using autoincrement address where possible
pri INCVFOC! ( byte adr -- )
DUP LASTREG C@ 1+ =			--- is this register = last register +1?
IF
	DROP 
	I2C!					--- yes, just send the register value
ELSE
	<I2C vfoadr I2C! I2C! I2C!	--- no, set up the register address and then send value
THEN
;

--- part of sendFMD and sendOMD
pri sendbytes	( -- )
	I C@ 1@ C@ <>			--- Are the new and old byte values different?
	IF
		I C@ 2@ INCVFOC!	--- Yes, so send the new byte to the SI5351 register
		2@ LASTREG C!		--- Save reg address to check for autoincrement
	THEN
	@1 --					--- Point to next lowest old byte
	@2 ++					--- Increment register address
	;

--- Send FMD to the SI5351 - all bytes if 1st time, else only changed bytes
pri sendFMD	( -- )
	RFactive C@
	IF 36 ELSE 28 THEN 2!		--- register start address, depends on active channel selected, store in memory 2
	RFoldparams@ .msna_p1 2 + 1!	--- memory 1 = pointer to MS byte of old .msna_p1
	RFparams@ .msna_p1 2 +		--- pointer to MS byte of .msna_p1
	FROM -1 BY 3 FOR			--- Do for all 3 bytes, decrementing new byte pointer
		sendbytes
	NEXT
	RFoldparams@ .msna_p2 2 + 1!	--- memory 1 = pointer to MS byte of old .msna_p1
	RFparams@ .msna_p2 2 +		--- pointer to MS byte of .msna_p1
	FROM -1 BY 3 FOR			--- Do for all 3 bytes, decrementing new byte pointer
		sendbytes
	NEXT
	; 

--- Send OMD to the SI5351 - all bytes if 1st time, else only changed bytes
pri sendOMD ( -- )
	RFactive C@
	IF 52 ELSE 44 THEN 2!		--- register start address, depends on active channel selected, store in memory 2
	RFoldparams@ .msx_p1 2 + 1!	--- memory 1 = pointer to bottom of previous params, MS byte of old .msx_p1
	RFparams@ .msx_p1 2 +		--- point to MS byte of new .msx_p1
	FROM -1 BY 3 FOR			--- Do for all 3 bytes, decrementing new byte pointer
		sendbytes
	NEXT
	;

--- Wait until si5351 initialisation complete
pri VFOINIT?	( -- ) 
	BEGIN
		0 VFOC@
		$80 AND 0=
	UNTIL
	;

--- Disable all clock outputs
pri VFO_OPS_DIS	( -- )
	$FC 3 VFOC! ;

--- Power down all clocks using register 16-23
pri VFOCLKSOFF	( -- )
	16 FROM 8 FOR
			$80 I VFOC!
	NEXT
;

--- Set crystal as both PLL source
pri VFOXTAL	( -- )
	0 15 VFOC!
	;

--- Set all disabled outputs low
pri VFOOUTLOW	( -- )
	0 24 VFOC!
	;

--- Init Multisynth constants
pri VFOSYNTHINIT	( -- )
	$FF 26 VFOC!
	$FF 27 VFOC!
	$FF 34 VFOC!
	$FF 35 VFOC!
	0 42 VFOC!
	1 43 VFOC!
	0 47 VFOC!
	0 48 VFOC!
	0 49 VFOC!
	0 50 VFOC!
	1 51 VFOC!
	0 55 VFOC!
	0 56 VFOC!
	0 57 VFOC!
	; 

--- Power up CLK, PLL, MS for currently selected channel
pri VFOPLLON
	RFactive C@ 
	IF 
		$4F 16
	ELSE
		$6F 17
	THEN
	VFOC!
	;

--- Reference load setup
pri VFOREFSET
	$12 183 VFOC!
	;


--- CLK output enable  for currently selected channel
pub RFon
3 VFOC@
RFactive C@
IF
	$FD
ELSE
	$FE
THEN
AND 3 VFOC!
;

pub RFoff
3 VFOC@
RFactive C@
IF
	$02
ELSE
	$01
THEN
OR 3 VFOC!
;

--- reset the PLL on the currently active channel
: RESETPLL
RFactive C@
	IF
		$80	
	ELSE
		$20
	THEN
	177 VFOC!
;

--- Initialise the SI5351 ready for frequency setting
pri RFinit		( -- )
	VFOINIT?		--- wait until si5351 has initialised
	VFO_OPS_DIS		--- disable both outputs
	VFOCLKSOFF		--- power down all clocks
	VFOXTAL			--- set crystal as PLL source
	VFOOUTLOW		--- set all disabled O/Ps low
	VFOSYNTHINIT	--- initialise multisynth constants
	VFOREFSET		--- Reference load start up
	RFactive C@
	2 0 DO
		  I RFactive C!
		  VFOPLLON	--- power up CLK, PLL, MS0
		  RFoff		--- but set both o/ps off for now
		LOOP
	RFactive C!
;

--- set the si5351 current channel to frequency
pub RFtune		( frequency -- )
	  0 LASTREG C!	--- Ensure we get a proper I2C address setting start
	  OLDPARAM!
	  PARAM!	--- calculate register values
	  sendOMD	--- send the OMD registers to the SI5351
	  sendFMD	--- send the FMD registers to the SI5351
	  I2C>		--- end the i2C transfer
	  pllreset C@
	  IF
		RESETPLL
	  THEN		--- reset the pll
;

--- Test Words

--- display all params for the selected channel
pub RFparam.		( -- )
CR CR ." RFparams settings..."
RFparams@
CR ."  frequency = " frequency @.
CR ."          R = " R C@ .
CR ."      Rfreq = " Rfreq @.
CR ."        OMD = " DUP .OMD @.
CR ."    pllfreq = " pllfreq @.
CR ."          A = " A @.
CR ."          B = " B @.
CR ."          C = " C .
CR ."    msna_p1 = " DUP .msna_p1 @.
CR ."    msna_p2 = " DUP .msna_p2 @.
CR ."    msna_p3 = " $FFFFF .
CR ."     msx_p1 = " DUP .msx_p1 @.
CR ."   pllreset = " pllreset C@ .
CR
;

--- Display a byte as 8 binary digits
pub .BIN8	( n -- )
8 FOR
	DUP 7 SHR >b
	48 + EMIT
	2*
NEXT
DROP ;

--- Display ONE si5351 register
pub .VFOREG	( adr -- )
	TAB ." Register "
	DUP DECIMAL . TAB ." : "	--- display register address
	DUP VFOC@					--- read the register
	DUP . ." decimal " TAB		--- and display it in decimal
	DUP .BYTE ."  hex " TAB		--- also in hex
	BINARY .BIN8 ."  binary"	--- and also in binary
	DROP CR
	DECIMAL
;

pri .RES TAB ." Reserved" CR ;

--- Display all si5351 registers
pub .VFOREGS ( -- )
	CR CR
	TAB ." si5351 REGISTER READOUT"
	CR CR
	4 FOR I .VFOREG NEXT
	.RES
	9 .VFOREG
	.RES
	15 FROM 13 FOR I .VFOREG NEXT .RES
	29 FROM 7 FOR I .VFOREG NEXT .RES 
	37 FROM 134 FOR I .VFOREG NEXT .RES
	177 .VFOREG .RES
	183 .VFOREG .RES 
	187 .VFOREG 
;

--- This is a cross check that the params were calculated correctly
pub freqcheck	( -- calculated_frequency_from_parameters )
	  RFparams@ >R
	  fref A @ *			--- fref * A
	  fref B @ C */			--- fref * B / C
	  +
	  R C@ /
	  R> .OMD @ /
;

--- Display the PLL lock status - PLL locked if healthy
pub LOCK
0 VFOC@
CR ." Channel A pll "
DUP $20 AND IF ." unlocked" ELSE ." locked" THEN
CR ." Channel B pll "
$40 AND IF ." unlocked" ELSE ." locked" THEN
CR
;

--- Tune from start to stop frequency, stepping 10Hz as fast as possible, stop if key pressed
pub SWEEP	( startfreq stopfreq -- )
RFinit >R
RFon
BEGIN					--- save the stop frequency on the R stack
	DUP RFtune
	10 +
	DUP R@ => KEY 0<> OR
UNTIL
DROP
R> DROP					--- clear the R and data stacks
;

: SWEEPtest
3700000 3770000 SWEEP
;

END
