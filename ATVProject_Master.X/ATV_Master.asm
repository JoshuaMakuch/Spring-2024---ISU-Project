;******************************************************************************
;                                                                             *
;    Filename:	    1788 Communications.asm			              *
;    Date:	    29 NOV 2023						      *
;    File Version:  1                                                         *
;    Author:        XAVIER HOSKINS                                            *
;    Company:       Idaho State University                                    *
;    Description:   Code for running the PIC16lf1788 as the Master board      *
;		    for the ATV project. This code handles reception of UART  *
;		    data and I2C Master communications.			      *
;		                                                              *
;******************************************************************************
;******************************************************************************
;                                                                             *
;    Revision History:                                                        *
;	1: MAIN FILE FOR PIC16LF1788 ATV PROJECT-SPECIFICS ON MAIN CODE SHOULD*
;	   BE LISTED HERE AS MODIFIED					      *
;	                                                                      *
;	    STARTED 29 NOV 2023                                               *
;		 -CURRENT VERSION IMPLEMENTED 9 DEC 2023		      *
;                                                                             *
;******************************************************************************
	

	LIST	    p=16LF1788
	INCLUDE	    P16LF1788.INC
	INCLUDE	    1788_COMMS_SETUP.INC
	
; CONFIG1
    ; __config 0xEFE4
    __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
; CONFIG2
    ; __config 0xFFFF
    __CONFIG _CONFIG2, _WRT_OFF  & _PLLEN_OFF & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_OFF

;suppress "not in bank 0" message,  Found label after column 1,
    errorlevel -302,-207,-305,-206,-203			
							


;******************************************		
;INTERUPT VECTORS
;******************************************
		ORG 	0X00					
 		GOTO 	SETUP		;RESET CONDITION GOTO SETUP
		ORG	0X04
		GOTO	INTERUPT	;INTERRUPT VECTOR

		
SETUP
		CALL	INITIALIZE
		GOTO MAIN
		
;******************************************
;INTERUPT SERVICE ROUTINE 
;******************************************
INTERUPT ;*********************************
		BANKSEL W_SAVE
		MOVWF W_SAVE				;SAVE W REGISTER
		MOVFW STATUS
		MOVWF STATUS_SAVE			;SAVE STATUS REGISTER
		
		BTFSC	PIR1,RCIF
		CALL	SAVE_DATA			
		BCF	PIR1,RCIF			;RESET INTERRUPT FLAGS

		BTFSC	INTCON,	TMR0IF
		CALL	KILLBOT			
		BCF	INTCON,	TMR0IF
		
		BANKSEL	STATUS_SAVE
		MOVFW STATUS_SAVE			
		MOVWF STATUS				;RESTORE STATUS REGISTER
		MOVFW W_SAVE				;RESTORE W REGISTER
		RETFIE					;RETURN, ENABLE INTERRUPTS

;******************************************
;  SUBROUTINES
;******************************************
ESTOP
		BANKSEL	CONECTION_STA
		BCF	CONECTION_STA,0
		GOTO SETUP
KILLBOT
		BANKSEL	CONECTION_STA
		BSF	CONECTION_STA,0
		GOTO STOP
		RETURN
CONECT_TMR
		BANKSEL TMR0
		CLRF	TMR0
		RETURN
SAVE_DATA ;********************************
		BANKSEL	COUNT
		INCF	COUNT				;INCREMENT COUNT3
		MOVFW	COUNT
		MOVWF	COUNT_CHECK
		MOVLW	0X01		    
		XORWF	COUNT_CHECK,0			;CHECK COUNT VALUE
		BTFSS	STATUS,Z
		GOTO	$ + 5
		CALL	CONECT_TMR
		BANKSEL	RC1REG
		MOVFW	RC1REG				;\IF COUNT IS 1, SAVE RECEIVED BYTE TO
		BANKSEL	BYTE_1				;/BYTE_1 REGISTER
		MOVWF	BYTE_1				
		BANKSEL	COUNT_CHECK			
		MOVLW	0X02				;CHECK IF COUNT IS 2
		XORWF	COUNT_CHECK,0
		BTFSS	STATUS,Z
		GOTO	$ + 5
		BANKSEL	RC1REG
		MOVFW	RC1REG
		BANKSEL	BYTE_1
		MOVWF	BYTE_2				;MOVE TO BYTE_2 REGISTER
		BANKSEL	COUNT_CHECK
		MOVLW	0X03				;CHECK IF COUNT IS 3
		XORWF	COUNT_CHECK,0
		BTFSS	STATUS,Z
		GOTO	$ + 5
		BANKSEL	RC1REG
		MOVFW	RC1REG
		BANKSEL	BYTE_1
		MOVWF	BYTE_3				;MOVE TO BYTE_3 REGISTER
		BANKSEL	COUNT_CHECK
		MOVLW	0X04				;CHECK IF COUNT IS 4
		XORWF	COUNT_CHECK,0
		BTFSS	STATUS,Z
		GOTO	$ + 5
		BANKSEL	RC1REG
		MOVFW	RC1REG
		BANKSEL	BYTE_1
		MOVWF	BYTE_4				;MOVE TO BYTE_4 REGISTER
		BANKSEL	COUNT_CHECK
		MOVLW	0X05				;CHECK IF COUNT IS 5
		XORWF	COUNT_CHECK,0
		BTFSS	STATUS,Z
		GOTO	$ + 5
		BANKSEL	RC1REG
		MOVFW	RC1REG
		BANKSEL	BYTE_1
		MOVWF	BYTE_5				;MOVE TO BYTE_5 REGISTER
		BANKSEL	COUNT_CHECK
		MOVLW	0X06				;CHECK IF COUNT IS 6
		XORWF	COUNT_CHECK,0			;*/IF COUNT IS NOT 6
		BTFSS	STATUS,Z			;/BAILOUT
		RETURN					
		BANKSEL	RC1REG
		MOVFW	RC1REG
		BANKSEL	BYTE_1
		MOVWF	BYTE_6				;MOVE TO BYTE_6 REGISTER
		BANKSEL	COUNT
		CLRF	COUNT
		BSF	RECEIVE,0			;SET RECEIVE FLAG
		RETURN
			
I2C_IDLE ;*********************************
		MOVLW	0X1F
		BANKSEL	SSP1CON2
		ANDWF	SSP1CON2,W			;CHECK 5 INDICATOR FLAGS
		BTFSS	STATUS,Z			;Z = 0, BUS IS BUSY
		GOTO I2C_IDLE				;LOOP UNTIL FREE
	CHECKR_W
		BANKSEL	SSP1STAT			;CHECK IF TX IN PROGRESS
		BTFSC	SSP1STAT,2			;R_W = 1, TX IN PROGRESS
		GOTO CHECKR_W				;LOOP UNTIL FREE
		RETURN
		
;******************************************
MAIN
;******************************************
		BANKSEL	RECEIVE
		BTFSS	RECEIVE,0
		GOTO	MAIN				;REPEAT IDLE STATE
		BANKSEL	RECEIVE
		BCF	RECEIVE,0			;RESET RECEIVE FLAG
		BANKSEL	BYTE_1
		MOVLW	0X24
		XORWF	BYTE_1,0			;VALIDATE HANDSHAKE BYTE
		BTFSS	STATUS,Z			;BAILOUT IF NOT VALID
		GOTO	MAIN	
		BANKSEL	BYTE_3				;TEST COMMAND BYTE
		MOVLW	0X46				;46 IS 'F', GOTO FORWARD
		XORWF	BYTE_3,0
		BTFSC	STATUS,Z
		GOTO	FORWARD
		MOVLW	0X42				;42 IS 'B', GOTO REVERSE
		XORWF	BYTE_3,0
		BTFSC	STATUS,Z
		GOTO	REVERSE
		MOVLW	0X74				;74 IS 't', GOTO TURN
		XORWF	BYTE_3,0
		BTFSC	STATUS,Z
		GOTO	TURN
		MOVLW	0X53				;53 IS 'S', GOTO STOP
		XORWF	BYTE_3,0
		BTFSC	STATUS,Z
		GOTO	STOP
		GOTO	MAIN				;IF NOT RECOGNIZED, BAILOUT
		
	FORWARD
		MOVLW	0X46				;MOVE 'F' TO COMMAND BYTE
		BANKSEL	DRIVE_COMMAND
		MOVWF	DRIVE_COMMAND
		MOVLW	DRIVE_ADD			;MOVE DRIVE ADDRESS TO 
		MOVWF	TEMP_ADD			;/TEMP_ADD
		BANKSEL	BYTE_4
		MOVFW	BYTE_4				;MOVE BYTE4 TO DATA BYTE
		BANKSEL	DRIVE_DATA			
		MOVWF	DRIVE_DATA			
		GOTO	I2C_SEND_DATA			;SEND DATA
		
	REVERSE
		MOVLW	0X42				;MOVE 'B' TO COMMAND BYTE
		BANKSEL	DRIVE_COMMAND
		MOVWF	DRIVE_COMMAND
		MOVLW	DRIVE_ADD			;MOVE DRIVE ADDRESS TO 
		MOVWF	TEMP_ADD			;/TEMP_ADD
		BANKSEL	BYTE_4
		MOVFW	BYTE_4				;MOVE BYTE4 TO DATA BYTE
		MOVWF	DRIVE_DATA			
		GOTO	I2C_SEND_DATA			;SEND DATA
	TURN
		MOVLW	0X54				;MOVE 'T' TO COMMAND BYTE
		BANKSEL	DRIVE_COMMAND
		MOVWF	DRIVE_COMMAND
		MOVLW	DRIVE_ADD			;MOVE DRIVE ADDRESS TO
		MOVWF	TEMP_ADD			;/TEMP_ADD
		BANKSEL	BYTE_4
		MOVFW	BYTE_4				;MOVE BYTE4 TO DATA BYTE
		BANKSEL	DRIVE_DATA
		MOVWF	DRIVE_DATA
		GOTO	I2C_SEND_DATA			;SEND DATA
		
	STOP
		MOVLW	0X44				;MOVE 'D' TO COMMAND BYTE
		BANKSEL	DRIVE_COMMAND
		MOVWF	DRIVE_COMMAND
		MOVLW	DRIVE_ADD			;MOVE DRIVE ADDRESS TO
		MOVWF	TEMP_ADD			;/TEMP_DATA
		MOVLW	0X17				;MOVE NEUTRAL VALUE TO DATA BYTE
		BANKSEL	DRIVE_DATA
		MOVWF	DRIVE_DATA
		GOTO	I2C_SEND_DATA			;SEND DATA
		
	I2C_SEND_DATA
		BANKSEL	SSP1CON2
		BSF	SSP1CON2,SEN			;GENERATE START CONDITION
		BTFSC	SSP1CON2,SEN
		GOTO	$ - 1
		BANKSEL	TEMP_ADD			;LOAD TEMP-DATA
		LSLF	TEMP_ADD			;SHIFT LEFT
		MOVFW	TEMP_ADD			;/THIS CREATES A MASTER WRITE ADDRESS
		BANKSEL	SSP1BUF
		MOVWF	SSP1BUF				;SEND ADDRESS
		
		CALL I2C_IDLE				;WAIT FOR IDLE
		    
		BANKSEL	DRIVE_COMMAND
		MOVFW	DRIVE_COMMAND			;SEND COMMAND BYTE
		BANKSEL	SSP1BUF
		MOVWF	SSP1BUF
		
		CALL I2C_IDLE				;WAIT FOR IDLE
		
		BANKSEL	DRIVE_DATA			;SEND DATA BYTE
		MOVFW	DRIVE_DATA
		BANKSEL	SSP1BUF
		MOVWF	SSP1BUF
		
		CALL I2C_IDLE				;WAIT FOR IDLE
		
		BANKSEL	SSP1CON2			;STOP COMMUNICATION
		BSF	SSP1CON2,PEN
		
		BANKSEL CONECTION_STA
		BTFSC	CONECTION_STA,0
		GOTO	ESTOP
		
		GOTO MAIN				;LOOP
		END

;********************END PROGRAM DIRECTIVE ***********************************
;*****************************************************************************
