\ Rotary encoder driver ver 1 for ESP32forth v 7.0.5.4 - Bob Edwards October 2025

only forth
forth definitions

: ?dup                   \ missing in v7.0.5.4
    dup 0<> if dup then
;

vocabulary encoder
encoder definitions
only forth also encoder also interrupts

\ GPIO pin allocation - pin names as per markings on encoder
4 constant CLK
15 constant DT

\ driver variables
defer count             \ deferred so the encoder can be made to control any number of variables directly
variable counter
' counter is count      \ the default variable to be changed
variable time
variable oldtime
variable oldCLKDT
variable CLKDT
variable maxvalue
variable minvalue

\ the three state machine actions
: donothing
;

: countup
    1 count +!
    count @ maxvalue @ >
    if
        maxvalue @ count !
    then
;

: countdown
    -1 count +!
    count @ minvalue @ <
    if
        minvalue @ count !
    then
;


\ state machine lookup table determines counter direction
\ and ignores illegal transitions caused by contact bounce

create encoderstate           \ oldCLK    oldDT   CLK     DT
' donothing ,                 \   0        0       0       0
' countdown ,                 \   0        0       0       1
' countup ,                   \   0        0       1       0
' donothing ,                 \   0        0       1       1
' countup ,                   \   0        1       0       0
' donothing ,                 \   0        1       0       1
' donothing ,                 \   0        1       1       0
' countdown ,                 \   0        1       1       1
' countdown ,                 \   1        0       0       0
' donothing ,                 \   1        0       0       1
' donothing ,                 \   1        0       1       0
' countup ,                   \   1        0       1       1
' donothing ,                 \   1        1       0       0
' countup ,                   \   1        1       0       1
' countdown ,                 \   1        1       1       0
' donothing ,                 \   1        1       1       1      

\ set rotary encoder signals as inputs
: setinputs ( -- )
    CLK input pinmode
    DT  input pinmode
;

\ read DT and CLK, format as a two bit value in CLKDT, save old values in oldCLKDT
: readencoder   ( -- )
    CLKDT @ 2 lshift oldCLKDT !         \ save last encoder state in oldCLKDT bits 2 and 3
    CLK digitalread 1 lshift
    DT digitalread +
    CLKDT !                             \ save latest reading in CLKDT bits 0 and 1
;

\ read encoder and evaluate required state machine action - count up, count down or do nothing
: evaluate_encoder  ( -- )
    readencoder
    oldCLKDT @ CLKDT @ +                \ form them into a 16 bit code
    2 lshift                            \ cell offset into the 'state' table
    encoderstate + @                    \ read off the reqd action - countup, countdown or domothing
    execute                             \ and execute that action
;

\ User words ********************************************************************************

\ read the accumulated 'count' that has occurred since it was last read, 'time' ms ago
\ this allows the speed at which the encoder was spinning to be calculated by the user program
: read_count_rel  ( -- count period )
    time @ oldtime !                    \ save the time at which the count was last read
    ms-ticks time !                     \ save the time now
    count @ 0 count !                   \ put count on the stack and zero variable 'count'
    time @ oldtime @ -                  \ calculate the elapsed time
;

\ read the variable assigned to deferred word count - do not reset it to 0
: read_count_abs  ( -- count )
    count @                            \ put count on the stack
;

\ set the variable that the encoder controls to 'yourvariablename' 
: assign_count  ( "yourvariablename" -- )
    ' is count
;

\ set min and max limits for the count
: set_limits    ( min max -- )
    maxvalue !
    minvalue !
;

\ remove limits for count
: remove_limits     ( -- )
    268435455 maxvalue !
    -268435455 minvalue !
;

remove_limits

\ reset the variable that the encoder controls to 'counter' defined above
: default_count ( -- )
    ['] counter is count
;

\ initialise encoder and interrupts
: init_encoder  ( -- )
    setinputs
    remove_limits
    ['] evaluate_encoder CLK pinchange
    ['] evaluate_encoder DT pinchange
;

init_encoder

\ Test words *********************************************************************

\ display count and time until key press
: relcount.    ( --)
    begin
        250 ms
        read_count_rel
        ."   time period = " . ." ms" cr
        ." encoder count = " . cr cr
    key? until
;

\ display count and time until key press
: abscount.    ( --)
    begin
        250 ms
        read_count_abs
        ." encoder count = " . cr cr
    key? until
;
