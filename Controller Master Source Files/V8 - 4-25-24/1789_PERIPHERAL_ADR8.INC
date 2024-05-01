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
		
		CALL	I2C_IDLE_ADR8			;ENSURE I2C MODULE IS IDLE
	
		BANKSEL	SSPCON2
		BSF		SSPCON2,SEN		;GENERATE A START CONDITION
		
		CALL I2C_IDLE_ADR8
		
		MOVLW		B'00001000'		;ATTEMPT TO WRITE TO THE PERIPHERAL TO PROBE FOR AN ACKNOWLEDGE
		BANKSEL		SSP1BUF			;"08H - WRITE"
		MOVWF		SSP1BUF
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL SSP1CON2			;IF (ACKNOWLEDGE RECEIVED) THEN:
		BTFSC		SSP1CON2, ACKSTAT	    ;SET PERIPHERAL STATUS INDICATOR (ESTABLISHED COMMS)
		GOTO NEVER_ACKNOWLEDGED_ADR8			;ELSE:					    
		BANKSEL PERI_STATUS			    ;GOTO NEVER_ACKNOWLEDGED
		BSF		PERI_STATUS, 0		   
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL SSP1CON2			;GENERATE A STOP CONDITION
		BSF		SSP1CON2, PEN
		
		CALL I2C_IDLE_ADR8
		
		RETURN					;LEAVES PERIPHERAL_ADR8 FILE
		
;*** READ_FROM_PERIPHERAL_ADR8 **************
READ_FROM_PERIPHERAL_ADR8
		
		BANKSEL PORTD				;SET A TROUBLESHOOTING INDICATOR INCASE THE MASTER GETS STUCK
		BSF		PORTD, 5
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL	SSPCON2
		BSF		SSPCON2,SEN		;GENERATE A START CONDITION
		
		CALL I2C_IDLE_ADR8
		
		MOVLW		B'00001001'		;ATTEMPT TO ADDRESS PERIPHERAL "08H - READ"
		BANKSEL		SSP1BUF
		MOVWF		SSP1BUF
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL SSP1CON2			;IF (ACKNOWLEDGE RECIEVED) THEN:
		BTFSC		SSP1CON2, ACKSTAT	    ;CONTINUE
		GOTO NEVER_ACKNOWLEDGED_ADR8			;ELSE:
							    ;GOTO NEVER_ACKNOWLEDGED
		CALL I2C_IDLE_ADR8
		
		BANKSEL		SSP1CON2		;BEGIN CONTINOUS RECIEVE FOR 1ST BYTE
		BSF		SSP1CON2, RCEN
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL SSP1BUF				;PULL IN THE DATA FROM THE SLAVE (ENCODER 1 COUNT) 
		MOVFW		SSP1BUF
		BANKSEL TX_DATA_43H_VAR1		;PUSH THE DATA TO THE CANNON X-AXIS VARIABLE
		MOVWF		TX_DATA_43H_VAR1
		
		BANKSEL SSP1CON2
		BSF		SSP1CON2, ACKEN
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL		SSP1CON2		;BEGIN CONTINOUS RECIEVE FOR 2ND BYTE
		BSF		SSP1CON2, RCEN
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL SSP1BUF				;PULL IN THE DATA FROM THE SLAVE (ENCODER 2 COUNT)
		MOVFW		SSP1BUF
		BANKSEL TX_DATA_43H_VAR2		;PUSH THE DATA TO THE CANNON Y-AXIS VARIABLE
		MOVWF		TX_DATA_43H_VAR2
		
		BANKSEL SSP1CON2
		BSF		SSP1CON2, ACKEN
	
		CALL I2C_IDLE_ADR8	
		
		BANKSEL		SSP1CON2		;BEGIN CONTINOUS RECIEVE FOR 3RD BYTE
		BSF		SSP1CON2, RCEN
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL SSP1BUF				;PULL IN THE DATA FROM THE SLAVE (BUTTON STATUSES)
		MOVFW		SSP1BUF
		BANKSEL SHRT_TRM_REG
		MOVWF		SHRT_TRM_REG
		
		BANKSEL SHRT_TRM_REG
		MOVLW		0X00			;IF (REV (BTN_REG_1 BIT0/SHRT_TRM_REG BIT0)) THEN:
		BTFSC		SHRT_TRM_REG, 0		    ;SET REV INDICATOR (1) TO TX_DATA_63H_VAR1
		MOVLW		0X01			;ELSE:
		MOVWF		TX_DATA_63H_VAR1	    ;SET DON'T REV INDICATOR (0) TO TX_DATA_63H_VAR1
		MOVLW		0X00			;IF (FIRE (BTN_REG_1 BIT1/SHRT_TRM_REG BIT1)) THEN:
		BTFSC		SHRT_TRM_REG, 1		    ;SET FIRE INDICATOR (1) TO TX_DATA_63H_VAR2
		MOVLW		0X01			;ELSE:
		MOVWF		TX_DATA_63H_VAR2	    ;SET DON'T FIRE INDICATOR (0) TO TX_DATA_63H_VAR2
	
		CALL I2C_IDLE_ADR8	
		
		BANKSEL SSP1CON2			;GENERATE A STOP CONDITION
		BSF		SSP1CON2, PEN
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL PORTD
		BCF		PORTD, 5
		
		RETURN					;LEAVES PERIPHERAL_ADR8 FILE
;*** NEVER_ACKNOWLEDGED_ADR8 ****************
NEVER_ACKNOWLEDGED_ADR8
		
		BANKSEL PERI_STATUS			;CLEAR PERIPHERAL STATUS INDICATOR (LOSS/LACK OF COMMUNICATION)
		BCF		PERI_STATUS, 0
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL SSP1CON2			;GENERATE A STOP CONDITION
		BSF		SSP1CON2, PEN
		
		CALL I2C_IDLE_ADR8
		
		BANKSEL PORTD
		BCF		PORTD, 5
		
		RETURN					;LEAVES PERIPHERAL_ADR8 FILE
		
;********************************************
;FILE SPECIFIC SUBROUTINES
;********************************************
		
;*** I2C_IDLE *******************************
I2C_IDLE_ADR8
		BANKSEL PIR1
		BCF		PIR1, SSP1IF
I2C_IDLE_INNER_ADR8
		MOVLW 	B'00001111'			; Load Bus Test Value
		BANKSEL	SSPCON2		
		ANDWF		SSPCON2, 0		; Compare 1F to check for 5 busy conditions
		BANKSEL	STATUS
		BTFSS		STATUS,Z		;Test Zero Bit
		GOTO 		I2C_IDLE_INNER_ADR8	;Z=0  Bus is still busy -repeat
CHECKR_W_ADR8						;Z=1 Not Busy
		BANKSEL	SSP1STAT
		BTFSC 		SSP1STAT, R_NOT_W	; see if SSP is transmitting data
		GOTO 		CHECKR_W_ADR8		;R_W = 1 - Still transmitting data
		BANKSEL PORTD				;R_W = 0 - Transmit done
		BCF		PORTD, 5   
		RETURN				
	
;*** BAD1_ADR8 ******************************
BAD1_ADR8	
		MOVLW	0XFF				;SET RETURN CODE TO -1
		BANKSEL	SSPCON2
		BSF		SSPCON2,PEN		;GENERATE A STOP CONDITION
LOOP5_ADR8	
		BTFSC		SSPCON2,PEN		;IS STOP CONDITION DONE
		GOTO		LOOP5_ADR8
		RETURN
;********************************************