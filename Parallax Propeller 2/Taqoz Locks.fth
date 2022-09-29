--- LOCKS v1 for Taqoz Reloaded v2.8 - Bob Edwards May 2021

--- If two or more cogs are writing to the same data in hub memory, that data would be in jeopardy from race conditions as each cog performs
---  its read-modify-write cycle. The outcome of two cogs writing to the same address at very nearly the same time is unknown - which of the
--- two values ends up at the address?

--- To fix that, the P2 has a pool of 16 semaphore bits called locks....

--- Allocate a lock, returning the lock number n. If n = 0-15, lock was allocated, if n=-1 then all locks were already allocated 
code LOCKNEW ( -- n )
			>PUSHX				'make space on the stack
			locknew a wc		't.o.s. new lock allocation number
	if_nc	ret					'successful allocation
	_ret_	mov a,#-1			'else signal all locks taken
end

--- Return lock number n (0-15) to the pool
code LOCKRET ( n -- )
			lockret a
			DROP;
			ret
end

--- test LOCKNEW & LOCKRET
CRLF 17 FOR LOCKNEW . CRLF NEXT								--- try allocating one too many locks
13 LOCKRET CRLF ." Did we release lock 13? - " LOCKNEW .	--- check we can release a lock
CRLF 16 FOR I LOCKRET NEXT									--- return all locks

--- Attempt to 'take' Lock n, flag = 0 if successful, else flag = 1
code LOCKTRY	( n -- flag )
			locktry a wc
	_ret_	wrnc a				' a = carry flag
end

--- Release Lock n (0-15) - only the cog that took the lock is permitted to do this
code LOCKREL	( n -- )
			lockrel a
			DROP;
end

--- Read lock n status, lock_status 1 = unlocked, 0 = locked - N.B. if lock is not owned, results invalid
code LOCK?		( n -- lock_owner lock_status  )
			>PUSHX				' make room for status
			lockrel b wc		' t.o.s.+1   = cog no. whose lock it is
	_ret_	wrnc a				' t.o.s.     = lock status
end

long LOCKNUM1
long LOCKNUM2

pub SLAVE1 ( -- )
	BEGIN
		BEGIN
			LOCKNUM1 @ LOCKTRY
			30 ms
		0= UNTIL
		." Slave acquired lock" CRLF
		500 ms
		LOCKNUM1 @ LOCKREL
		." Slave released lock" CRLF
		500 ms		
	AGAIN
;

pub SLAVE2	( -- )
	BEGIN
		BEGIN
			LOCKNUM2 @ LOCKTRY
			30 ms
		0= UNTIL
		500 ms
		LOCKNUM2 @ LOCKREL
		500 ms		
	AGAIN
;

pub SLAVE3 ( -- )
	BEGIN
		BEGIN
			LOCKNUM1 @ LOCKTRY
			30 ms
		0= UNTIL
		750 ms
		LOCKNUM1 @ LOCKREL
		750 ms		
	AGAIN
;

pub MASTER ( -- )
	BEGIN
		BEGIN
			LOCKNUM1 @ LOCKTRY
			30 ms
		0= UNTIL
		." Master acquired lock" CRLF
		1000 ms
		LOCKNUM1 @ LOCKREL
		." Master released lock" CRLF
		1000 ms
	KEY UNTIL
;

pub .LOCKS	( -- )
	OFF %CURSOR
	BEGIN
		%ERSCN %HOME
		%BOLD ." Press any key to stop scanning..." %PLAIN CRLF
		16 FOR
			." Lock number " I . SPACE
			I LOCK? SWAP
			." owned by cog #" . SPACE
			." status is " . CRLF
		NEXT
		20 ms
	KEY UNTIL
	ON %CURSOR
;


--- Demo the use of LOCK? to monitor Lock status in the P2
pub DEMO1	( -- )
	LOCKNEW
	LOCKNUM1 !
	LOCKNEW
	LOCKNUM2 !
	' SLAVE2 5 RUN
	' SLAVE3 6 RUN
	.LOCKS
	5 COGSTOP
	6 COGSTOP
	%BOLD ." So Cog 5 and 6 were monitored, by means of the LOCK? word, taking and releasing two locks" %PLAIN CRLF
	LOCKNUM1 @ LOCKRET
	LOCKNUM2 @ LOCKRET
;

--- Demo two cogs using a lock - each waits to take the lock in turn, then releases it
pub DEMO2	( -- )
	LOCKNEW
	LOCKNUM1 !
	%ERSCN %HOME
	%BOLD ." Press any key to stop the Master - 5s later the Slave will stop too" %PLAIN CRLF CRLF
	' SLAVE1 5 RUN %ERLINE
	MASTER
	%BOLD ." Master stopped " CRLF %PLAIN
	5 s
	5 COGSTOP
	%BOLD ." Slave also stopped" CRLF
	." Any code sequence protected by the lock could only have been run BY ONE COG AT A TIME" CRLF
	." so any read-modify-writes would run undamaged by the other cog. Enables race-free data" CRLF
	." or orderly sharing of a subsystem - e.g. the console port" CRLF
	%PLAIN
	LOCKNUM1 @ LOCKRET
;

