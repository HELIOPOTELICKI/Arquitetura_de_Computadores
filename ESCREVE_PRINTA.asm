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

		CALL INICIALIZA_8251

REPETE:
		MOV BX, OFFSET TEXTO
		CALL RECEBE_MENSAGEM
		
		MOV AL,13
		CALL MANDA_CARACTER
		MOV AL,10
		CALL MANDA_CARACTER

		MOV BX, OFFSET TEXTO
		CALL MANDA_MENSAGEM

		MOV AL,13
		CALL MANDA_CARACTER
		MOV AL,10
		CALL MANDA_CARACTER


		JMP REPETE
		

				
		MOV SEGUNDOS_UNID, 0
		MOV SEGUNDOS_DEZ,  0
MOSTRA:		
		CALL DISPLAY
		JMP MOSTRA

DISPLAY:
		PUSH AX
		PUSH BX
		PUSH DX
		MOV BL, SEGUNDOS_UNID
		MOV BH, 0
		MOV AL, TABELA[BX]
		MOV DX, IO3
		OUT DX, AL
		MOV BL, SEGUNDOS_DEZ
		MOV BH, 0
		MOV AL, TABELA[BX]
		MOV DX, IO2
		OUT DX, AL
		POP DX
		POP BX
		POP AX
		RET
		
DELAY:	PUSH CX
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
		JE ZERA_SEGUNDOS_UNID
		JMP SAI_INTERRUPT_RELOGIO
ZERA_SEGUNDOS_UNID:
		MOV SEGUNDOS_UNID, 0
		INC SEGUNDOS_DEZ
		CMP SEGUNDOS_DEZ, 6
		JE ZERA_SEGUNDOS_DEZ
		JMP SAI_INTERRUPT_RELOGIO	 
ZERA_SEGUNDOS_DEZ:
		MOV SEGUNDOS_DEZ, 0		
SAI_INTERRUPT_RELOGIO:
		POPF
		IRET

; 8251A USART 

ADR_USART_DATA EQU  (IO8 + 00h)
;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251

ADR_USART_CMD  EQU  (IO8 + 02h)
;É O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251

ADR_USART_STAT EQU  (IO8 + 02h)
;RETORNA O STATUS SE UM CARACTER FOI DIGITADO
;RETORNA O STATUS SE POSSO TRANSMITIR CARACTER PARA O TERMINAL

INICIALIZA_8251:                                     
   MOV AL,0
   MOV DX, ADR_USART_CMD
   OUT DX,AL
   OUT DX,AL
   OUT DX,AL
   MOV AL,40H
   OUT DX,AL
   MOV AL,4DH
   OUT DX,AL
   MOV AL,37H
   OUT DX,AL
   RET

RECEBE_CARACTER:
   PUSHF
   PUSH DX
AGUARDA_CARACTER:
   MOV DX, ADR_USART_STAT
   IN  AL,DX
   TEST AL,2
   JZ AGUARDA_CARACTER
   MOV DX, ADR_USART_DATA
   IN AL,DX
   SHR AL,1
NAO_RECEBIDO:
   POP DX
   POPF
   RET

MANDA_CARACTER:
   PUSHF
   PUSH DX
   PUSH AX  ; SALVA AL   
BUSY:
   MOV DX, ADR_USART_STAT
   IN  AL,DX
   TEST AL,1
   JZ BUSY
   MOV DX, ADR_USART_DATA
   POP AX  ; RESTAURA AL
   OUT DX,AL
   POP DX
   POPF
   RET 

MANDA_MENSAGEM:
	PUSHF
	PUSH AX
	INC BX ; PULA TAMANHO DA MENSAGEM
MANDA_MENSAGEM_CARACTER:
	MOV AL,[BX]
	CMP AL,0
	JE FIM_MANDA_MENSAGEM
	CALL MANDA_CARACTER
	INC BX
	JMP MANDA_MENSAGEM_CARACTER
FIM_MANDA_MENSAGEM:
	POP AX
	POPF
	RET

RECEBE_MENSAGEM:
	PUSHF
	PUSH AX
	INC BX ; APONTE PARA O PAYLOAD, NAO APONTE PARA O TAMANHO
RECEBE_MENSAGEM_CARACTER:
	CALL RECEBE_CARACTER
	CMP  AL,13
	JE SAI_RECEBE_CARACTER
	CMP  AL, 8  ; BACKSPACE
	JE   CONSISTE_BACKSPACE	
	CMP  CONTADOR_LETRAS,32
	JE   RECEBE_MENSAGEM_CARACTER
IMPRIME_SALVA:
	CALL MANDA_CARACTER
	MOV [BX],AL
	INC BX
	INC CONTADOR_LETRAS
	JMP RECEBE_MENSAGEM_CARACTER
CONSISTE_BACKSPACE:
	CMP CONTADOR_LETRAS,0
	JE  RECEBE_MENSAGEM_CARACTER
	DEC BX
	DEC CONTADOR_LETRAS
	CALL MANDA_CARACTER ; EXCLUSIVO PARA IMPRIMIR BACKSPACE
	JMP RECEBE_MENSAGEM_CARACTER
SAI_RECEBE_CARACTER:
	MOV AL,0
	MOV [BX],AL
	MOV BX, OFFSET TEXTO ; APONTA PARA CAMPO TAMANHO DE TEXTO
	MOV AL, CONTADOR_LETRAS ; PEGA
	MOV [BX],AL
	POP AX
	POPF
	RET


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
	SEGUNDOS_DEZ  DB 0

	TEXTO DB ?,33 DUP("X")
	CONTADOR_LETRAS DB 0
	




	MENSAGEM DB "HELIO POTELICKI",13,10,0

	

	DATA 	  ENDS
	

	;EXTRA

	EXTRA SEGMENT
	EXTRA ENDS

	end inicio