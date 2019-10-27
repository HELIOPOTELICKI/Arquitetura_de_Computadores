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
		  org 0000h
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

	LEITURA:

		MOV DX, IO1
		IN  AL, DX

		CMP AL, 0000B
		JE  ESCREVE_0
		CMP AL, 0001B
		JE  ESCREVE_1
		CMP AL, 0010B
		JE  ESCREVE_2
		CMP AL, 0011B
		JE  ESCREVE_3
		CMP AL, 0100B
		JE  ESCREVE_4
		CMP AL, 0101B
		JE  ESCREVE_5
		CMP AL, 0110B
		JE  ESCREVE_6
		CMP AL, 0111B
		JE  ESCREVE_7
		CMP AL, 1000B
		JE  ESCREVE_8
		CMP AL, 1001B
		JE  ESCREVE_9
		CMP AL, 1010B
		JE  ESCREVE_A
		CMP AL, 1011B
		JE  ESCREVE_B
		CMP AL, 1100B
		JE  ESCREVE_C
		CMP AL, 1101B
		JE  ESCREVE_D
		CMP AL, 1110B
		JE  ESCREVE_E
		CMP AL, 1111B
		JE  ESCREVE_F

		JMP LEITURA

ESCREVE_0:
	MOV AL,0111111b
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_1:
	MOV AL,0000110b
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_2:
	MOV AL, 1011011B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_3:
	MOV AL, 1001111B
	MOV DX, IO2
	OUT DX,AL
	JMP LEITURA
ESCREVE_4:
	MOV AL, 1100110B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_5:
	MOV AL, 1101101B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_6:
	MOV AL, 1111101B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_7:
	MOV AL, 0000111B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_8:
	MOV AL, 1111111B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_9:
	MOV AL, 1101111B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_A:
	MOV AL, 1110111B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_B:
	MOV AL, 1111100B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_C:
	MOV AL, 0111001B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_D:
	MOV AL, 1011110B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_E:
	MOV AL, 1111001B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA
ESCREVE_F:
	MOV AL, 1110001B
	MOV DX, IO2
	OUT DX, AL
	JMP LEITURA

	CODE ENDS

	;MILHA PILHA
	STACK SEGMENT STACK      
	DW 128 DUP(?) 
	STACK ENDS 

	;MEUS DADOS
	DATA      SEGMENT  
	DATA 	  ENDS
	

	;EXTRA

	EXTRA SEGMENT
	EXTRA ENDS

	end inicio