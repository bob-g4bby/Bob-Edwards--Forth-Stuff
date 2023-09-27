# Bob Edwards' Forth Stuff

 These programs for Nasforth, a fig-forth programming tool-set for the Nascom Z80 based microcomputer.
 
 clock.fth - [using this circuit](https://github.com/bob-g4bby/Bob-Edwards--Nascom--Stuff/blob/main/Circuits/nascom%20clock%20circuit.pdf), adds a clock to the Nascom, driven by the PIO
             N.B. The clock chip needs 10k pullups to +5V on D0,D1,D2,D3 data lines - missing in the circuit diagram
 
 dump.fth  - e.g. HEX <start address> <number of bytes> DUMP -- Dump a table of hex values with ASCII to one side
 
 spell.fth - e.g. SPELL <wordname> -- Decompile a word in the dictionary for debug purposes
