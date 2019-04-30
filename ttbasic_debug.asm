;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;for debug
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	IF	DEBUG_ENABLE
DBG_PUTC	MACRO
	PSHS	CC, A
	LDA	#\1
	LBSR	C_PUTCH
	PULS	CC, A
	ENDM
	
DBG_PUTS	MACRO
	LBSR	PUTS
	FCC	\1
	FCB	0
	ENDM
	
DBG_PUTLINE	MACRO
	LBSR	PUTLINE
	FCC	\1
	FCB	0
	ENDM

DBG_NEWLINE	MACRO
	LBSR	NEWLINE
	ENDM

DBG_PUTHEX_D	MACRO
	LBSR	PUTHEX_D
	ENDM

DBG_PUTHEX_A	MACRO
	LBSR	PUTHEX_A
	ENDM

DBG_PRINT_REGS	MACRO
	LBSR	PRINT_REGS
	ENDM

DBG_DUMP_IBUF	MACRO
	LBSR	DUMP_IBUF
	ENDM

DBG_DUMP_LIST	MACRO
	LBSR	DUMP_LIST
	ENDM

DBG_DUMP_LBUF	MACRO
	LBSR	DUMP_LBUF
	ENDM

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
NEWLINE	PSHS	CC, D, X
	LBSR	C_NEWLINE
	PULS	CC, D, X, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
PUTHEX_D	PSHS	CC, D, X
	LBSR	PUTHEX_W
	PULS	CC, D, X, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
PUTHEX_A	PSHS	CC, D, X
	LBSR	PUTHEX_B
	PULS	CC, D, X, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
PUTHEX_W
	PSHS	B
	BSR	PUTHEX_B
	PULS	A
PUTHEX_B
	PSHS	A
	LDB	#16
	MUL
	BSR	PUTHEX_4BIT
	PULS	A
	ANDA	#$0F
PUTHEX_4BIT	ADDA	#$90
	DAA
	ADCA	#$40
	DAA
	JMP	C_PUTCHAR
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
PUTS	PSHS	CC, D, X
	;S+0=>D
	;S+2=>X
	;S+4=>RETADDR
	LDX	5, S
PUTS_LOOP	LDA	, X+
	BEQ	PUTS_E
	LBSR	C_PUTCH
	BRA	PUTS_LOOP
	;ここでXは終端文字の後ろになっているはず
PUTS_E	STX	5, S
	PULS	CC, D, X, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
PUTLINE	PSHS	CC, D, X
	;S+0=>D
	;S+2=>X
	;S+4=>RETADDR
	LDX	5, S
PUTLINE_LOOP	LDA	, X+
	BEQ	PUTLINE_E
	LBSR	C_PUTCH
	BRA	PUTLINE_LOOP
	;ここでXは終端文字の後ろになっているはず
PUTLINE_E	STX	5, S
	LBSR	NEWLINE
	PULS	CC, D, X, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
PRINT_REGS	PSHS	CC, D, X, Y, U
	;S+0=>D
	;S+2=>X
	;S+4=>Y
	;S+6=>U
	;S+8=>RETADDR
	BSR	PUTS
	FCC	"CC:",0
	LDA	, S
	BSR	PUTHEX_A
	BSR	PUTS
	FCC	" A:",0
	LDA	1, S
	BSR	PUTHEX_A
	BSR	PUTS
	FCC	" B:",0
	LDA	2, S
	BSR	PUTHEX_A
	BSR	PUTS
	FCC	" X:",0
	LDD	3, S
	BSR	PUTHEX_D
	BSR	PUTS
	FCC	" Y:",0
	LDD	5, S
	LBSR	PUTHEX_D
	LBSR	PUTS
	FCC	" U:",0
	LDD	7, S
	LBSR	PUTHEX_D
	LBSR	C_NEWLINE
	PULS	CC, D, X, Y, U, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
DUMP_IBUF	PSHS	CC, D, X
	BSR	PUTS
	FCC	CR, "*IBUF*", 0
	LDX	#IBUF
	CLRB
DUMP_IBUF_L	BITB	#$1F
	BNE	1F
	LBSR	C_NEWLINE
	PSHS	D
	TFR	X, D
	LBSR	PUTHEX_D
	DBG_PUTC	' '
	PULS	D
1	LDA	, X+
	PSHS	B
	LBSR	PUTHEX_A
	DBG_PUTC	' '
	PULS	B
	INCB
	CMPB	#80
	BLO	DUMP_IBUF_L
	LBSR	C_NEWLINE
	PULS	CC, D, X, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
DUMP_LIST	PSHS	CC, D, X
	LBSR	PUTS
	FCC	CR, "*LIST BUF*", 0
	LBSR	PUTS
	FCC	CR, "ADDR 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F", 0
	LDX	#LISTBUF
	CLRB
DUMP_LIST_L	BITB	#$1F
	BNE	1F
	LBSR	C_NEWLINE
	PSHS	D
	TFR	X, D
	LBSR	PUTHEX_D
	DBG_PUTC	' '
	PULS	D
1	LDA	, X+
	PSHS	B
	LBSR	PUTHEX_A
	DBG_PUTC	' '
	PULS	B
	INCB
	CMPB	#96
	BLO	DUMP_LIST_L
	LBSR	C_NEWLINE
	PULS	CC, D, X, PC
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
DUMP_LBUF	PSHS	CC, D, X
	LBSR	PUTS
	FCC	CR,"*LBUF*", 0
	LDX	#LBUF
	BSR	DUMP
	PULS	CC, D, X, PC
DUMP	CLRB
DUMP_LOOP	TST	, X
	BEQ	2F
	BITB	#$1F
	BNE	1F
	LBSR	C_NEWLINE
	PSHS	D
	TFR	X, D
	LBSR	PUTHEX_D
	DBG_PUTC	' '
	PULS	D
1	LDA	, X+
	PSHS	B
	LBSR	PUTHEX_A
	DBG_PUTC	' '
	PULS	B
	INCB
	BRA	DUMP_LOOP
2	LBSR	C_NEWLINE
	RTS
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	ELSE
DBG_PUT_C	MACRO
	ENDM
	
DBG_PUTS	MACRO
	ENDM
	
DBG_NEWLINE	MACRO
	ENDM

DBG_PUTHEX_D	MACRO
	ENDM

DBG_PUTHEX_A	MACRO
	ENDM

DBG_PRINT_REGS	MACRO
	ENDM

DBG_DUMP_IBUF	MACRO
	ENDM

DBG_DUMP_LIST	MACRO
	ENDM

DBG_DUMP_LBUF	MACRO
	ENDM

	ENDIF
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
