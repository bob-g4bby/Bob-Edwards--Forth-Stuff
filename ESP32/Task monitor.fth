\ Multitask - A Task memory monitor ver 1 - Bob Edwards Oct 2025
\ Tested under ESP32forth 7.0.7.21

\ Watch a tasks' data and return stacks in real time
\ Determine how big those stacks need to be - no need to guess
\ Once a task is finalised the stacks sizes can be reduced.

\ N.B. Load before your multitask application as a modified version of 'task' is used

\ Each task in the multitasker round robin list has memory allocated as follows:-
( executing the taskname puts the address of the linked list pointer on the data stack )

\ taskname ->      linked list pointer
\                  data stack pointer
\                  data stack
\                       |
\                  data stack end
\                  return stack
\                       |
\                  return stack end
\ rsp set here ->  xt of the assigned task  <- jump back to here
\                  pause
\                  branch
\                  memory address           -> jump back
\
\ In defining a task e.g. ' mysubprogram 16 16 task mytask1
\ here we've asked for the data and return stack to be 16 longs each
\ In actual fact, only 15 longs will be allocated by 'task' - a 'feature' to be aware of
\ also notice the bottom word on the data stack never gets used

only
tasks also internals also ansi

hex

\ Part of 'task' - fill from start addr for n-1 cells with constant $DEADBEEF
: watermark ( cells addr -- )
    swap 1- 0 do
        dup $DEADBEEF swap !
        cell+
    loop
    drop
;

\ A modified TASK word which watermarks the data and return stack spaces with $DEADBEEF
\ to enable us to identify how much stack is actually being used by the task
: task ( xt dsz rsz "name" )
   create
   here >r                                  \ save here on R stack
   0 , 0 ,                                  \ link, sp
   swap                                     ( xt rsz dsz )
   here cell+                               ( xt rsz dsz here2+4 )
   r@ cell+                                 ( xt rsz dsz here2+4 here1+4 )
   !                                        ( xt rsz dsz )  \ initialise data stack ptr
   dup here watermark
   cells allot                              \ allot space for the data stack
   here r@ cell+                            ( xt rsz dsz here3 here1+4 )
   @                                        ( xt rsz dsz here3 datastackptr  )
   !                                        \ store r stack ptr 2nd from bottom on data stack?!
   dup here watermark
   cells allot                              ( xt ) \ allot space for R stack
   dup 0= 
   if
        drop                                \ if xt=0, unassigned task allocation table is complete
   else                                     \ else the assigned task-pause-branch code is added
        here r@ cell+ @ @ !                 \ bottom of rstack now points to assigned task
        ,                                   \ compile xt inline
        postpone pause                      \ compile pause 
        ['] branch ,                        \ compile branch
        here 3 cells - ,                    \ and the jump back to the xt allotted to this task
   then
   rdrop ;


\ part of dumpl - display n as an eight digit unsigned number - assumes base is set hex!
: long. ( n -- )
    <# # # # # # # # # #> type
;

\ dump memory data in hex, starting from addr, for n longs
: dumpl     ( addr n -- )
    base @ -rot hex         ( base addr n )     \ save number base and set hex display
    8 -rot                  ( base 8 addr n )   \ count per display line
    cells                   \ convert n words to bytes
    over + swap             ( base 8 endaddr startaddr )
    do                      ( base dispcount )
        dup 8 = if
            cr i long. ." :  "  \ start a new line with an address display
        then
        i @ long. space     \ display data stored at i memory address
        1-                  ( base dispcount ) \ increment data/line count
        dup 0= if
            drop 8          \ reset the dispcount
        then
    cell +loop
    drop
    base !                  \ restore number base
    cr
;

\ dump an area of memory continuously until key pressed
: dumplcont     ( addr n -- )
    base @ >r hex
    page hide
    begin
        0 0 at-xy
        2dup dumpl
        pause
    key? until
    r> base !
    2drop
    show
;

variable memaddr                                \ used to scan memory allocation addresses
variable spaddr                                 \ data stack start address
variable spcount                                \ data stack size
variable rpaddr                                 \ return stack start address
variable rpcount                                \ return stack size
variable task-xt

\ parts of dotaskomn
: nextcell      ( -- data address )
    cell memaddr +!
    memaddr @ dup @ swap    
;

\ display address with :
:   address.    ( n -- )
    long. ." :"
;

\ starting at addr1, look for next address addr2 containing $DEADBEEF
: lookforDB     ( addr1 -- addr2 )
    cell -
    begin
        cell+
        dup @ $DEADBEEF =
    until
;

\ display task memory allocated once
: dotaskmon      ( task-xt dsz rsz -- )
    dup rpcount !
    swap dup spcount ! swap                     \ remember both stack sizes
    rot 
    dup cr ."                       Task: " see.
    >body memaddr !                             ( dsz rsz )  \ memaddr points to link address
    memaddr @ dup @ swap
    cr address. ."      link address: " .       \ display link address
    nextcell
    cr address. ."        dstack ptr: " .       \ display data stack pointer
    cell memaddr +!
    swap                                        ( rsz dsz )
    memaddr @
    dup spaddr !                                ( remember 'sp0' )
    cr ."        data stack occupies: " . ." to "
    cells cell - memaddr +!
    memaddr @ .                                 \ display data stack address range
    cell memaddr +!
    memaddr @
    dup rpaddr !                                \ remember 'rp0' )
    cr ."      return stack occupies: " . ." to "
    cells cell - memaddr +!
    memaddr @ .
    nextcell
    cr address. ."     assigned task: " dup .    \ display assiged task xt
    space see.                                   \ and  the name
    nextcell
    cr address. ."             pause: " dup .    \ display pause entry
    space see.                                   \ and confirm it is actually pause
    nextcell
    cr address. ."            branch: " dup .    \ display branch entry
    space see.                                   \ and confirm it is actually branch
    nextcell
    cr address. ."      jump address: " .        \ display the jump address
    cr
    cr ." data stack contents:"
    spaddr @ spcount @ 1 - dumpl cr
    ." return stack contents:"
    rpaddr @ rpcount @ 1 - dumpl cr
    ."   Data stack usage for this task: "
    spaddr @ dup cell+ lookforDB swap - 2 rshift . ." hex cells" cr
    ." Return stack usage for this task: "
    rpaddr @ dup lookforDB swap - 2 rshift . ." hex cells" cr
;

' main-task constant 'main-task
' yield-task constant 'yield-task

\ display task memory allocated continuously until key pressed - requires ANSI terminal
: taskmon   ( task-xt dsz rsz -- )
    rpcount ! spcount ! task-xt !
    task-xt @ dup 'main-task = >r
    'yield-task = r> or
    if
        cr ." Only user tasks can be monitored with taskmon" cr
    else
        hide page    
        begin
            0 0 at-xy                                \ display at the top left ...
            task-xt @ spcount @ rpcount @ dotaskmon  \ the task memory allocation
            pause                                    \ allow all tasks to run
        key? until
        show
    then
;

\ Test Tasks **************************************************************************

variable count1
variable count2

\ a couple of tasks to verify the task memory allocation
: baba
    0 begin 250 ms 1+ dup count1 ! pause again
;

' baba $20 $20 task mytask1
mytask1 start-task

: gaga
    0 begin 500 ms 1+ dup count2 ! pause again
;

' gaga $15 $15 task mytask2
 mytask2 start-task

\ show counters until key pressed - check the two tasks are running
: testtasks ( -- )
    begin
        cr ." task1: " count1 ? ." task2: " count2 ?
        250 ms
    key? until
;

\ ' mytask1 $20 $20 taskmon
\ ' mytask2 $15 $15 taskmon