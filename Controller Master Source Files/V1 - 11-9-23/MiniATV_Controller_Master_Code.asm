;******************************************************************************
;                                                                             *
;    Filename:	    MiniATV_Controller_Master_Code.asm			      *
;    Date:	    Novermber 6, 2023                                         *
;    File Version:  1                                                         *
;    Author:        Joshua Makuch                                             *
;    Company:       Idaho State University                                    *
;    Description:   Firmware for runing the Master PIC for the MiniATV	      *
;		    Controller						      *
;		                                                              *
;******************************************************************************
;******************************************************************************
;                                                                             *
;    Revision History:                                                        *
;	1: Basic setup for the PIC16LF1788. Test program for the dev board    *
;	   increments portb to indicate that the 1788 was soldered correctly  *
;	                                                                      *
;	    STARTED NOV 9 2023 -                                              *
;									      *
;                                                                             *
;******************************************************************************
	

	LIST	    p=16LF1788
	INCLUDE	    P16LF1788.INC
	INCLUDE	    1788_SETUP.INC
	
	; CONFIG1
; __config 0xEFE4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _WRT_OFF  & _PLLEN_OFF & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON

    ;suppress "not in bank 0" message,  Found label after column 1,
    errorlevel -302,-207,-305,-206,-203			
							
;******************************************		
;ORIGIN VECTORS & SETUP
;******************************************
		ORG 	H'000'					
 		GOTO 	SETUP				;RESET CONDITION GOTO SETUP
		ORG	H'004'
		GOTO	INTERUPT
SETUP
		CALL	INITIALIZE			;CALLS THE SETUP FILE 1788_SETUP.INC
		GOTO	MAIN
;******************************************
;INTERUPT SERVICE ROUTINE 
;******************************************
INTERUPT
		BANKSEL W_SAVE
		MOVWF		W_SAVE			;SAVE WORKING REGISTER CONTENTS
		BANKSEL	STATUS
		MOVFW		STATUS
		MOVWF		STATUS_SAVE		;SAVES STATUS REGISTER CONTENTS
		
		BANKSEL PIR1
		BTFSC	PIR1, TMR2IF			;IF TIMER2 INTERRUPT FLAG, THEN HANDLE TIMER COUNT
		CALL HANDLE_T2_INT
		
		BANKSEL STATUS_SAVE			;RECALL STATUS REGISTER CONTENTS
		MOVFW		STATUS_SAVE
		MOVWF		STATUS			;RESTORE STATUS REGISTER CONTENTS
		BANKSEL W_SAVE				
		MOVFW		W_SAVE			;RESTORE WORKING REGISTER CONTENTS
		
		RETFIE					;RETURN AND RESET INTERRUPT ENABLE BITS
;******************************************
;  SUBROUTINES
;******************************************
;*** STORE_PW1 *****************************************
STORE_PW1
		BANKSEL ADC_RESULT
		MOVFW		ADC_RESULT
		MOVWF		PW_CNT_1
		RETURN
;*** STORE_PW0 *****************************************
STORE_PW0
		BANKSEL ADC_RESULT
		MOVFW		ADC_RESULT
		MOVWF		PW_CNT_0
		RETURN
;*** CONVERSION_DONE ***********************************
CONVERSION_DONE
		
		BANKSEL ADRESH
		MOVFW		ADRESH	
		BANKSEL		ADC_RESULT
		MOVWF		ADC_RESULT
		SWAPF		ADC_RESULT		;SWAP NIBBLES OF ADC_RESULT
		MOVLW		H'00F'
		ANDWF		ADC_RESULT, 1		;AND THE ADC_RESULT WITH h0F, THIS CLEARS THE UPPER NIBBLE
		
		
		BANKSEL	ADCON0				;IF (ANALOG CHANNEL = AN1) THEN:
		BTFSC		ADCON0, 2		;STORE ADC_RESULT INTO PW_CNT_1
		CALL STORE_PW1				;ELSE (ANALOG CHANNEL = AN0) THEN:
		BANKSEL ADCON0				;STORE ADC_RESULT INTO PW_CNT_0
		BTFSS		ADCON0, 2		
		CALL STORE_PW0
		
		BANKSEL ADCON0				;IF (ANALOG CHANNEL = AN0) THEN:
		MOVLW		B'10000101'		;SETS ANALOG CHANNEL TO AN1
		BTFSC		ADCON0, 2		;ELSE:
		MOVLW		B'10000001'		;SETS ANALOG CHANNEL TO AN0
		MOVWF		ADCON0
		
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BANKSEL ADCON0
		BSF		ADCON0, 1		;BEGIN A NEW CONVERSION
		
		RETURN
;*** HANDLE T2_INT *************************************
HANDLE_T2_INT
		
		BANKSEL PIR1				;PG.36
		BCF		PIR1, TMR2IF		;TMR2 INTERRUPT FLAG RESET
		
		BANKSEL TMR_CNT
		DECFSZ	TMR_CNT				;IF ? COUNTS OF TMR_CNT HAS OCCURED, RESET THE COUNT
		RETURN
		
		MOVLW		D'020'
		MOVWF		TMR_CNT
		
		BANKSEL		ADCON0
		BTFSS		ADCON0, 1		;THIS WILL TEST IF A CONVERSION IS DONE
		CALL CONVERSION_DONE
		
		RETURN
;******************************************
MAIN
;******************************************
		
		BANKSEL PORTA				
		BTFSC		PORTA, 2		;IF (BUTTON1) THEN: 
		BSF		PORTC, 7		;SET BUTTON 1 INDICATOR
		BTFSS		PORTA, 2		;ELSE:
		BCF		PORTC, 7		;CLEAR BUTTON 1 INDICATOR
		
		BANKSEL PORTA				
		BTFSC		PORTA, 3		;IF (BUTTON2) THEN: 
		BSF		PORTC, 6		;SET BUTTON 2 INDICATOR
		BTFSS		PORTA, 3		;ELSE:
		BCF		PORTC, 6		;CLEAR BUTTON 2 INDICATOR
		
		BANKSEL PORTA				
		BTFSC		PORTA, 4		;IF (BUTTON3) THEN: 
		BSF		PORTC, 5		;SET BUTTON 3 INDICATOR
		BTFSS		PORTA, 4		;ELSE:
		BCF		PORTC, 5		;CLEAR BUTTON 3 INDICATOR
		
		BANKSEL PORTA				
		BTFSC		PORTA, 5		;IF (BUTTON4) THEN: 
		BSF		PORTC, 2		;SET BUTTON 4 INDICATOR
		BTFSS		PORTA, 5		;ELSE:
		BCF		PORTC, 2		;CLEAR BUTTON 4 INDICATOR
		
		BANKSEL STATUS				;PG.31
		MOVFW		PW_CNT_0		;IF (PW_CNT_0 > TMR_CNT) THEN:
		SUBWF		TMR_CNT, 0		;SET PORTC BIT0 (F/B STICK INDICATOR)
		BTFSS		STATUS,	C		;ELSE:
		BSF		PORTC,	0		;CLEAR PORTC BIT0 (F/B STICK INDICATOR)
		BTFSC		STATUS, C
		BCF		PORTC, 0
		
		BANKSEL STATUS				;PG.31
		MOVFW		PW_CNT_1		;IF (PW_CNT_1 > TMR_CNT) THEN:
		SUBWF		TMR_CNT, 0		;SET PORTC BIT1 (L/R STICK INDICATOR)
		BTFSS		STATUS,	C		;ELSE:
		BSF		PORTC,	1		;CLEAR PORTC BIT1 (L/R STICK INDICATOR)
		BTFSC		STATUS, C
		BCF		PORTC, 1
		
		BANKSEL PORTB				;STORES THE ROBOT ADDRESS INTO RBT_ADR AND CLEARS THE FINAL BIT
		MOVFW		PORTB
		MOVWF		RBT_ADR
		BCF		RBT_ADR, 7
	
		GOTO	MAIN			    ;REPEAT
		END
;********************END PROGRAM DIRECTIVE ***********************************
;*****************************************************************************









