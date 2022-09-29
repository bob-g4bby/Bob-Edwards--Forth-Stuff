
--- Modified lsi2c by Peter Jakacki - 19th Feb 2022
--- Uses a write command to test for devices. MS5611 chip now detected ok

pri DEV?
		1 SWAP 
		FOR
			CASE@ I2C.START 
			I2C.WR 0= i2C.STOP 25 us $FE I2CRD AND 
		NEXT
		;

pri .I2C ( adr8 -- )
        SWITCH  \ AT i2cdev C!
        100 I2C.KHZ $FF I2CRD I2C.STOP
---     Check for ack and exit if none
        CASE@  I2C.START I2C.WR 0= I2C.STOP 5 us I2C.STOP 0EXIT
---     Print the address on a new line
        CRLF+ CASE@ .B
        100								--- start frequency in khz
        6000 200 DO
			I I2C.KHZ 
			3 DEV? 11 COG@ 0<> AND 
			IF
				100 +
			ELSE 
				LEAVE
			THEN 
			50 us 
			100	+LOOP
        100 I2C.KHZ
		TAB PRINT PRINT" kHz" TAB TAB
---     and try to identify it
pri (.I2C)
        \ SWITCH
        $36 CASE 0 SFR@ DROP $B5 SFR@ $36 = IF PRINT" P2D2 UB USB+SUPPORT  UUID:" .UUID THEN BREAK
---     Could be RTC but check ID register in case this is not a P2D2
        $A4 CASE 0 RTC@ DROP $28 RTC@ $33 = IF PRINT" RV-3028 RTC  "  RDRTC 100 us .FDT THEN BREAK
        $DE CASE PRINT" MCP79410 RTC " BREAK
		$1A CASE PRINT" QMC5883 Magnetic Field Sensor" BREAK
        CASE@ $A0 $AE WITHIN IF .EEPROM BREAK
        CASE@ $C0 $CE WITHIN IF PRINT" Si5351A Clock Generator" BREAK
        CASE@ $D0 $DC WITHIN IF PRINT" DS3231 compatiable RTC" BREAK
        $EC CASE PRINT" BMP280 Pressure Sensor or MS5611 Pressure Sensor with pin CSB=1" BREAK
		$EE CASE PRINT" MS5611 Pressure Sensor with pin CSB=0" BREAK
        CASE@ $30 $3E WITHIN IF PRINT" MCP9808 Temperature Sensor" BREAK
        CASE@ $40 $4E WITHIN IF PRINT" I/O Expander" BREAK
        PRINT" UNKNOWN DEVICE"
        ;

pub lsi2c       
		CRLF PRINT" I2C DEVICES" CRLF
		PRINT" Address	Max clock	Identity"
		I2C? 
		IF 
			128 FOR 
					I 2* .I2C 
				NEXT
			CRLF
		THEN ;
		