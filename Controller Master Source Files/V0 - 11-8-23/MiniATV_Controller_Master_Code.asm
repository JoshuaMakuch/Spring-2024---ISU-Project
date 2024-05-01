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
;	    STARTED Fbraury 7 2023 -                                          *
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
;INTERUPT VECTORS
;******************************************
		ORG 	H'000'					
 		GOTO 	SETUP		;RESET CONDITION GOTO SETUP
		ORG	H'004'
		GOTO	INTERUPT

		
SETUP
		CALL	INITIALIZE
		
		GOTO	MAIN

		
		
;******************************************
;INTERUPT SERVICE ROUTINE 
;******************************************

INTERUPT


		RETFIE


;******************************************
;  SUBROUTINES
;******************************************		
		
		
;******************************************
MAIN
;******************************************


		
		GOTO	MAIN			    ;REPEAT
		
		END

;********************END PROGRAM DIRECTIVE ***********************************
;*****************************************************************************









