\ Button read using polling, streams and multitasking ver 1 - Bob Edwards Oct 2025
\ Tested with ESP32forth ver 7.0.7.21 and 7.0.5.4

\ Polling at this low rate takes up very little processor time - far less finnicky than interrupt programming

only forth also streams

DEFINED? ?DUP [IF] [ELSE] : ?DUP dup 0<> if dup then ; [THEN] \ missing in v7.0.5.4

5 constant BUT                      \ GPIO pin number the button is connected to
100 constant butrate                \ set the button to be read every X mS

variable butcount                   \ counts the number of consecutive button low (pressed) states
3 stream buttonstr                  \ small message buffer for the button results

\ initialise the button for reading
: butinit       ( -- )
    BUT input pinMode
    0 butcount !
;

\ read the button
: butread      ( -- )
    butrate ms                      \ no need to read the button that fast
    BUT digitalread                 \ read the button state
    if                              \ if button released
        butcount @ ?DUP if          \ and the button sample count is non-zero
            buttonstr ch>stream     \ send the sample count to the button stream
            0 butcount !            \ and zero the count
        then
    else                            \ else button is pressed
        1 butcount +!               \ increment the 'pressed' counter
    then
;

\ set up 'butread' as a multitasker task 'butreadtask'
' butread $12 $12 task butreadtask  \ create the task to read the button - only small stacks needed
butreadtask start-task              \ and set it running

\ test words ***********************************************************************************

\ read the button message stream from the button task until a key is pressed
\ in a real application, this might be from another task, rather than the main program
: but.      ( -- )
    butinit
    begin
        buttonstr stream# if
            buttonstr stream>ch
            ." Button pressed for " . ." samples" cr
        then
    pause
    key? until
;

\ run but. and then press the button

