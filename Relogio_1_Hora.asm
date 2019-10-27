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

   TAM_STRING EQU 200

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

   ; ASCENDE OS LEDS VERDES
   MOV DX, IO1
   IN AL, DX
   MOV DX, IO0
   MOV AL, 11111111B
   OUT DX, AL

   ; LIGA OS DISPLAYS
   CALL DISPLAY
   
   ;INICIALIZA PARTE COM O TERMINAL
   CALL INICIALIZA_8251

   MOV BX, OFFSET TITULO ;MOVE A VARIAVEL COM O TITULO E EXIBE
   CALL MANDA_MENSAGEM

   MOV BX, OFFSET TEXTO ; APONTA PARA VARIAVEL QUE IRA RECEBER A PALAVRA
   INC CENSURADO ;ATIVA A CENSURA
   CALL MANDA_PARA_TERMINAL ; MANDA PALAVRA CENSURADA PARA O TERMINAL
   DEC CENSURADO ;DESATIVA A CENSURA
   
   CALL PULA_LINHA
   CALL PULA_LINHA

   CALL PALAVRA_PARCIAL

ADIVINHA_PALAVRA:
   CALL VERIFICA_SE_ACABOU
   CMP ACABOU, 1
   JE FIM_DE_JOGO

   MOV BX, OFFSET TENTATIVA 
   CALL MANDA_MENSAGEM

   MOV BX, OFFSET LETRA_DIGITADA
   CALL MANDA_PARA_TERMINAL
   CALL PROCURA ; PEGA A LETRA DIGITADA E PROCURA NA PALAVRA

   CALL PULA_LINHA
   
   MOV BX, OFFSET ENCONTRADAS
   CALL MANDA_MENSAGEM
   
   MOV BX, OFFSET TRACO
   CALL MANDA_MENSAGEM
   
   CALL PULA_LINHA
   CALL PULA_LINHA

   JMP ADIVINHA_PALAVRA

FIM_DE_JOGO:
   CALL PULA_LINHA
   MOV BX, OFFSET FIM
   CALL MANDA_MENSAGEM
   CALL PULA_LINHA
   MOV BX, OFFSET PALAVRA
   CALL MANDA_MENSAGEM
   MOV BX, OFFSET TEXTO
   CALL MANDA_MENSAGEM
   
   MOV HORAS_DEZ,        0
   MOV HORAS_UNID,       0
   MOV MINUTOS_DEZ,      0
   MOV MINUTOS_UNID,    13
   MOV SEGUNDOS_DEZ,    12
   MOV SEGUNDOS_UNID,   15
   CALL DISPLAY
   
LOOP_FINALIZA:
   JMP LOOP_FINALIZA

; 8251A USART 

ADR_USART_DATA EQU  (IO8 + 00h)
;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251

ADR_USART_CMD  EQU  (IO8 + 02h)
;É O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251

ADR_USART_STAT EQU  (IO8 + 02h)
;RETORNA O STATUS SE UM CARACTER FOI DIGITADO
;RETORNA O STATUS SE POSSO TRANSMITIR CARACTER PARA O TERMINAL 


INICIALIZA_8251:                                     
   MOV AL, 0
   MOV DX, ADR_USART_CMD
   OUT DX, AL
   OUT DX, AL
   OUT DX, AL
   MOV AL, 40H
   OUT DX, AL
   MOV AL, 4DH
   OUT DX, AL
   MOV AL, 37H
   OUT DX, AL
   RET 

MENSAGEM_MAIUSCULO:
   PUSHF
   PUSH AX
IGNORA_CARACTER_MAISCULO:
   INC BX ; PARA PULAR TAMANHO
   MOV AL, [BX]
   CMP AL,  0
   JE SAI_MENSAGEM_MAIUSCULO
   CMP AL, 'a'
   JL  IGNORA_CARACTER_MAISCULO
   CMP AL, 'z'
   JG  IGNORA_CARACTER_MAISCULO
   MOV AL,32
   SUB [BX],AL ; LE CARACTERE DA MEMORIA, SUBTRAI 32 E ESCREVE NOVAMENTE NA MEMORIA
   JMP IGNORA_CARACTER_MAISCULO
SAI_MENSAGEM_MAIUSCULO:
   POP AX
   POPF
   RET

   
PALAVRA_PARCIAL:
   PUSHF
   PUSH AX
   PUSH CX

   MOV BX, OFFSET TEXTO
   MOV CL, 0
   INC BX ; PULA O TAMANHO DO TEXTO

CONTA_LETRA:
   MOV AL, [BX]
   CMP AL, 0
   JE FIM_CONTA_LETRA
   INC CX
   INC BX
   JMP CONTA_LETRA

FIM_CONTA_LETRA:
   MOV BX, OFFSET TRACO
   INC BX
   ADD BX, CX
   MOV AL, 0
   MOV [BX], AL

   POP CX
   POP AX
   POPF
   RET

PROCURA:
   PUSHF
   PUSH AX
   PUSH CX
   MOV CL, 0
   MOV BX, OFFSET TEXTO
   INC BX ; CONTEM A PALAVRA DIGITADA
   MOV SI, OFFSET LETRA_DIGITADA
   INC SI ; CONTEM A LETRA DIGITADA

PROCURA_LETRA_A_SER_PREENCHIDA:
   MOV AL, [BX]
   CMP AL, 0
   JE SAI_PROCURA_LETRA
   CMP AL, [SI]
   JE PREENCHE_LETRA
CONTINUA_PROCURAR_LETRAS:
   INC BX
   INC CL
   JMP PROCURA_LETRA_A_SER_PREENCHIDA
SAI_PROCURA_LETRA:
   POP CX
   POP AX
   POPF
   RET

PREENCHE_LETRA:
   PUSH BX
   MOV BX, OFFSET TRACO
   INC BX
   ADD BX, CX
   MOV [BX], AL
   POP BX
   JMP CONTINUA_PROCURAR_LETRAS

VERIFICA_SE_ACABOU:
   PUSHF
   PUSH AX
   PUSH BX
   MOV BX, OFFSET TRACO
   INC BX
CHECAGEM:
   MOV AL, [BX]
   CMP AL, 0
   JE ACABA
   CMP AL, '_'
   JE CONTINUA
   INC BX
   JMP CHECAGEM
CONTINUA:
   MOV ACABOU, 0
   POP BX
   POP AX
   POPF
   RET
ACABA:
   MOV ACABOU, 1
   POP BX
   POP AX
   POPF
   RET

MANDA_CARACTER:
   PUSHF
   PUSH DX
   PUSH AX
BUSY:
   MOV DX, ADR_USART_STAT
   IN  AL, DX
   TEST AL, 1
   JZ BUSY
   MOV DX, ADR_USART_DATA
   POP AX
   OUT DX, AL
   POP DX
   POPF
   RET 

MANDA_MENSAGEM:
   PUSHF
   PUSH AX
   INC BX ; PULA TAMANHO DO TEXTO
MANDA_MENSAGEM_CARACTER:
   MOV AL, [BX]
   CMP AL, 0
   JE FIM_MANDA_MENSAGEM
   CALL MANDA_CARACTER
   INC BX
   JMP MANDA_MENSAGEM_CARACTER
FIM_MANDA_MENSAGEM:
   POP AX
   POPF
   RET

RECEBE_CARACTER:
   PUSHF
   PUSH DX
AGUARDA_CARACTER:
   MOV DX, ADR_USART_STAT
   IN  AL, DX
   TEST AL, 2
   JZ AGUARDA_CARACTER
   MOV DX, ADR_USART_DATA
   IN AL, DX
   SHR AL,1
NAO_RECEBIDO:
   POP DX
   POPF
   RET

MANDA_PARA_TERMINAL:
   PUSHF
   PUSH AX
   INC BX
   MOV CONTADOR_LETRAS, 0
RECEBE_MENSAGEM_CARACTER:
   CALL RECEBE_CARACTER
   CMP AL, 13
   JE SAI_RECEBE_CARACTER
   CMP AL, 8
   JE CONSISTE_BACKSPACE
   CMP CONTADOR_LETRAS,TAM_STRING
   JE RECEBE_MENSAGEM_CARACTER
   CMP AL, 'a'
   JL GUARDA_CARACTER
   CMP AL, 'z'
   JG GUARDA_CARACTER
   SUB AL, 32
GUARDA_CARACTER:
   MOV [BX],AL
   CMP CENSURADO, 1
   JE ESCONDE
   JMP IMPRIME_CARACTER
ESCONDE:
   MOV AL, 42
   IMPRIME_CARACTER:
   CALL MANDA_CARACTER
   INC BX
   INC CONTADOR_LETRAS
   JMP RECEBE_MENSAGEM_CARACTER
CONSISTE_BACKSPACE:
   CMP CONTADOR_LETRAS, 0
   JE  RECEBE_MENSAGEM_CARACTER
   DEC BX
   DEC CONTADOR_LETRAS
   CALL MANDA_CARACTER
   JMP RECEBE_MENSAGEM_CARACTER
SAI_RECEBE_CARACTER:
   MOV AL, 0
   MOV [BX], AL
   MOV BL, CONTADOR_LETRAS
   MOV AL, CONTADOR_LETRAS
   MOV [BX], AL
   POP AX
   POPF
   RET

PULA_LINHA:
   PUSHF
   PUSH AX
   MOV AL, 13
   CALL MANDA_CARACTER
   MOV AL, 10
   CALL MANDA_CARACTER
   POP AX
   POPF
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

DISPLAY:
   PUSH AX
   PUSH BX
   PUSH DX

   MOV BL, HORAS_DEZ
   MOV BH, 0
   CALL DELAY
   MOV AL, TABELA[BX]
   MOV DX, IO7
   OUT DX, AL
   MOV BL, HORAS_UNID
   MOV BH, 0
   CALL DELAY
   MOV AL, TABELA[BX]
   MOV DX, IO6
   OUT DX, AL
   
   MOV BL, MINUTOS_DEZ
   MOV BH, 0
   CALL DELAY
   MOV AL, TABELA[BX]
   MOV DX, IO5
   OUT DX, AL
   MOV BL, MINUTOS_UNID
   MOV BH, 0
   CALL DELAY
   MOV AL, TABELA[BX]
   MOV DX, IO4
   OUT DX, AL

   MOV BL, SEGUNDOS_DEZ
   MOV BH, 0
   CALL DELAY
   MOV AL, TABELA[BX]
   MOV DX, IO3
   OUT DX, AL
   MOV BL, SEGUNDOS_UNID
   MOV BH, 0
   CALL DELAY
   MOV AL, TABELA[BX]
   MOV DX, IO2
   OUT DX, AL

   POP DX
   POP BX
   POP AX
   RET
  
DELAY:
   PUSH CX
   MOV CX, 1111111111111111B

DELAY_DEC:
   DEC CX
   CMP CX, 0
   JE DELAY_SAI
   JMP DELAY_DEC

DELAY_SAI:
   POP CX
   RET  
 
CODE ENDS

;MILHA PILHA
STACK SEGMENT STACK  

DW 128 DUP(?)

STACK ENDS 

;MEUS DADOS
DATA SEGMENT

  ; ARMAZENA AS LETRAS MOSTRADAS NO DISPLAY
  TABELA DB 1000000b,1110110b,0111111b,1110111b
	 DB 0111001b,1110111b,1111101b,0000111b
	 DB 1111111b,1101111b,1110111b,1111100b
	 DB 0000110b,1110001b,0110111b,0110111b

   ; DEFINE QUAIS LETRAS SERAM MOSTRADAS
   SEGUNDOS_UNID DB 5
   SEGUNDOS_DEZ DB  4
   MINUTOS_UNID DB  3
   MINUTOS_DEZ DB   2
   HORAS_UNID DB   13
   HORAS_DEZ DB     0
 
   CONTADOR_LETRAS DB 0
   CENSURADO DB 0
   ACABOU DB 0

   TITULO DB " DESENVOLVIDO POR: HELIO & ARIEL",13,13,"DIGITE UMA PALAVRA PARA INICIAR O DESAFIO:",13,10,0
   TENTATIVA DB ?, "TENTE ADIVINHAR A PALAVRA ESCONDIDA",13,"DIGITE UMA LETRA:  ",10,0
   ENCONTRADAS DB ?, "CONTINUE TENTANDO, ENCONTROU: ", 0
   FIM DB ?, "FIM_DO_JOGO", 0

   TEXTO DB ?, TAM_STRING + 1 DUP(?) ; ARMAZENA PALAVRA DIGITADA
   LETRA_DIGITADA DB 1, ?, 0
   TRACO DB ?, TAM_STRING + 1 DUP("_"), 0 ; CRIA OS TRACOS
   PALAVRA DB ?, "A PALAVRA MISTERIOSA ERA: ",0 
   
DATA ENDS

EXTRA SEGMENT

EXTRA ENDS

end inicio