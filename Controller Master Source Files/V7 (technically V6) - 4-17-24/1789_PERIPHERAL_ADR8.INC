;******************************************************************************
;                                                                             *
;    Filename:	    1789_PERIPHERAL_ADR8.INC				      *
;    Date:	    APRIL 9,  2024                                            *
;    File Version:  1                                                         *
;    Author:        JOSHUA MAKUCH                                             *
;    Company:       Idaho State University                                    *
;    Description:   Source file for the peripheral controller I2C protocol    *
;									      *		
;   STARTED APRIL 9, 2024 - CURRENT VERSION IMPLEMENTED			      *
;******************************************************************************

;******************************************************************************
;                                                                             *
;    Revision History:                                                        *
;	1: This handles all protocols for peripheral communication for the    *
;	   MINIATV peripheral controller. Currently, it can do two way comms  *
;	   with LED indication of incoming data as well as loss of comms.     *
;									      *
;******************************************************************************	
	    
;*****************************************************
;START OF FILE
;*****************************************************		
		
;*** IDENTIFY_PERIPHERAL_ADR8 ***************
IDENTIFY_PERIPHERAL_ADR8
		
		CALL		I2C_IDLE		;ENSURE I2C MODULE IS IDLE
		BANKSEL	SSPCON2
		BSF		SSPCON2,SEN		;GENERATE A START CONDITION
		BTFSC		SSPCON2,SEN		;WAIT UNTIL START CONDITION IS COMPLETED
		GOTO 		$ - 1
		
		BANKSEL INFO_REG
		BTFSC		INFO_REG, 5
		GOTO LOCK_COND_1
		GOTO LOCK_COND_2
LOCK_COND_1
		MOVLW		B'00001001'		;ATTEMPT TO ADDRESS PERIPHERAL "08H - READ"
		MOVWF		SHRT_TRM_REG
		GOTO LOCK_COND_END
LOCK_COND_2
		MOVLW		B'00001000'		;ATTEMPT TO ADDRESS PERIPHERAL "08H - WRITE"
		MOVWF		SHRT_TRM_REG
		
		BANKSEL	SHRT_TRM_REG
		MOVWF		SHRT_TRM_REG
		;MOVLW		B'00001000'		;ATTEMPT TO ADDRESS PERIPHERAL "08H - WRITE"
		BANKSEL		SSP1BUF
		MOVWF		SSP1BUF
		
		CALL I2C_IDLE
		
		BANKSEL SSP1CON2
		BTFSC		SSP1CON2, ACKSTAT
		GOTO NEVER_ACKNOWLEDGED
		
		CALL I2C_IDLE
		
		BANKSEL SSP1CON2			;GENERATE A STOP CONDITION
		BSF		SSP1CON2, PEN
		
		RETURN
		
LOCK_COND_END
		BANKSEL	SHRT_TRM_REG
		MOVWF		SHRT_TRM_REG
		;MOVLW		B'00001000'		;ATTEMPT TO ADDRESS PERIPHERAL "08H - WRITE"
		BANKSEL		SSP1BUF
		MOVWF		SSP1BUF
		
		CALL I2C_IDLE
		
		BANKSEL SSP1CON2
		BTFSC		SSP1CON2, ACKSTAT
		GOTO NEVER_ACKNOWLEDGED
		
		CALL I2C_IDLE
		
		BANKSEL		SSP1CON2		;BEGIN CONTINOUS RECIEVE
		BSF		SSP1CON2, RCEN
		
		CALL I2C_IDLE
		
		BANKSEL SSP1BUF				;PULL IN THE DATA FROM THE SLAVE
		MOVFW		SSP1BUF
		BANKSEL PORTD
		MOVWF		PORTD
		
		BANKSEL SSP1CON2
		BSF		SSP1CON2, ACKEN
		
		CALL I2C_IDLE
		
		BANKSEL		SSP1CON2		;BEGIN CONTINOUS RECIEVE
		BSF		SSP1CON2, RCEN
		
		CALL I2C_IDLE
		
		BANKSEL SSP1BUF				;PULL IN THE DATA FROM THE SLAVE
		MOVFW		SSP1BUF
		BANKSEL PORTD
		MOVWF		PORTD
		
		BANKSEL SSP1CON2
		BSF		SSP1CON2, ACKEN
	
		CALL I2C_IDLE	
		
		BANKSEL		SSP1CON2		;BEGIN CONTINOUS RECIEVE
		BSF		SSP1CON2, RCEN
		
		CALL I2C_IDLE
		
		BANKSEL SSP1BUF				;PULL IN THE DATA FROM THE SLAVE
		MOVFW		SSP1BUF
		BANKSEL PORTD
		MOVWF		PORTD
	
		CALL I2C_IDLE	
		
		BANKSEL SSP1CON2			;GENERATE A STOP CONDITION
		BSF		SSP1CON2, PEN
		
		RETURN					;LEAVES PERIPHERAL_ADR8 FILE
		
NEVER_ACKNOWLEDGED
		
		BANKSEL PORTD
		MOVLW		0XAA
		MOVWF		PORTD
		
		BANKSEL SSP1CON2			;GENERATE A STOP CONDITION
		BSF		SSP1CON2, PEN
		
		RETURN
		
;*** I2C_IDLE *******************************
I2C_IDLE
		MOVLW 	0X1F				; Load Bus Test Value (00011111)
		BANKSEL	SSPCON2		
		ANDWF 	SSPCON2, 0			; Compare 1F to check for 5 busy conditions
		BANKSEL	STATUS
		BTFSS		STATUS,Z		;Test Zero Bit
		GOTO 		I2C_IDLE		;Z=0  Bus is still busy -repeat
CHECKR_W						;Z=1 Not Busy
		BANKSEL	SSP1STAT
		BTFSC 		SSP1STAT, R_NOT_W	; see if SSP is transmitting data
		GOTO 		CHECKR_W		;R_W = 1 - Still transmitting data
		RETURN					;R_W = 0 - Transmit done
	
;*** BAD1 ***********************************
BAD1	
		MOVLW	0XFF				;SET RETURN CODE TO -1
		BANKSEL	SSPCON2
		BSF		SSPCON2,PEN		;GENERATE A STOP CONDITION
LOOP5	
		BTFSC		SSPCON2,PEN		;IS STOP CONDITION DONE
		GOTO		LOOP5
		RETURN
		
;*** WAIT_FOR_TRANSMIT_BUFFER ****************
WAIT_FOR_TRANSMIT_BUFFER
		BANKSEL		SSP1STAT		;WAT FOR TRANSMIT BUFFER TO EMPTY
		BTFSC		SSP1STAT, BF
		GOTO WAIT_FOR_TRANSMIT_BUFFER
		
		RETURN
;*** WAIT_FOR_RECEIVED_BUFFER ****************
WAIT_FOR_RECEIVED_BUFFER
		BANKSEL		SSP1STAT		;WAT FOR TRANSMIT BUFFER TO EMPTY
		BTFSC		SSP1STAT, BF
		GOTO WAIT_FOR_RECEIVED_BUFFER
		
		RETURN
;******************************************************
