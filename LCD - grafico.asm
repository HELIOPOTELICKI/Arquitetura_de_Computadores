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

; REGISTRADORES DA CONTROLADORA 8255

   ADR_PPI_PORTA	EQU  (IO9)       ; 0a00h
   ADR_PPI_PORTB	EQU  (IO9 + 02h) ; 0a02
   ADR_PPI_PORTC	EQU  (IO9 + 04h) ; 0a04
   ADR_PPI_CONTROL	EQU  (IO9 + 06h) ; 0a06

   PPI_PORTA_INP	EQU  10h
   PPI_PORTA_OUT	EQU  00h
   PPI_PORTB_INP	EQU  02h
   PPI_PORTB_OUT	EQU  00h
   PPI_PORTCL_INP	EQU  01h
   PPI_PORTCL_OUT	EQU  00h
   PPI_PORTCH_INP	EQU  08h
   PPI_PORTCH_OUT	EQU  00h
   PPI_MODE_BCL_0	EQU  00h
   PPI_MODE_BCL_1	EQU  04h
   PPI_MODE_ACH_0	EQU  00h
   PPI_MODE_ACH_1	EQU  20h
   PPI_MODE_ACH_2	EQU  40h
   PPI_ACTIVE	EQU  80h 

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

   CALL INICIALIZA_8251
   CALL INICIALIZA_8255_PORTB_OUTPUT
   
   MOV BX, OFFSET TITULO
   CALL MANDA_MENSAGEM
   
   CALL GLCD_ATIVA
   CALL GLCD_CLR

   MOV BX, OFFSET TEXTO
   CALL RECEBE_MENSAGEM
   
   CALL REPETICOES 
   
   CALL INSERE_BASE_LCD ; COLOCA OS NUMEROS BASE
   
   MOV AH, 0  ;DEFINIDO COLUNA 
   MOV AL, 53 ;DEFININDO LINHA
   MOV BH, 1  ; ASCENDER OS PIXELS
   
GRAFICO_BASE:
   MOV TRACO, 0
   INC TAMANHO
   CALL GLCD_DRAW_POINT ; COLOCA UM PIXEL NAS COORDENADAS AH - AL
   
PULA:
   CMP TRACO, 4
   JE SAI_ROTINA 
   INC TRACO
   INC AH
   CALL GLCD_DRAW_POINT ; COLOCA UM PIXEL NAS COORDENADAS AH - AL
   JMP PULA 

SAI_ROTINA: 
   CMP TAMANHO, 10
   JE FIM_BASE
 
   ADD AH, 4 ; DA ESPACO ENTRE TRACOS

   JMP GRAFICO_BASE
   
FIM_BASE:
   MOV AH, 0 ; DEFINIDO COLUNA 
   SUB AL, 2 ; DEFININDO LINHA
   MOV BH, 1 ; ASCENDER OS PIXELS

   MOV SI, OFFSET REPETICOES_DIGITADOS
   INC SI
   MOV CX, 10
   
GRAFICO_REPETICOES:
   PUSH CX
   MOV CL,[SI]
   SUB CL, 48
   
   CALL CHAMA_GRAFICO
   ADD AH,8
   INC SI
   POP CX
   LOOP GRAFICO_REPETICOES
   JMP $
  
AUMENTA_VEZES_NUMERO: 
   SUB AL,48
   MOV AH,0
   MOV BX,AX
   INC REPETICOES_DIGITADOS[BX]
   RET

CHAMA_GRAFICO:
   PUSHF
   PUSH AX
   CMP CX,0
   JE FIM_MOSTRA_GRAFICO
   
MOSTRA_GRAFICO:
   CALL COLOCA_GRAFICO_RESULTADO
   SUB AL, 2
   LOOP MOSTRA_GRAFICO
   
FIM_MOSTRA_GRAFICO:
   POP AX
   POPF
   RET

COLOCA_GRAFICO_RESULTADO:
   PUSH AX
   PUSH CX
   MOV CX,5

GRAFICO_ESCREVE:
   CALL GLCD_DRAW_POINT
   INC AH
   LOOP GRAFICO_ESCREVE
   CALL INSERE_RESULTADO_LCD ; PRINTA A VARIAVEL COM AS REPETICOES 
   
   POP CX
   POP AX  
   RET

;======================================= FIM MEU CODIGO =======================================;

   MOV SEGUNDOS_UNID, 0
   MOV SEGUNDOS_DEZ,  0
   
MOSTRA:		
   CALL DISPLAY
   JMP MOSTRA

REPETICOES:
   PUSHF
   PUSH AX
   PUSH CX
   MOV CX, 0
   MOV SI, OFFSET TEXTO
   INC SI

REPETE_ACHA_LETRA:
   CMP SI, 0
   JE SAI_ACHA_LETRA
   MOV BX, OFFSET REPETICOES_DIGITADOS
   INC BX
   MOV AL, [SI]
   SUB AL, 48
   ADD BL, AL
   MOV AL, [BX]
   INC AL
   MOV [BX], AL
   INC SI
   JMP REPETE_ACHA_LETRA
 
SAI_ACHA_LETRA:
   POP CX
   POP AX
   POPF

INSERE_BASE_LCD:
   PUSHF
   PUSH CX
   MOV CL, 0

CONTA:
   CMP CL, 10
   JE SAI_CONTA
   MOV AH, CL
   MOV AL, 7
   CALL GLCD_GOTO_XY_TEXT
   MOV AL, CL
   ADD AL, 48
   CALL PRINT_CAR
   INC CL
   JMP CONTA

SAI_CONTA:
   POP CX
   POPF
   RET

INSERE_RESULTADO_LCD:
   PUSHF
   PUSH AX
   PUSH BX
   PUSH CX
   MOV CL, 0
   MOV BX, OFFSET REPETICOES_DIGITADOS
   INC BX

CONTA_RESULTADO:
   CMP CL, 10
   JE SAI_CONTA_RESULTADO
   MOV AH, CL
   MOV AL, 0
   CALL GLCD_GOTO_XY_TEXT
   MOV AL, [BX]
   CALL PRINT_CAR
   INC CL
   INC BX
   JMP CONTA_RESULTADO
   
SAI_CONTA_RESULTADO:
   POP CX
   POP BX
   POP AX
   POPF
   RET	
   
INVERTE_MENSAGEM:
   PUSHF
   PUSH AX
   PUSH CX
   MOV CL, [BX] ; CL PEGA O TAMANHO DO TEXTO
   CMP CL,0 ; SE STRING VAZIA, IGNORA TUDO
   JE FIM_INVERTE_MENSAGEM
   MOV AL, [BX] ; AL CONTEM O TAMANHO DO TEXTO
   MOV AH, 0 ; LIMPA AH PARA SOMA COM AX (PAI DE AL)
   ADD BX, AX
PROCURA_INVERTE_CARACTER:
   MOV AL, [BX]
   CALL MANDA_CARACTER
   DEC BX ; VOLTA CARACTER
   DEC CL
   CMP CL,0
   JNE PROCURA_INVERTE_CARACTER
FIM_INVERTE_MENSAGEM:		
   POP CX
   POP AX
   POPF
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

PULA_LINHA:
   PUSHF
   PUSH AX
   MOV AL,13
   CALL MANDA_CARACTER
   MOV AL,10
   CALL MANDA_CARACTER
   POP AX
   POPF
   RET

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
   MOV CONTADOR_LETRAS,0
   
RECEBE_MENSAGEM_CARACTER:

   CMP CONTADOR_LETRAS,50
   JE SAI_RECEBE_CARACTER
   
   CALL RECEBE_CARACTER
   CMP  AL,13
   JE SAI_RECEBE_CARACTER
   CMP  AL, 8  ; BACKSPACE
   JE   CONSISTE_BACKSPACE	
   CMP  CONTADOR_LETRAS,TAM_STRING
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

;---------------------------------------------------------
;ROTINAS PARA 8255   
;CONFIGURA PORTA E PORTB COMO SAIDAS
INICIALIZA_8255_PORTB_OUTPUT:
   PUSHF
   PUSH AX
   PUSH DX
   MOV DX, ADR_PPI_CONTROL
   MOV AL,0
   OR AL,PPI_PORTA_OUT
   OR AL,PPI_PORTB_OUT  
   OR AL,PPI_PORTCL_INP
   OR AL,PPI_PORTCH_INP
   OR AL,PPI_MODE_BCL_0
   OR AL,PPI_MODE_ACH_0
   OR AL,PPI_ACTIVE
   OUT DX,AL
   POP DX
   POP AX
   POPF
   RET

;INICIALIZA PORTB E "PORTC" COMO ENTRADA
INICIALIZA_8255_PORT_INPUT:
   PUSHF
   PUSH AX
   PUSH DX
   MOV DX, ADR_PPI_CONTROL
   MOV AL,0
   OR AL,PPI_PORTA_OUT
   OR AL,PPI_PORTB_INP
   OR AL,PPI_PORTCL_INP
   OR AL,PPI_PORTCH_INP
   OR AL,PPI_MODE_BCL_0
   OR AL,PPI_MODE_ACH_0
   OR AL,PPI_ACTIVE
   OUT DX,AL
   POP DX
   POP AX
   POPF
   RET

;MANDA AL PARA PORTA
MANDA_PORT_A:
   PUSHF
   PUSH DX
   MOV DX,ADR_PPI_PORTA
   OUT DX,AL
   POP DX
   POPF
   RET

;MANDA AL PARA PORTB
MANDA_PORT_B:
   PUSHF
   PUSH DX
   MOV DX,ADR_PPI_PORTB
   OUT DX,AL
   POP DX
   POPF
   RET

;LE PORTB E JOGA EM AL
LE_PORT_B:
   PUSHF
   PUSH DX
   MOV DX,ADR_PPI_PORTB
   IN AL,DX
   POP DX
   POPF
   RET

;LE PORTC E JOGA EM AL
LE_PORT_C:
   PUSHF
   PUSH DX
   MOV DX,ADR_PPI_PORTC
   IN AL,DX
   POP DX
   POPF
   RET
;---------------------------------------------------------

;LIGA DISPLAY
GLCD_ON:
   CALL GLCD_CS1_LOW
   CALL GLCD_CS2_LOW
   CALL GLCD_RS_LOW
   CALL GLCD_RW_LOW
   MOV AL,03FH
   CALL MANDA_PORT_B
   CALL ENABLE_PULSE
   RET   

;------------------------------------
;POSICIONA "CURSOR" NA COLUNA
GLCD_GOTO_COL:
   PUSHF
   PUSH AX

   CALL GLCD_RS_LOW
   CALL GLCD_RW_LOW
   CMP AH,64
   JL LEFT

   CALL GLCD_CS2_LOW
   CALL GLCD_CS1_HIGH
   SUB AH,64
   MOV COL_DATA,AH
   JMP SAI_GOTO_COL

LEFT:
   CALL GLCD_CS1_LOW
   CALL GLCD_CS2_HIGH
   MOV COL_DATA,AH

SAI_GOTO_COL:
   OR COL_DATA, 40H
   AND COL_DATA, 7FH
   MOV AL,COL_DATA
   CALL MANDA_PORT_B
   CALL ENABLE_PULSE
   POP AX
   POPF
   RET
;------------------------------------

;------------------------------------
;POSICIONA "CURSOR" NA COLUNA
GLCD_GOTO_COL_TEXT:
   PUSHF
   PUSH AX
   PUSH BX

   PUSH AX
   MOV BL,8
   MOV AL,AH
   MUL BL
   MOV BL,AL
   POP AX
   MOV AH,BL

   CALL GLCD_RS_LOW
   CALL GLCD_RW_LOW
   CMP AH,64
   JL LEFT_TEXT

   CALL GLCD_CS2_LOW
   CALL GLCD_CS1_HIGH
   SUB AH,64
   MOV COL_DATA,AH
   JMP SAI_GOTO_COL_TEXT

LEFT_TEXT:
   CALL GLCD_CS1_LOW
   CALL GLCD_CS2_HIGH
   MOV COL_DATA,AH

SAI_GOTO_COL_TEXT:
   OR COL_DATA, 40H
   AND COL_DATA, 7FH
   MOV AL,COL_DATA
   CALL MANDA_PORT_B
   CALL ENABLE_PULSE
   POP BX
   POP AX
   POPF
   RET
;------------------------------------

;------------------------------------
;POSICIONA "CURSOR" NA LINHA
GLCD_GOTO_ROW:
   PUSH AX
   CALL GLCD_RS_LOW
   CALL GLCD_RW_LOW
   OR AL,0B8H
   AND AL,0BFH
   MOV COL_DATA,AL
   CALL MANDA_PORT_B
   CALL ENABLE_PULSE
   POP AX
   RET
;------------------------------------

;------------------------------------
;POSICIONA "CURSOR" NA LINHA
GLCD_GOTO_ROW_TEXT:
   PUSH AX
   CALL GLCD_RS_LOW
   CALL GLCD_RW_LOW
   OR AL,0B8H
   AND AL,0BFH
   MOV COL_DATA,AL
   CALL MANDA_PORT_B
   CALL ENABLE_PULSE
   POP AX
   RET
;------------------------------------

;------------------------------------   
; AH LINHA E  AL COLUNA
; POSICIONAMENTO DO "CURSOR" EM LINHA X COLUNA
; MODO GRAFICO (128x64)
GLCD_GOTO_XY:
   CALL GLCD_GOTO_COL
   CALL GLCD_GOTO_ROW
   RET
;;------------------------------------   

;------------------------------------   
; AH LINHA E  AL COLUNA
; POSICIONAMENTO DO "CURSOR" EM LINHA X COLUNA
; COLUNAS 16 (0..15), LINHAS 8 (0..7)
GLCD_GOTO_XY_TEXT:
   CALL GLCD_GOTO_COL_TEXT
   CALL GLCD_GOTO_ROW_TEXT
   RET
;------------------------------------   

; AL = DATA
GLCD_WRITE:
   CALL GLCD_RS_HIGH
   CALL GLCD_RW_LOW
   CALL MANDA_PORT_B
   CALL ENABLE_PULSE
   RET

;AL = DATA  
GLCD_CLRLN:   
   PUSHF
   PUSH AX
   PUSH CX
   MOV AH,0
   CALL GLCD_GOTO_XY
   MOV AH,64
   CALL GLCD_GOTO_XY
   CALL GLCD_CS1_LOW
   MOV AL,0
   MOV CX,64
   
ESCREVA:   
   CALL GLCD_WRITE
   LOOP ESCREVA
   POP CX
   POP AX
   POPF
   RET

;---------------------------------------------------------
;APAGA DISPLAY GRAFICO
GLCD_CLR:
   PUSHF
   PUSH AX
   MOV AL,0
   
CLRLN:   
   CALL GLCD_CLRLN
   ADD AL,1
   CMP AL,8
   JNE CLRLN
   POP AX
   POPF
   RET
;---------------------------------------------------------

;---------------------------------------------------------
;DESENHA UM PONTO NESTAS COORDENADAS
;AH, AL, BH
;COLUNAS MODO GRAFICO = 128 (0..127) AH
;LINHAS MODO GRAFICO = 64 (0..63) AL
;BH = 0 PIXEL APAGADO, BH=1 PIXEL ACESO
GLCD_DRAW_POINT:
   PUSHF
   PUSH AX
   PUSH BX
   PUSH CX

   PUSH AX ; SALVA AH, AL
   PUSH AX ; SALVA AH, AL

   MOV CH,AH ; SALVA AH
   MOV AH,0

   MOV BL,8
   DIV BL

   MOV AH,CH
   CALL GLCD_GOTO_XY

   POP AX  ; RESTAURA AH, AL

   CMP BH,0
   JE LIGHT_SPOT

   MOV AH,0
   MOV BH,8
   DIV BH
; AH RESTO
   MOV CL,AH
   MOV AL,1
   SHL AL,CL
   MOV COL_DATA_AUX,AL

   MOV AH,CH
   CALL GLCD_READ_DATA
   OR COL_DATA_AUX,AL

   JMP SAI_GLCD_DRAW_POINT

LIGHT_SPOT:
   MOV AH,0
   MOV BH,8
   DIV BH
; AH RESTO
   MOV CL,AH
   MOV AL,1
   SHL AL,CL
   NOT AL
   MOV COL_DATA_AUX,AL
   MOV AH,CH
   CALL GLCD_READ_DATA
   AND COL_DATA_AUX,AL

SAI_GLCD_DRAW_POINT:
   POP AX

   MOV CH,AH ; SALVA AH
   MOV AH,0

   MOV BL,8
   DIV BL

   MOV AH,CH
   CALL GLCD_GOTO_XY

   MOV AL, COL_DATA_AUX
   CALL GLCD_WRITE
   
   POP CX
   POP BX
   POP AX
   POPF
   RET 
;---------------------------------------------------------

;---------------------------------------------------------
;LE STATUS DO DISPLAY
GLCD_READ_DATA:
   CALL INICIALIZA_8255_PORT_INPUT
   CALL GLCD_RW_HIGH
   CALL GLCD_RS_HIGH
   CMP AH,63
   JG  HAB_CS2

HAB_CS1:
   CALL GLCD_CS2_HIGH
   CALL GLCD_CS1_LOW
   JMP HAB

HAB_CS2:
   CALL GLCD_CS2_LOW
   CALL GLCD_CS1_HIGH

HAB:
   CALL GLCD_EN_HIGH
   CALL GLCD_EN_LOW
   CALL GLCD_EN_HIGH
   CALL LE_PORT_B
   MOV READ_DATA,AL
   CALL GLCD_EN_LOW
   CALL INICIALIZA_8255_PORTB_OUTPUT
   RET
;---------------------------------------------------------

;---------------------------------------------------------
; AL = INDICE CARACTER FONT (COMECA EM 0)
; IMPRIME CARACTER NA LINHA E COLUNA DEFINIDA
PRINT_CAR:
   PUSHF
   PUSH AX
   PUSH BX
   PUSH CX
   MOV BL,5
   MUL BL
   MOV BX,AX
   MOV CX,5
   
PRINTING_CAR:
   MOV AL,FONTS[BX]
   CALL GLCD_WRITE
   INC BX
   LOOP PRINTING_CAR
   POP CX
   POP BX
   POP AX
   POPF
   RET

;---------------------------------------------------------
; AH = COLUNA, AL=LINHA
; PRIMEIRO BYTE DO VETOR É NUMERO DE LINHAS E COLUNAS OCUPADAS
; EXEMPLO, IMAGEM DE 24X24 PIXELS = 3 LINHAS X 3 COLUNAS
PRINT_ICON:
   PUSHF
   PUSH AX
   PUSH CX
   MOV CL,  DS:[SI]  
   MOV QNT_COLUNAS, CL ; QNT COLUNAS IMPRESSAS
   MOV SALVA_QNT_COLUNAS, CL ; GUARDA QNT PARA NOVO LACO QNT COLUNAS IMPRESSAS
   MOV POS_COLUNAS, AH ; COLUNA PASSADA COMO PARAMETRO
   MOV CL,  DS:[SI+1]
   MOV LINHA, CL ;LINHA
   ADD SI,2    ; APONTA PARA ICONE...
   
PRINT:
   MOV CX,8
   CALL GLCD_GOTO_XY_TEXT
   
PRINTING_ICON:
   PUSH AX
   MOV AL,DS:[SI]
   CALL GLCD_WRITE
   POP  AX
   INC SI
   LOOP PRINTING_ICON
   INC AH
   DEC QNT_COLUNAS
   JNE PRINT	
   MOV AH,SALVA_QNT_COLUNAS
   MOV QNT_COLUNAS,AH
   MOV AH,POS_COLUNAS
   INC AL
   DEC LINHA
   JNE PRINT	
   POP CX
   POP AX
   POPF
   RET

;---------------------------------------------------------
;ESTA ROTINA IMPRIME O GRAFICO APONTADO POR SI
PLOT_BMP:
   PUSHF
   PUSH AX
   PUSH SI
   MOV AL,0
   MOV AH,0
   
PLOT:
   CALL GLCD_GOTO_XY
   PUSH AX
   MOV AL,[SI]
   CALL GLCD_WRITE
   POP AX
   INC SI
   INC AH
   CMP AH,127
   JNE PLOT
   MOV AH,0
   INC AL
   CMP AL,8
   JNE PLOT
   POP SI
   POP AX
   POPF 
   RET
;---------------------------------------------------------

;---------------------------------------------------------
;ATIVA O GLCD
GLCD_ATIVA:
   CALL GLCD_CS1_HIGH
   CALL GLCD_CS2_HIGH
   CALL GLCD_RST_HIGH
   CALL GLCD_ON
   RET
;---------------------------------------------------------

;---------------------------------------------------------
;ESTAS ROTINAS APENAS GERAM PULSOS PARA O DISPLAY GRAFICO
GLCD_CS1_HIGH:
   PUSHF
   PUSH AX
   OR  GLCD_CONTROL, 32
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_CS1_LOW:
   PUSHF
   PUSH AX
   MOV AL, 32
   NOT AL
   AND  GLCD_CONTROL, AL
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_CS2_HIGH:
   PUSHF
   PUSH AX
   OR  GLCD_CONTROL, 16
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_CS2_LOW:
   PUSHF
   PUSH AX
   MOV AL, 16
   NOT AL
   AND  GLCD_CONTROL, AL
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_RST_HIGH:
   PUSHF
   PUSH AX
   OR  GLCD_CONTROL, 1
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_RST_LOW:
   PUSHF
   PUSH AX
   MOV AL, 1
   NOT AL
   AND  GLCD_CONTROL, AL
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_EN_HIGH:
   PUSHF
   PUSH AX
   OR  GLCD_CONTROL, 2
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_EN_LOW:
   PUSHF
   PUSH AX
   MOV AL, 2
   NOT AL
   AND  GLCD_CONTROL, AL
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_RW_HIGH:
   PUSHF
   PUSH AX
   OR  GLCD_CONTROL, 4
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_RW_LOW:
   PUSHF
   PUSH AX
   MOV AL, 4
   NOT AL
   AND  GLCD_CONTROL, AL
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_RS_HIGH:
   PUSHF
   PUSH AX
   OR  GLCD_CONTROL, 8
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

GLCD_RS_LOW:
   PUSHF
   PUSH AX
   MOV AL, 8
   NOT AL
   AND  GLCD_CONTROL, AL
   MOV AL,GLCD_CONTROL
   CALL MANDA_PORT_A
   POP AX
   POPF
   RET

ENABLE_PULSE:
   CALL GLCD_EN_HIGH
   CALL GLCD_EN_LOW
   RET

CODE ENDS

;MILHA PILHA
STACK SEGMENT STACK      
   DW 128 DUP(?) 
STACK ENDS 

;MEUS DADOS
DATA      SEGMENT  

   GLCD_CONTROL DB 0
   GLCD_DATA    DB 0
   COL_DATA DB 0
   COL_DATA_AUX DB 0
   READ_DATA DB 0
   LINHA DB 0

   QNT_COLUNAS DB 0
   SALVA_QNT_COLUNAS DB 0
   POS_COLUNAS DB 0

   MIGUEL DB 8,4
   DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH,07FH,07FH,07FH,07FH,07FH,07FH
   DB 07FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH
   DB 03FH,03FH,01FH,01FH,01FH,01FH,01FH,03FH,03FH,03FH,03FH,03FH,03FH,07FH,07FH,07FH
   DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
   DB 0FFH,0FFH,0FFH,0FFH,07FH,03FH,003H,011H,040H,040H,010H,010H,010H,070H,030H,070H
   DB 070H,070H,040H,040H,000H,000H,000H,000H,000H,000H,000H,000H,0C0H,0C0H,0E0H,0E0H
   DB 0E0H,0E0H,0E0H,0F0H,0F0H,0F8H,0F8H,078H,018H,038H,078H,07CH,0F8H,0F8H,0F8H,0F8H
   DB 0FCH,0FFH,0DFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
   DB 0FFH,0FFH,0FFH,0FFH,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
   DB 000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,003H,007H,037H,07FH,07FH
   DB 07FH,06FH,0EFH,07FH,0FFH,0FFH,0FBH,071H,0C1H,000H,000H,000H,000H,000H,003H,003H
   DB 003H,003H,000H,001H,001H,001H,07BH,0FDH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
   DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FCH,0F8H,0F0H,0F0H,0F0H,040H,000H,000H,000H
   DB 001H,001H,001H,001H,003H,003H,003H,003H,003H,002H,002H,002H,002H,002H,002H,007H
   DB 007H,007H,007H,007H,007H,067H,067H,073H,0F1H,0F0H,0F0H,0F0H,0F0H,0F0H,0F0H,070H
   DB 070H,0F0H,0F8H,0FCH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH,07FH,07FH

   MIGUEL2 DB 8,4
   DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH,07FH,07FH,07FH,07FH,07FH,07FH
   DB 07FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH,03FH
   DB 03FH,03FH,01FH,01FH,01FH,01FH,01FH,03FH,03FH,03FH,03FH,03FH,03FH,07FH,07FH,07FH
   DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
   DB 0FFH,0FFH,0FFH,0FFH,07FH,03FH,003H,011H,040H,0C0H,010H,050H,0D0H,0F0H,0B0H,070H
   DB 070H,0F0H,0C0H,040H,000H,000H,000H,000H,000H,000H,000H,000H,0C0H,0C0H,0E0H,0E0H
   DB 0E0H,0E0H,0E0H,0F0H,0F0H,0F8H,0F8H,078H,018H,038H,078H,07CH,0F8H,0F8H,0F8H,0F8H
   DB 0FCH,0FFH,0DFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
   DB 0FFH,0FFH,0FFH,0FFH,080H,000H,000H,000H,000H,001H,003H,002H,002H,002H,002H,002H
   DB 003H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,003H,007H,037H,07FH,07FH
   DB 07FH,06FH,0EFH,07FH,0FFH,0FFH,0FBH,071H,0C1H,000H,000H,000H,000H,000H,003H,003H
   DB 003H,003H,000H,001H,001H,001H,07BH,0FDH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
   DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FCH,0F8H,0F0H,0F0H,0F0H,040H,000H,000H,000H
   DB 001H,001H,001H,001H,003H,003H,003H,003H,003H,002H,002H,002H,002H,002H,002H,007H
   DB 007H,007H,007H,007H,007H,067H,067H,073H,0F1H,0F0H,0F0H,0F0H,0F0H,0F0H,0F0H,070H
   DB 070H,0F0H,0F8H,0FCH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH,07FH,07FH

   FONTS  	DB      32*5 DUP(0)
   DB	00H, 00H, 00H, 00H, 00H ; (space)
   DB	00H, 00H, 5FH, 00H, 00H ; !
   DB	00H, 07H, 00H, 07H, 00H ; "
   DB	14H, 7FH, 14H, 7FH, 14H ; #
   DB	24H, 2AH, 7FH, 2AH, 12H ; $
   DB	23H, 13H, 08H, 64H, 62H ; %
   DB	36H, 49H, 55H, 22H, 50H ; &
   DB	00H, 05H, 03H, 00H, 00H ; '
   DB	00H, 1CH, 22H, 41H, 00H ; (
   DB	00H, 41H, 22H, 1CH, 00H ; )
   DB	08H, 2AH, 1CH, 2AH, 08H ; *
   DB	08H, 08H, 3EH, 08H, 08H ; +
   DB	00H, 50H, 30H, 00H, 00H ; H,
   DB	08H, 08H, 08H, 08H, 08H ; -
   DB	00H, 60H, 60H, 00H, 00H ; .
   DB	20H, 10H, 08H, 04H, 02H ; /
   DB	3EH, 51H, 49H, 45H, 3EH ; 0
   DB	00H, 42H, 7FH, 40H, 00H ; 1
   DB	42H, 61H, 51H, 49H, 46H ; 2
   DB	21H, 41H, 45H, 4BH, 31H ; 3
   DB	18H, 14H, 12H, 7FH, 10H ; 4
   DB	27H, 45H, 45H, 45H, 39H ; 5
   DB	3CH, 4AH, 49H, 49H, 30H ; 6
   DB	01H, 71H, 09H, 05H, 03H ; 7
   DB	36H, 49H, 49H, 49H, 36H ; 8
   DB	06H, 49H, 49H, 29H, 1EH ; 9
   DB	00H, 36H, 36H, 00H, 00H ; :
   DB	00H, 56H, 36H, 00H, 00H ; ;
   DB	00H, 08H, 14H, 22H, 41H ; <
   DB	14H, 14H, 14H, 14H, 14H ; =
   DB	41H, 22H, 14H, 08H, 00H ; >
   DB	02H, 01H, 51H, 09H, 06H ; ?
   DB	32H, 49H, 79H, 41H, 3EH ; @
   DB	7EH, 11H, 11H, 11H, 7EH ; A
   DB	7FH, 49H, 49H, 49H, 36H ; B
   DB	3EH, 41H, 41H, 41H, 22H ; C
   DB	7FH, 41H, 41H, 22H, 1CH ; D
   DB	7FH, 49H, 49H, 49H, 41H ; E
   DB	7FH, 09H, 09H, 01H, 01H ; F
   DB	3EH, 41H, 41H, 51H, 32H ; G
   DB	7FH, 08H, 08H, 08H, 7FH ; H
   DB	00H, 41H, 7FH, 41H, 00H ; I
   DB	20H, 40H, 41H, 3FH, 01H ; J
   DB	7FH, 08H, 14H, 22H, 41H ; K
   DB	7FH, 40H, 40H, 40H, 40H ; L
   DB	7FH, 02H, 04H, 02H, 7FH ; M
   DB	7FH, 04H, 08H, 10H, 7FH ; N
   DB	3EH, 41H, 41H, 41H, 3EH ; O
   DB	7FH, 09H, 09H, 09H, 06H ; P
   DB	3EH, 41H, 51H, 21H, 5EH ; Q
   DB	7FH, 09H, 19H, 29H, 46H ; R
   DB	46H, 49H, 49H, 49H, 31H ; S
   DB	01H, 01H, 7FH, 01H, 01H ; T
   DB	3FH, 40H, 40H, 40H, 3FH ; U
   DB	1FH, 20H, 40H, 20H, 1FH ; V
   DB	7FH, 20H, 18H, 20H, 7FH ; W
   DB	63H, 14H, 08H, 14H, 63H ; X
   DB	03H, 04H, 78H, 04H, 03H ; Y
   DB	61H, 51H, 49H, 45H, 43H ; Z
   DB	00H, 00H, 7FH, 41H, 41H ; [
   DB	02H, 04H, 08H, 10H, 20H ; "\"
   DB	41H, 41H, 7FH, 00H, 00H ; ]
   DB	04H, 02H, 01H, 02H, 04H ; ^
   DB	40H, 40H, 40H, 40H, 40H ; _
   DB	00H, 01H, 02H, 04H, 00H ; `
   DB	20H, 54H, 54H, 54H, 78H ; a
   DB	7FH, 48H, 44H, 44H, 38H ; b
   DB	38H, 44H, 44H, 44H, 20H ; c
   DB	38H, 44H, 44H, 48H, 7FH ; d
   DB	38H, 54H, 54H, 54H, 18H ; e
   DB	08H, 7EH, 09H, 01H, 02H ; f
   DB	08H, 14H, 54H, 54H, 3CH ; g
   DB	7FH, 08H, 04H, 04H, 78H ; h
   DB	00H, 44H, 7DH, 40H, 00H ; i
   DB	20H, 40H, 44H, 3DH, 00H ; j
   DB	00H, 7FH, 10H, 28H, 44H ; k
   DB	00H, 41H, 7FH, 40H, 00H ; l
   DB	7CH, 04H, 18H, 04H, 78H ; m
   DB	7CH, 08H, 04H, 04H, 78H ; n
   DB	38H, 44H, 44H, 44H, 38H ; o
   DB	7CH, 14H, 14H, 14H, 08H ; p
   DB	08H, 14H, 14H, 18H, 7CH ; q
   DB	7CH, 08H, 04H, 04H, 08H ; r
   DB	48H, 54H, 54H, 54H, 20H ; s
   DB	04H, 3FH, 44H, 40H, 20H ; t
   DB	3CH, 40H, 40H, 20H, 7CH ; u
   DB	1CH, 20H, 40H, 20H, 1CH ; v
   DB	3CH, 40H, 30H, 40H, 3CH ; w
   DB	44H, 28H, 10H, 28H, 44H ; x
   DB	0CH, 50H, 50H, 50H, 3CH ; y
   DB	44H, 64H, 54H, 4CH, 44H ; z
   DB   00H, 08H, 36H, 41H, 00H ; {
   DB	00H, 00H, 7FH, 00H, 00H ; |
   DB	00H, 41H, 36H, 08H, 00H ; }
   DB	08H, 08H, 2AH, 1CH, 08H ; ->
   DB	08H, 1CH, 2AH, 08H, 08H ; <- 

   TABELA DB 0111111b,0000110b,1011011b,1001111b
	  DB 1100110b,1101101b,1111101b,0000111b
	  DB 1111111b,1101111b,1110111b,1111100b
	  DB 0111001b,1011110b,1111001b,1110001b
   
   MAPA DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"
	DB "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X", "X"

   TITULO DB ?, "POR FAVOR, DIGITE UMA SEQUENCIA NUMERICA !!!", 13, 13, 10, 0
   
   REPETICOES_DIGITADOS DB 10, "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", 0
   
   TRACO DB 0, "?", 0
   TAMANHO DB 0, "?", 0

   SEGUNDOS_UNID DB 0
   SEGUNDOS_DEZ  DB 0

   TEXTO DB ?, TAM_STRING+1 DUP(?)
   CONTADOR_LETRAS DB 0

   MENSAGEM DB "HELIO POTELICKY", 13 , 10, 0

DATA 	  ENDS

;EXTRA

EXTRA SEGMENT
EXTRA ENDS

end inicio