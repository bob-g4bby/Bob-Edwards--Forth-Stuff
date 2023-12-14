# Bob Edwards' Forth Stuff

 I've written a glossary for Nasforth, , a fig-forth programming tool-set for the Nascom Z80 based microcomputer, as part of a hyperlinked Nascom documentation package available here https://github.com/bob-g4bby/Bob-Edwards--Nascom--Stuff/tree/main/Documentation/Table%20of%20Contents%20experiment

 The following programs are for Nasforth:-

  auto-loading a disk file.fth - if a word is entered on the user terminal the system does not recognise, then a search is made on disk for a file of the same name. If found, this file will be loaded as source code

  case.fth - a simple case statement to handle sequential integers 0 - n
 
  clock.fth - [using this circuit](https://github.com/bob-g4bby/Bob-Edwards--Nascom--Stuff/blob/main/Circuits/nascom%20clock%20circuit.pdf), adds a clock to the Nascom, driven by the PIO
  N.B. The clock chip needs 10k pullups to +5V on D0,D1,D2,D3 data lines - missing in the circuit diagram
 
 dump.fth  - e.g. HEX <start address> <number of bytes> DUMP -- Dump a table of hex values with ASCII to one side
 
 eakers case.fth - A more versatile case statement with example
 
 mini-oof.fth - Bernd Paysan's famous object oriented program library adapted for Nasforth - simple yet powerful tool
 
 nasforth expansion.fth - Greatly expands code space to 30k+ bytes for Polydos Nasforth. Doesn't work for the original RAM disk Nasforth as the RAM disk area is eliminated. 
 
 recursion.fth - Adds the ability for a forth word to call itself until some limit is met
 
 spell.fth - e.g. SPELL 'wordname' -- Decompile a word in the dictionary for debug purposes
 
 String Library from Mark Wills.fth - Adds a string stack to the system with many string manipulation words - recommended
 
 throw-catch.fth - an error management system that works a bit like the 'back button' in a web browser. Automatically cleans up the stacks and returns if an error is non-zero.
 
 polyforth.cas - Under Polydos, use the NASSYS R command to read this file into memory via the serial port. Then use the Polydos command SAVE POLY4TH.GO 1000 5200 1000 1000 to save the file to disk. This is an image of the expanded Polydos Nasforth system, which will indicate 26944 bytes available for code when the word FREE is executed. It includes modules :-
    auto-loading a disk file.fth
    dump.fth
    eakers case.fth
    spell.fth
    String Library from Mark Will.fth
    throw-catch.fth
    
