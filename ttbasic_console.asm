;---------------------------------------------------------------------------
; WAIT ACIA
;---------------------------------------------------------------------------
C_WAIT_ACIA	PSHS	A
WRWAIT	LDA	USTAT
	BITA	#2
	BEQ	WRWAIT
	PULS	A
	RTS
;---------------------------------------------------------------------------
;GET KEY
;---------------------------------------------------------------------------
C_GETCHAR	BSR	C_KBHIT
	BEQ	1F
	LDA	URECV
	ANDA	#$7F
1	RTS
;---------------------------------------------------------------------------
;C_PUTCHAR
;---------------------------------------------------------------------------
C_PUTCHAR	BSR	C_WAIT_ACIA
	STA	USEND
	RTS
;---------------------------------------------------------------------------
;C_KBHIT
;---------------------------------------------------------------------------
C_KBHIT	LDA	USTAT
	ANDA	#1
	RTS
;---------------------------------------------------------------------------
;数値を表示する
;D : 値
;X : 桁数
;---------------------------------------------------------------------------
C_PUTNUM
	PSHS	D, X, U
	;+0:D
	;+2:X(+3:WLEN)
	;+4:U
	
;	;::::::::::debug :::::::::::::
;	LBSR	PRINT_REG
;	;::::::::::debug :::::::::::::
	CLR	SIGN	;SIGN
	CLR	WLEN	;現在の桁数
	LDU	#(PBUF+9)
	CLR	, U	;終端文字セット
	;マイナスか？
	CMPD	#0
	BGE	C_PUTNUM_PLUS
	INC	SIGN	;符号ありにセット
	LBSR	NEGD	;正数に変換
C_PUTNUM_PLUS	STD	VALUE1
;	;::::::::::debug :::::::::::::
;	LBSR	PRINT_REG
;	LBSR	PUTS
;	FCC	"DIV",CR,0
;	;::::::::::debug :::::::::::::
	TFR	D, X
C_PUTNUM_LOOP1	LDD	#10
	LBSR	DIV16	;X=X / D 
			;D=X % D
;	;::::::::::debug :::::::::::::
;	LBSR	PRINT_REG
;	;::::::::::debug :::::::::::::
	STX	VALUE1
	ADDB	#'0'
	STB	, -U
	INC	WLEN
	LDX	VALUE1
	BNE	C_PUTNUM_LOOP1
	TST	SIGN
	BEQ	C_PUTNUM_NO_SIGN
	LDB	#'-'
	STB	, -U
	INC	WLEN
C_PUTNUM_NO_SIGN
	LDA	WLEN
;	;::::::::::debug :::::::::::::
;	LBSR	PUTS
;	FCC	"WLEN",CR,0
;	LBSR	PRINT_REG
;	;::::::::::debug :::::::::::::
	LDB	#' '
C_PUTNUM_LOOP2	;指定桁数になるまで空白を付与する
	CMPA	3, S
	BGE	C_PUTNUM_PRINT
	STB	, -U
	INCA
	BRA	C_PUTNUM_LOOP2
C_PUTNUM_PRINT	LEAX	, U
	LBSR	C_PUTS

	PULS	D, X, U, PC

;---------------------------------------------------------------------------
;数値を入力する
;Called by only INPUT statement
;OUT D : 値
;	use	value1
;---------------------------------------------------------------------------
C_GETNUM
	PSHS	X, Y
	CLRB		;LEN
	CLR	SIGN
	CLR	ERR_CODE
	LDU	#PBUF
GETNUM_LOOP
	LBSR	C_GETCH
	CMPA	#KEY_ENTER
	BEQ	GETNUM_END
	CMPA	#KEY_BS1
	BEQ	GETNUM_BS
	CMPA	#KEY_BS2
	BEQ	GETNUM_BS
	;行頭の符号および数字が入力された場合の処理
	;（符号込みで6桁を超えないこと）
	CMPA	#'-'
	BEQ	GETNUM_SIGN
	CMPA	#'+'
	BEQ	GETNUM_SIGN
	CMPB	#6
	BHS	GETNUM_LOOP	;6桁まで入力可能
	LBSR	ISDIGIT
	BEQ	GETNUM_SETBUF
	;数字以外は無視
	BRA	GETNUM_LOOP

GETNUM_SIGN	;符号は行頭のみOK
	TSTB
	BNE	GETNUM_LOOP
GETNUM_SETBUF
	STA	B, Y
	INCB
	LBSR	C_PUTCH
	BRA	GETNUM_LOOP


	;[BackSpace]キーが押された場合の処理（行頭ではないこと）
GETNUM_BS	TSTB
	BEQ	GETNUM_LOOP
	DECB
	LBSR	C_PUT_BS
	BRA	GETNUM_LOOP

GETNUM_END	LBSR	C_NEWLINE
	CLR	B, Y	;終端を置く
	;数値に変換
	LDB	, Y	;先頭の文字を取得
	CMPB	#'+'	;「+」の場合は次の文字に
	BEQ	GETNUM_NEXT_C
	CMPB	#'-'
	BNE	GETNUM_TO_INT
	NEG	SIGN	;「-」の場合はフラグをセットし
			;次の文字に
GETNUM_NEXT_C	LEAY	1, Y
GETNUM_TO_INT	LBSR	STR_TO_INT
	BNE	GETNUM_ERR_VOF
;1	LEAU	1, Y	;符号ありの場合は2文字目以降を対象
;2	LDX	#0	;値をクリア
;GETNUM_LOOP2	STX	VALUE1
;	LDA	, Y+
;	BEQ	GETNUM_LOOP2_E
;	LBSR	MUL_X_BY_10_ADD_A
;	CMPX	VALUE1
;	BHS	GETNUM_LOOP2
;GETNUM_ERR_VOF
;	LDB	#ERR_VOF	;前回より小さい場合はエラー
;	STB	ERR_CODE
;
;GETNUM_LOOP2_E
	TST	SIGN
	BEQ	1F
	;負の値に変換
	LBSR	NEGD
1	PULS	X, Y, PC
GETNUM_ERR_VOF
	LDB	#ERR_VOF	;前回より小さい場合はエラー
	STB	ERR_CODE
	PULS	X, Y, PC

;---------------------------------------------------------------------------
; output console
;	IN	A	出力文字
;			CRの場合は続けてLFを出力
;---------------------------------------------------------------------------
C_PUTCH	CMPA	#CR
	LBNE	C_PUTCHAR
	LBSR	C_PUTCHAR
	LDA	#LF	;DO LINEFEED AFTER CR
	LBRA	C_PUTCHAR
;---------------------------------------------------------------------------
; output console newline
;	IN	A	出力文字
;			CRの場合は続けてLFを出力
;---------------------------------------------------------------------------
C_NEWLINE	LDA	#CR
	BRA	C_PUTCH
;---------------------------------------------------------------------------
;GET CHARACTER
;WAIT INPUT
;	OUT	A
;---------------------------------------------------------------------------
C_GETCH	LBSR	C_GETCHAR	;GET A CHARACTER FROM CONSOLE IN
	BEQ	C_GETCH	;LOOP IF NO KEY DOWN
	RTS
;---------------------------------------------------------------------------
;文字列を表示する
;	IN	X	STRING
;---------------------------------------------------------------------------
C_PUTS	PSHS	X
1	LDA	,X+
	BEQ	2F
	LBSR	C_PUTCH
	BRA	1B
2	PULS	X, PC
;---------------------------------------------------------------------------
;BSを表示して文字を消す
;---------------------------------------------------------------------------
C_PUT_BS	PSHS	A
	LDA	#BS
	LBSR	C_PUTCHAR
	BSR	C_PUT_SPACE
	LDA	#BS
	LBSR	C_PUTCHAR
	PULS	A, PC
;---------------------------------------------------------------------------
;1文字の空白を表示する
;---------------------------------------------------------------------------
C_PUT_SPACE	PSHS	A
	LDA	#SPACE
	LBSR	C_PUTCH
	PULS	A, PC
;---------------------------------------------------------------------------
;文字列を入力しLBUFに保存する
;---------------------------------------------------------------------------
C_GETS	PSHS	D, U
	CLRB		;文字数
	LDU	#LBUF	;入力バッファ
C_GETS_LOOP	LBSR	C_GETCH
	CMPA	#KEY_ENTER	;[Enter]で終了
	BEQ	C_GETS_LOOP_E

	BSR	REPLACE_TAB	;[Tab]キーは空白に置き換える
	
	BSR	IS_KEY_BS	;[Back Space]押下
	BEQ	C_GETS_BS
	;BS以外
	LBSR	ISPRINT
	BNE	C_GETS_LOOP	;非表示文字
	CMPB	#(SIZE_LINE-1)	;バッファが溢れないように
	BHS	C_GETS_LOOP	;B>=(SIZE_LINE-1)
	;入力文字をバッファに追加
	STA	B, U
	INCB
	LBSR	C_PUTCH
	BRA	C_GETS_LOOP
C_GETS_BS	;BS
	;バッファに文字がない場合は何もしない
	TSTB
	BEQ	C_GETS_LOOP
	;文字数を1減らす
	DECB
	BSR	C_PUT_BS
	BRA	C_GETS_LOOP
C_GETS_LOOP_E
	LBSR	C_NEWLINE	;改行
	BSR	TRIM_END_SPACE	;バッファが空でない場合は末尾の空白を削る
	PULS	D, U, PC
	
REPLACE_TAB	CMPA	#KEY_TAB
	BNE	1F
	LDA	#SPACE
1	RTS

IS_KEY_BS	CMPA	#KEY_BS1
	BEQ	1F
	CMPA	#KEY_BS2
1	RTS

TRIM_END_SPACE	
1	TSTB
	BEQ	2F
	;バッファが空でない場合は末尾の空白を削る
	DECB
	LDA	B, U
	LBSR	ISSPACE
	BEQ	1B
	INCB
2	CLR	B, U	;終端文字をセット
	RTS
