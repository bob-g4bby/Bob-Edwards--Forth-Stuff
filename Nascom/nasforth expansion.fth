( Patches to Polydos Nasforth v1.11 to increase code space - ver 3 )
( Bob Edwards Nov 2023 )
( DOES NOT work for original Nasforth as the RAM disk space is eliminated )
( Create a Polydos Nasforth system first, then run this patch )
( expansion needs to stop short of the Polydos workspace, which starts at C000 )

HEX
FLUSH
 
BB00 16 +ORIGIN !   ( move the terminal input buffer TIB )
BB00 12 +ORIGIN !   ( move the parameter stack ptr )
BBA0 14 +ORIGIN !   ( move the return stack ptr )
BBA0 10 +ORIGIN !   ( move the User Pointer UP )
BBE0 16D9 !         ( patch constant FIRST to move start of disk buffer )
C000 16E5 !         ( patch constant LIMIT to the end of disk buffer )
4BA0 BBA0 32  CMOVE ( move the User Variables )
4BE0 BBE0 420 CMOVE ( move the Disk Buffer )
BBE0 USE !          ( Disk Buffer to use next )
BBE0 PREV !         ( Disk Buffer most recently accessed )
BBE0 2122 !         ( patch COLD so PREV is initialised to higher address )
BBE0 211A !         ( patch for USE and PREV )
BBE0 2358 !         ( patch to unknown code )

( more accurate FREE lists true code bytes available )
: FREE TIB @ HERE - U. ;  ( more accurate, excludes the buffers, stacks etc )

( then do a SYS-SAVE, <ctrl-shift-@> to exit to Polydos - take a note of the end address saved )
( and then create a BIGFORTH.GO file saving 1000 - <the noted address> hex )

( Revised memory map )
( 1000 - 1025 hex ... Cold & Warm start vectors )
( 1026 - 103E hex ... Debug support area )
( 103F - 104C hex ... Inner Interpreter )
( 104C - BB00 hex ... Expanded code space )
( BB00 - BB50 hex ... terminal input buffer )
( XXXX - BB00 hex ... Data stack extending downwards )
( XXXX - BBA0 hex ... Return stack extending downwards )
( BBA0 - BBE0 hex ... System USER variables )
( BBE0 - BFFF hex ... Disk buffer )
( The RAM disk is no longer supported in Polydos Nasforth )
