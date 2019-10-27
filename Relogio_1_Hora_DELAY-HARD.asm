	; I/O Address Bus decode - every device gets 0x200 addresses */

	IO0  EQU  0000h
	IO1  EQU  0200h
	IO2  EQU  0400h
	IO3  EQU  0600h
	IO4  EQU  0800h
	IO5  EQU  0A00h
	IO6  EQU  0C00h
	IO7  EQU  0E00h
	IO8  EQU  1000h
	IO9  EQU  1200h
	IO10 EQU  1400h
	IO11 EQU  1600h
	IO12 EQU  1800h
	IO13 EQU  1A00h
	IO14 EQU  1C00h
	IO15 EQU  1E00h

	;MEU CODIGO
	CODE  SEGMENT 
		  ASSUME DS:DATA
		  org 0000h
		  
		  org 0008h
		  DW OFFSET RELOGIO
		  DW SEG    RELOGIO
		  
	;RESERVADO PARA VETOR DE INTERRUPCOES
		  org 0400h
	;MEU CODIGO
	inicio:
		MOV AX,DATA
		MOV DS,AX   ; DS AGORA APONTA PARA DATA SEGMENT
		MOV AX,EXTRA
		MOV ES,AX   ; ES AGORA APONTA PARA EXTRA SEGMENT
		MOV AX,STACK
		MOV SS,AX   ; SS AGORA APONTA PARA STACK SEGMENT

		
		MOV SEGUNDOS_UNID, 0
		MOV SEGUNDOS_DEZ, 0
		MOV MINUTOS_UNID, 0
		MOV MINUTOS_DEZ, 0
MOSTRA:		
		CALL DISPLAY
		CALL DELAY
		CALL DELAY
		CALL DELAY

	 JMP MOSTRA

DISPLAY:
		PUSH AX
		PUSH BX
		PUSH DX
		MOV BL, SEGUNDOS_UNID
		MOV BH, 0
		MOV AL, TABELA[BX]
		MOV DX, IO2
		OUT DX, AL
		MOV BL, SEGUNDOS_DEZ
		MOV BH, 0
		MOV AL, TABELA[BX]
		MOV DX, IO3
		OUT DX, AL
		
		MOV BL, MINUTOS_UNID
		MOV BH, 0
		MOV AL, TABELA[BX]
		MOV DX, IO4
		OUT DX, AL
		MOV BL, MINUTOS_DEZ
		MOV BH, 0
		MOV AL, TABELA[BX]
		MOV DX, IO5
		OUT DX, AL
		
		POP DX
		POP BX
		POP AX
		RET

DELAY:	
		PUSH CX
		MOV CX, 65535

DEC_CX:
		DEC CX
		CMP CX, 0
		JE  SAI_DELAY
		JMP DEC_CX

SAI_DELAY:
		POP CX
		RET

RELOGIO:
		PUSHF	
		INC SEGUNDOS_UNID
		CMP SEGUNDOS_UNID, 10
		JE SEGUNDOS_UNID_ZERA
		JMP SAI_INTERRUPT_RELOGIO

SEGUNDOS_UNID_ZERA:
		MOV SEGUNDOS_UNID, 0
		INC SEGUNDOS_DEZ
		CMP SEGUNDOS_DEZ, 6
		JE SEGUNDOS_DEZ_ZERA
		JMP SAI_INTERRUPT_RELOGIO
		
SEGUNDOS_DEZ_ZERA:
		MOV SEGUNDOS_DEZ, 0
		
		INC MINUTOS_UNID
		CMP MINUTOS_UNID, 10
		JE MINUTOS_UNID_ZERA
		JMP SAI_INTERRUPT_RELOGIO
		
MINUTOS_UNID_ZERA:
		MOV MINUTOS_UNID, 0
		INC MINUTOS_DEZ
		CMP MINUTOS_DEZ, 6
		JE MINUTOS_DEZ_ZERA
		JMP SAI_INTERRUPT_RELOGIO
		
MINUTOS_DEZ_ZERA:
		MOV MINUTOS_DEZ, 0
		
SAI_INTERRUPT_RELOGIO:
		POPF
		IRET

	CODE ENDS

	;MILHA PILHA
	STACK SEGMENT STACK      
	DW 128 DUP(?) 
	STACK ENDS 

	;MEUS DADOS
	DATA      SEGMENT  

	TABELA DB 0111111b,0000110b,1011011b,1001111b
		   DB 1100110b,1101101b,1111101b,0000111b
		   DB 1111111b,1101111b,1110111b,1111100b
		   DB 0111001b,1011110b,1111001b,1110001b

	SEGUNDOS_UNID DB 0
	SEGUNDOS_DEZ DB 0
	MINUTOS_UNID DB 0
	MINUTOS_DEZ DB 0

	DATA 	  ENDS
	

	;EXTRA

	EXTRA SEGMENT
	EXTRA ENDS

	end inicio