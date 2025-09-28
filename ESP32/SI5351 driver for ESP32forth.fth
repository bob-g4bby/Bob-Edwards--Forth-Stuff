\ SI5351 RF signal generator driver for ESP32forth - ver. 1.0 by Bob Edwards Sept 2025

\ Written using ESP32forth version 7.0.7.21
\ Does not currently run on v7.0.6.19 maybe due to 'Wire' library changes
\ Does not compile on v7.0.5.4 since 'Structures' are not supported

\ Optimised for radio tuning by minimising data transfers to SI5351
\ N.B. value fref will need tuning for accurate frequency output
\ The crystals on the SI5351 modules aren't exactly 25MHz
\ A new vocabulary SI5351 is created to contain the driver words

only				            \ make sure we're in the FORTH vocabulary

\ If this code is alerady compiled, let's forget it
DEFINED? *SI5351* [IF] forget *SI5351* [THEN]
: *SI5351* ;

\ common forth words missing from ESP32forth

only
forth definitions

\ returns true if n is within range of low and high inclusive, else returns false
: within    ( n lo hi -- flag )
    1+ over -
    >r - r>
    u< 0<>
;

\ returns the bit position 0-31 of the MS bit of n1
: >|    ( n1 -- bitpos )
    0
    begin
        swap 1 rshift dup 0<>
    while
        swap 1+
    repeat
    drop
;

\ display one tab
: .TAB
    9 emit
;

vocabulary SI5351			        \ create the new SI5351 vocabulary
SI5351 definitions			        \ all definitions that follow will go there

\ constants
                                
$60      	constant vfoadr	        \ SI5351 i2c address
750000000	constant pllmid		    \ PLL frequency midrange
600000000	constant pllmin		    \ PLL minimum permitted frequency
900000000	constant pllmax		    \ PLL maximum permitted frequency
1048575		constant C		        \ FMD parameter C is maintained as a constant

\ values

\ May need adjustment to suit your SI5351 board - the onboard oscillators are not trimmed accurately
25008325 	value fref		        \ nominal crystal frequency driving the SI5351

\ variables
                                
only STRUCTURES also SI5351

variable changedCLKX                \ flag set true if CLK0 or CLK1 has been executed
variable i2creg                     \ required i2c register address
variable i2cdata                    \ data to send to an SI5351 register
variable frequency				    \ required o/p frequency for the active channel
variable Rfreq					    \ reqd OMD o/p frequency, before R divider
variable pllfreq				    \ reqd pll frequency 
variable A						    \ A parameter of the FMD divider
variable B						    \ B parameter of the FMD divider
variable R					        \ The R divider parameter
variable LASTREG				    \ address of SI5351 register last written to in autoincrement mode
variable pllreset				    \ pllreset set 1 if pll reset needed
variable m1					        \ scratch register 1
variable m2						    \ scratch register 2

struct RFparam
	\ i32 field .frequency		    \ output frequency
	i32 field .OMD		            \ OMD
	i32 field .msx_p1		        \ OMD intermediate value + rx_div + msx_divby4
	i32 field .msna_p2		        \ FMD intermediate value
	i32 field .msna_p1		        \ FMD intermediate value

create CLK0data RFparam allot	    \ create CLK0 workspace
create CLK1data RFparam allot	    \ create CLK1 workspace
create SCRATCHdata RFparam allot	\ create workspace so we can compare old and new data
                                    \ and thus determine which changed bytes need sending
\ Scratch register access
: m1@ m1 @ ;
: m2@ m2 @ ;
: m1! m1 ! ;
: m2! m2 ! ;

\ CLK0, CLK1 are used to select the active channel to be worked on, this state stored in vector RFactive

defer RFActive

: CLK0  ( -- )
    ['] CLK0data is RFActive         \ CLK0 channel will receive all subsequent commands
    -1 changedCLKX !                 \ signal all frequency setting bytes need to be sent next time
;

: CLK1  ( -- )
    ['] CLK1data is RFActive         \ CLK1 channel will receive all subsequent commands
    -1 changedCLKX !                 \ signal all frequency setting bytes need to be sent next time
;    

CLK0

\ Read which CLK channel is currently set to take commands, true=CLK0, false-CLK1
: CLK?     ( -- flg )
    RFActive
    CLK1data =
;


\ Calculation of register values from a wanted frequency

\ At frequencies below 500kHz an R prescaler is necessary
\ so calculate the required R divider and the equivalent o/p frequency, freq2

: RCALC	( freq1 -- R freq2 )
	DUP 500000 <
	IF
	  2							    \ R = 2 seed value 
	  7 0 DO 
			2DUP * 500000 >	        \ check if freq1 * R > 500kHz
			IF
				LEAVE			    \ yes, f now > 500kHz,so leave loop
			ELSE
				2*				     \ no, then set R = R * 2
			THEN 
		LOOP 					    \ and try again
		SWAP 2DUP * SWAP DROP
	ELSE
		1 SWAP				        \ R is 1 for frequencies over 500000, freq2 is no change
	THEN
;

\ Calculate the new Output Multisynth Divider, flg=1 if pll reset reqd.
: OMD		( freq oldOMD -- newOMD pllfreq flg )
	2DUP *
	DUP pllmin pllmax WITHIN	
	IF					            \ freq oldOMD pllfreq
		ROT DROP 0
	ELSE				            \ freq oldOMD pllfreq
		DROP DROP DUP	            \ freq freq
		pllmid SWAP /	            \ freq newOMD
		DUP 1 AND
		IF
			1+
		THEN			            \ freq newOMD'
		SWAP OVER * 1	            \ newOMD pllfreq						
	THEN
;

\ calculate a,b for parameters  a + b / c for the Feedback Multisynth Divider from the pll frequency
\ C is a constant, $FFFFF, the largest value permitted, so that widest b range gives best frequency precision

: FMD		( pllfreq -- a b )
	DUP fref / SWAP                 \ -- a pllfreq
	C fref */                       \ -- a c*pllfreq/Fref
	OVER C * -                      \ -- a b
;                                   \ -- a b

\ The SI5351 requires the above parameters to be packed in the following way...

\ calculate msna_p1
: msna_p1!
	A @ 7 lshift                    \ A*128
	B @ 7 lshift
	C /                             \ 128*B/C
	+
	512 -
	RFactive .msna_p1 !
;

\ calculate msna_p2
: msna_p2!
	B @ 7 lshift DUP                \ 128*B
	C /                             \ (128*B)/C
	C *                             \ C*((128*B)/C)
	- 
	$F00000 +                       \ Set top four bits of msna_p3, which is a constant $FFFFF
	RFactive .msna_p2 !             \ 128*B-C*((128*B)/C)
;

\ calculate msx_p1, complete with msx_divby4 and rx_div bit fields
: msx_p1!		( -- )
	RFactive >R
	R> DUP >R .OMD @
	128 * 512 -
	Rfreq @ 150000000 >
		IF
			$0C0000 +               \ MS0_DIVBY4
		THEN
	R @ DUP 1 =
		IF
			DROP 0
		ELSE
			>| 20 lshift             \ R0_DIV
		THEN
	+
	R> .msx_p1 !
;

\ Copy the active channel params record to the scratchpad record
: OLDPARAM!	( -- )
	RFactive SCRATCHdata RFparam CMOVE
;

\ Set all of Scratchdata <> RFactive, so all frequency setting bytes will get sent
: OLDPARAM<>    ( -- )
    RFparam 0 do
        RFActive I + C@
        invert 255 and
        SCRATCHdata I + C!
    loop
;

\ Calculate and store all parameters in the currently selected channel record
: PARAM!	( frequency -- )
	RFactive >R
	DUP frequency !                 \ save o/p frequency
	RCALC SWAP
	R !                             \ save the R divider parameter
	DUP 
	Rfreq !                         \ save the OMD divider o/p frequency
	R> DUP >R .OMD @
	OMD
	pllreset !                      \ save pllreset - 1 = reset needed
	DUP pllfreq !                   \ save pllfreq
	FMD
	B !                             \ save A
	A !                             \ save B
	R> .OMD !                       \ save OMD
	msna_p1!                        \ calculate msna_p1
	msna_p2!                        \ calculate msna_p2
	msx_p1!                         \ calculate msx_p1
;

\ I2C words to communicate with SI5351 ***************************************************************

only wire also SI5351                   \ 'wire' is the vocabulary with the i2c interface words

\ initialise the I2C interface, define the GPIO pins used
\ and wait for the SI5351 to initialise
: Wire.start    ( -- )
    21 22 Wire.begin drop               \ gpio21 set as sda, gpio22 set as scl
;


\ Read byte at register regadr in SI5351
: VFOC@ ( regadr -- byte )
    i2creg !                            \ save the register address
    vfoadr Wire.beginTransmission
    i2creg 1 Wire.write drop            \ send the SI5351 register address required -- that data needs to be at an address, not on the stack
    0 Wire.endTransmission drop
    vfoadr 1 -1 Wire.requestFrom drop   \ request one byte of register data and send a stop message
    Wire.Available drop	                \ # bytes to read
    Wire.Read                           \ read the SI5351 register contents
;

\ Write byte to register regadr in SI5351
: VFOC! ( byte regadr -- )
    \ 2dup ." VFO!: sending to SI5351 register " . ."  data byte " . cr         \ debug display
	i2creg !                            \ save the register address
    i2cdata !                           \ save the data to be written to the register
    vfoadr 	Wire.beginTransmission
    i2creg 1 Wire.write drop            \ send the SI5351 register required
    i2cdata 1 Wire.write drop           \ send the data for the SI5351 register
    1 Wire.endTransmission drop
;

\ Write a byte to SI5351 register using autoincrement address where possible
: INCVFOC! ( byte regadr -- )
    \ 2dup ." INCVFO!: sending to SI5351 register " . ."  data byte " . cr       \ debug display
	i2creg !                            \ save the register address
    i2cdata !                           \ save the data to be written to the register
    i2creg @ LASTREG @ 1+ =             \ is this register = last register +1?
	IF
        i2cdata 1 Wire.write drop       \ send the data for the SI5351 register
	ELSE
        -1 Wire.endTransmission drop
        vfoadr 	Wire.beginTransmission  \ send the required SI5351 register address
        i2creg 1 Wire.write drop        \ send the SI5351 register required
        i2cdata 1 Wire.write drop       \ send the data for the SI5351 register
	THEN
;

\ used internally by sendFMD and sendOMD
\ variable @1 points to the old data
\ variable @2 holds the SI5351 register address
\ top of stack points to the new data
: sendbytes	( ptr_to_new_data -- )
3 0 DO                                  \ Do for all 3 bytes, decrementing new byte pointer
	DUP I - C@ m1@ C@ <>                \ Are the new and old byte values different?
		IF
			DUP I -  C@ m2@ INCVFOC!    \ Yes, so send the new byte to the SI5351 register
			m2@ LASTREG !               \ Save reg address to check for autoincrement
		THEN
	-1 m1 +!                            \ Point to next lowest old byte
	 1 m2 +!                            \ Increment register address
LOOP
DROP
;

\ Send FMD to the SI5351 - all bytes if 1st time, else only changed bytes
: sendFMD	( -- )
	CLK?                                \ read which clock is currently taking commands
	IF 36 ELSE 28 THEN m2!              \ register start address, depends on active channel selected, store in memory 2
	SCRATCHdata .msna_p1 2 + m1!        \ memory 1 = pointer to MS byte of old .msna_p1
	RFActive .msna_p1 2 +               \ pointer to MS byte of .msna_p1
	sendbytes
	SCRATCHdata .msna_p2 2 + m1!        \ memory 1 = pointer to MS byte of old .msna_p1
	RFActive .msna_p2 2 +               \ pointer to MS byte of .msna_p2
	sendbytes
; 

\ Send OMD to the SI5351 - all bytes if 1st time, else only changed bytes
: sendOMD ( -- )
	CLK?                                \ read which clock is currently taking commands
	IF 52 ELSE 44 THEN m2!              \ register start address, depends on active channel selected, store in memory 2
	SCRATCHdata .msx_p1 2 + m1!         \ memory 1 = pointer to bottom of previous params, MS byte of old .msx_p1
	RFActive .msx_p1 2 +                \ point to MS byte of new .msx_p1
	sendbytes
;

\ Wait until SI5351 initialisation complete
: VFOINIT?	( -- ) 
	BEGIN
		0 VFOC@
		$80 AND 0=
	UNTIL
;

\ Disable all clock outputs
: VFO_OPS_DIS	( -- )
	$FC 3 VFOC!
;

\ Power down all clocks using register 16-23
: VFOCLKSOFF	( -- )
	8 0 DO
			$80 I 16 + VFOC!
	LOOP
;

\ Set crystal as both PLL source
: VFOXTAL	( -- )
	0 15 VFOC!
;

\ Set all disabled outputs low
: VFOOUTLOW	( -- )
	0 24 VFOC!
;

\ Init Multisynth constants
: VFOSYNTHINIT	( -- )
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

\ Power up CLK, PLL, MS for currently selected channel
: VFOPLLON
    CLK?
    IF
        $4F 16
    ELSE
        $6F 17
    THEN
    VFOC!
;

\ Reference load setup
: VFOREFSET	( -- )
	$12 183 VFOC!
;

\ CLK output enable  for currently selected channel
: RFon	( -- )
    3 VFOC@
    CLK?
    IF
        $FD
    ELSE
        $FE
    THEN
    AND 3 VFOC!
;

: RFoff ( -- )
    3 VFOC@
    CLK?
    IF
        $02
    ELSE
        $01
    THEN
    OR 3 VFOC!
;

\ Reset the PLL on the currently active channel
: RESETPLL	( -- )
    CLK?
	IF
		$80	
	ELSE
		$20
	THEN
	177 VFOC!
;

\ Initialise the SI5351 ready for frequency setting
: RFinit		( -- )
	VFOINIT?                            \ wait until si5351 has initialised
	VFO_OPS_DIS                         \ disable both outputs
	VFOCLKSOFF                          \ power down all clocks
	VFOXTAL                             \ set crystal as PLL source
	VFOOUTLOW                           \ set all disabled O/Ps low
	VFOSYNTHINIT                        \ initialise multisynth constants
	VFOREFSET                           \ Reference load start up
	CLK1
    VFOPLLON							\ power up CLK, PLL, MS0
    RFoff								\ set o/p off for now
    CLK0
    VFOPLLON							\ power up CLK, PLL, MS0
    RFoff								\ set o/p off for now
;

\ set the si5351 current channel to frequency ( Hz )
: RFtune		( frequency -- )
	  0 LASTREG !                       \ Ensure we get a proper I2C address setting start
  	  OLDPARAM!
      PARAM!                            \ calculate register values
      changedCLKX @ IF                  \ are all frequency setting bytes needed to be sent?
        OLDPARAM<>                      \ Set all Scratchdata <> RFactive data
        0 changedCLKX !                 \ and reset that flag, so only changed bytes sent thereafter
      THEN
	  sendOMD                           \ send the OMD registers to the SI5351
	  sendFMD                           \ send the FMD registers to the SI5351
      1 Wire.endTransmission drop       \ end the i2C transfer
	  pllreset @
	  IF
		RESETPLL                        \ reset the pll
	  THEN
;

\ Using CLK0, tune from start to stop frequency, stepping 10Hz as fast as possible, stop if key pressed
\ This produces 1024 steps per second on an ESP32 WROOM 32, so a nice smooth sweep at 10Hz per step
: RFsweep	( startfreq stopfreq -- )
RFinit >R
RFon
BEGIN                                   \ save the stop frequency on the R stack
	DUP RFtune
	10 +                                \ step 10Hz higher
	DUP R> DUP >R >= KEY? OR            \ stop when stopfreq reached or user presses key
UNTIL
DROP
R> DROP                                 \ clean up the R and data stacks
;


\ Test words **********************************************************************

: *VFOTESTWORDS* ;                      \ Easy to forget from here if not needed

\ Test write / read from SI5351 works
: VFO!@ ( byte regadr -- )
    2dup swap ." Writing  " . ."  to register " .
    2dup VFOC!
    swap drop
    dup VFOC@                            \ regaddr data
    CR ." Reading " . ."  from register " . CR
;

\ display all params for the selected channel
: RFparam.		( -- )
CR CR ." RFparams settings..."
RFactive
CR ."  frequency = " frequency ?
CR ."          R = " R ?
CR ."      Rfreq = " Rfreq ?
CR ."        OMD = " DUP .OMD ?
CR ."    pllfreq = " pllfreq ?
CR ."          A = " A ?
CR ."          B = " B ?
CR ."          C = " C .
CR ."    msna_p1 = " DUP .msna_p1 ?
CR ."    msna_p2 = " DUP .msna_p2 ?
CR ."    msna_p3 = " $FFFFF .
CR ."     msx_p1 = " .msx_p1 ?
CR ."   pllreset = " pllreset ?
CR
;


\ Display ONE SI5351 register
: VFOREG.	( adr -- )
	.TAB ." Register "
	DUP . .TAB ." : "                    \ display register address
	DUP VFOC@                            \ read the register
	DUP . ." decimal " .TAB              \ and display it in decimal
	HEX . DECIMAL ."  hex " .TAB         \ also in hex
	DROP CR
;

\ Display "reserved" for an illegal register number
: .RES .TAB ." Reserved" CR ;

\ Display all SI5351 registers
: VFOREGS. ( -- )
	CR CR
	.TAB ." SI5351 REGISTER READOUT"
	CR CR
	4 0 DO I VFOREG. LOOP
	.RES
	9 VFOREG.
	.RES
	13 0 DO I 15 + VFOREG. LOOP .RES
	7 0 DO I 29 + VFOREG. LOOP .RES 
	134 0 DO I 37 + VFOREG. LOOP .RES
	177 VFOREG. .RES
	183 VFOREG. .RES 
	187 VFOREG. 
;

\ This checks that the params were calculated correctly by back-calculating the output frequency 
: FREQCHECK.	( -- )
	  RFactive >R
	  fref A @ *                            \ fref * A
	  fref B @ C */                         \ fref * B / C
	  +
	  R @ /
	  R> .OMD @ /
	  CR CR
	  ." The si5351 params will give an output of " . ." Hz" CR
;

\ This displays all three structures that hold the SI5351 register settings
: Strucs.    ( -- )
CR CLK0
." CLK0 settings" CR
."     OMD = " RFactive .OMD ? CR
."  msx_p1 = " RFactive .msx_p1 ? CR
." msna_p2 = " RFactive .msna_p2 ? CR
." msna_p1 = " RFactive .msna_p1 ? CR
CLK1
." CLK1 settings" CR
."     OMD = " RFactive .OMD ? CR
."  msx_p1 = " RFactive .msx_p1 ? CR
." msna_p2 = " RFactive .msna_p2 ? CR
." msna_p1 = " RFactive .msna_p1 ? CR
." Scratch data settings" CR
."     OMD = " SCRATCHdata .OMD ? CR
."  msx_p1 = " SCRATCHdata .msx_p1 ? CR
." msna_p2 = " SCRATCHdata .msna_p2 ? CR
." msna_p1 = " SCRATCHdata .msna_p1 ? CR
;

forth definitions
SI5351
\ forget *VFOTESTWORDS*
