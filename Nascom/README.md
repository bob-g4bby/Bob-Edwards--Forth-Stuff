# Bob Edwards' Forth Stuff

 These programs for Nasforth, a fig-forth programming tool-set for the Nascom Z80 based microcomputer.
 
 clock.fth - [using this circuit](https://github.com/bob-g4bby/Bob-Edwards--Nascom--Stuff/blob/main/Circuits/nascom%20clock%20circuit.pdf), adds a clock to the Nascom, driven by the PIO
             N.B. The clock chip needs 10k pullups to +5V on D0,D1,D2,D3 data lines - missing in the circuit diagram
 
 case.fth - a simple case statement to handle sequential integers 0 - n
 
 clock.fth - an MSM5382 chip driver via the Nascom PIO to provide calendar and time
 
 dump.fth  - e.g. HEX <start address> <number of bytes> DUMP -- Dump a table of hex values with ASCII to one side
 
 eakers case.fth - A more versatile case statement with example
 
 recursion.fth - Adds the ability for a forth word to call itself until some limit is met
 
 spell.fth - e.g. SPELL <wordname> -- Decompile a word in the dictionary for debug purposes
 
 throw-catch.fth - an error management system that works a bit like the 'back button' in a web browser. Automatically cleans up the stacks.
