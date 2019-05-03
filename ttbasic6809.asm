;/*
; TOYOSHIKI Tiny BASIC for Arduino
; (C)2012 Tetsuya Suzuki
; GNU General Public License
;  2019/xx/xx, Porting by Tamakichi、for 6809 ; */

;---------------------------------------------------------------------------
;MACRO及び設定
;---------------------------------------------------------------------------
	INCLUDE	/ttbasic_macro.asm/
	INCLUDE	/ttbasic_def.asm/
;---------------------------------------------------------------------------
;RAM割り付け
;---------------------------------------------------------------------------
	ORG	$0000
RANDOM_SEED	RMB	2	;乱数
CLP	RMB	2	;Pointer current line
GSTKI	RMB	1	;GOSUB stack index
GSTK	RMB	SIZE_GSTK	;GOSUB stack
LSTKI	RMB	1	;FOR stack index
LSTK	RMB	SIZE_LSTK	;FOR stack
ERR_CODE	RMB	1	;エラーコード
PBUF	RMB	10	;表示用ワーク
SIGN	RMB	1	;符号
WLEN	RMB	1	;桁
PLEN	RMB	2	;PRINTの桁数
WSIZE	RMB	1
VALUE1	RMB	2	;値
VALUE2	RMB	2	;値

VAR	RMB	26*2	;変数領域(Variable area)
	IF	RX_BUFFER_SIZE!=0
RX_BUF_W_PTR	RMB	1
RX_BUF_CNT	RMB	1
	ENDIF
LBUF	RMB	SIZE_LINE	;Command line buffer
IBUF	RMB	SIZE_IBUF	;i-code conversion buffer
ARR	RMB	SIZE_ARRY*2	;Array area
	IF	RX_BUFFER_SIZE!=0
RX_BUFFER	RMB	RX_BUFFER_SIZE
	ENDIF

LISTBUF	RMB	SIZE_LIST	;List area



	ORG	$E000

TITLE	FCC	"TOYOSHIKI TINY BASIC",0
EDITION	FCC	"6809"
	FCC	" EDITION",0
PROMPT_LINE	FCC	"LINE:",0
PROMPT_YOU_TYPE	FCC	"YOU TYPE: ",0

;---------------------------------------------------------------------------
;割り込みハンドラ
;---------------------------------------------------------------------------
SWI3	;ソフトウェア割り込み３
	RTI
SWI2	;ソフトウェア割り込み２
	RTI
FIRQ	;高速割り込み
	RTI
IRQ	;通常割り込み
	IF	RX_BUFFER_SIZE!=0
	LDA	USTAT
	ASLA		;IRQ ?
	BCC	RTIIRQ
	LSRA
	LSRA		;RDRF ?
	BCC	ERRPRC
	LDA	URECV	;READ RX DATA
	;PUT RX BUFFER
	LDX	#RX_BUFFER
	LDB	RX_BUF_W_PTR
	STA	B, X
	INCB
	ANDB	#(RX_BUFFER_SIZE-1)
	STB	RX_BUF_W_PTR

	LDA	RX_BUF_CNT
	CMPA	#RX_BUFFER_SIZE
	BEQ	1F
	INC	RX_BUF_CNT
1	;FLOW CONTROL
	CMPA	#(RX_BUFFER_SIZE-8)
	BLS	RTIIRQ
	LDB	#RTS_HI
	STB	UCTRL
	RTI
ERRPRC	LDA	URECV	;DUMMY READ
	ENDIF
RTIIRQ	RTI
SWI	;ソフトウェア割り込み１
	RTI
NMI	;マスク不可割り込み
	RTI

	IF	RX_BUFFER_SIZE!=0
;-------------------------------------------------
; RX BUFFER DATA EXISTS
; OUT
;   ZF:DATA NOT EXISTS:1
;      DATA EXISTS    :0
;-------------------------------------------------
RING_DATA_EXISTS
	PSHS	A
	TST	RX_BUF_CNT
	PULS	A, PC
;-------------------------------------------------
; RX BUFFER GET DATA
; OUT
;   A :DATA
;   ZF:DATA NOT EXISTS : 1
;      DATA EXISTS     : 0
;-------------------------------------------------
RX_GET_DATA
	PSHS	B, X
	LDX	#RX_BUFFER
	CLRA
	TST	RX_BUF_CNT
	BEQ	1F
	LDB	RX_BUF_W_PTR
	SUBB	RX_BUF_CNT
	ANDB	#(RX_BUFFER_SIZE-1)
	LDA	B, X
	DEC	RX_BUF_CNT
	BNE	2F
	LDB	#RTS_LO
	STB	UCTRL
2
	CLR_ZF
1
	PULS	B, X, PC
	ENDIF

;---------------------------------------------------------------------------
;リセット処理
;---------------------------------------------------------------------------
RESET	;リセット
	;DPの初期化
	CLRA
	TFR	A, DP
	;スタックの設定
	LDS	#STACK_TOP
	;乱数初期値の設定
	LDD	#12345
	STD	RANDOM_SEED
	;ACIAの初期化
	IF	RX_BUFFER_SIZE!=0
	SEI
	CLR	RX_BUF_W_PTR
	CLR	RX_BUF_CNT
	LDA	#RTS_LO	;RTS:Lo
	STA	UCTRL
	CLI
	ELSE
	LDA	#$15
	STA	UCTRL
	ENDIF
	JMP	BASIC

;---------------------------------------------------------------------------
;各種モジュール
;---------------------------------------------------------------------------

	INCLUDE	/ttbasic_debug.asm/
	INCLUDE	/ttbasic_console.asm/
	INCLUDE	/ttbasic_keyword.asm/
	INCLUDE	/ttbasic_sub.asm/
	INCLUDE	/ttbasic_list.asm/
	INCLUDE	/ttbasic_error.asm/

;---------------------------------------------------------------------------
; 括弧でくくられた式を値に変換して中間コードポインタを進める
;	IN	Y	CIP
;	OUT	D	value
;		Y	CIP
;---------------------------------------------------------------------------
GET_PARAM
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"GET_PARAM"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDA	, Y
	;"("でない場合はエラー
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPA	#I_OPEN
	BNE	GET_PARAM_ERR
	LEAY	1, Y	;中間コードポインタを次へ進める

	LBSR	IEXP	;式を計算
	TST	ERR_CODE	;もしエラーが生じたら
	BNE	1F	;終了

	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"GET_PARAM2"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	D
	;")"でない場合はエラー
	LDA	, Y
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPA	#I_CLOSE
	PULS	D
	BNE	GET_PARAM_ERR

	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"GET_PARAM END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	RTS

1	LDD	#0
	RTS
GET_PARAM_ERR
	;::::::::::debug :::::::::::::
	DBG_PUTLINE	"GET_PARAM_ERR"
	;::::::::::debug :::::::::::::
	LDB	#ERR_PAREN
	STB	ERR_CODE
	RTS
;---------------------------------------------------------------------------
; Value  address
;	IN	B	Value No
;	OUT	X	Value Address
;---------------------------------------------------------------------------
VALUE_ADDRESS
	LDX	#VAR
	ASLB
	ABX
	RTS
;---------------------------------------------------------------------------
; Array address
;	IN	D	Array Index
;	OUT	X	Array Address
;---------------------------------------------------------------------------
ARRAY_ADDRESS
	ASLB
	ROLB
	PSHS	D
	LDD	#ARR
	ADDD	, S
	LEAS	2, S
	TFR	D, X
	RTS
;---------------------------------------------------------------------------
; Get value
;	IN	Y	CIP
;	OUT	D	value
;		Y	CIP
;---------------------------------------------------------------------------
IVALUE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	X
	LDB	, Y
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_TBL"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPB	#I_STR
	BHI	IVALUE_ERR
	SUBB	#I_MINUS
	BLO	IVALUE_ERR
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;ジャンプテーブル計算
	LDX	#IVALUE_TBL
	ASLB		;B=B*2
	ABX
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;0の場合は対象外
	LDX	, X
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BEQ	IVALUE_ERR
	JMP	, X
IVALUE_ERR
	LDB	#ERR_SYNTAX
IVALUE_ERR2	STB	ERR_CODE
IVALUE_END	PULS	X, PC


IVALUE_TBL	FDB	IVALUE_MINUS	;I_MINUS
	FDB	IVALUE_PLUS	;I_PLUS
	FDB	0	;I_MUL
	FDB	0	;I_DIV
	FDB	0	;I_NEQ
	FDB	0	;I_EQ
	FDB	0	;I_SHARP
	FDB	0	;I_LT
	FDB	0	;I_LTE
	FDB	0	;I_GT
	FDB	0	;I_GTE
	FDB	IVALUE_OPEN	;I_OPEN
	FDB	0	;I_CLOSE
	FDB	0	;I_COMMA
	FDB	IVALUE_ARRAY	;I_ARRAY
	FDB	IVALUE_RND	;I_RND
	FDB	IVALUE_ABS	;I_ABS
	FDB	IVALUE_SIZE	;I_SIZE
	FDB	0	;I_LIST
	FDB	0	;I_RUN
	FDB	0	;I_NEW
	FDB	IVALUE_NUM	;I_NUM
	FDB	IVALUE_VAR	;I_VAR
	FDB	0	;I_STR

	;-----------------------------------------------------------
	;定数の取得
IVALUE_NUM	;定数
	LEAY	1, Y	;中間コードポインタを次へ進める
	LDD	, Y++	;定数を取得し中間コードポインタを定数の次へ進める
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_NUM"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_PLUS	;+付きの値の取得
	LEAY	1, Y	;中間コードポインタを次へ進める
	;BSR	IVALUE	;値を取得
	JSR	IVALUE
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IVALUE_PLUS"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_MINUS	;負の値の取得
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IVALUE
	LBSR	NEGD
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IVALUE_MINUS"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_VAR	;変数番号を取得する
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_VAR"
	;::::::::::debug :::::::::::::
	LEAY	1, Y
	LDB	, Y+
	JSR	VALUE_ADDRESS
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDD	, X
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_OPEN	;括弧の値の取得
	LBSR	GET_PARAM
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_ARRAY	;配列の値の取得
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_ARRAY"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	GET_PARAM
	TST	ERR_CODE
	BNE	IVALUE_END	;エラー発生時は終了
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPD	#SIZE_ARRY
	BHS	IVALUE_ARRAY_ERR
	JSR	ARRAY_ADDRESS
	LDD	, X
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_RND	;RND
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_NUM"
	;::::::::::debug :::::::::::::
	LEAY	1, Y
	LBSR	GET_PARAM
	TST	ERR_CODE
	LBNE	IVALUE_END	;エラー発生時は終了
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"PARAM"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	LBSR	GETRND
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_ABS	;ABS
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_ABS"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LEAY	1, Y
	LBSR	GET_PARAM
	TST	ERR_CODE
	LBNE	IVALUE_END	;エラー発生時は終了
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPD	#0
	BHS	1F
	LBSR	NEGD
1	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_SIZE	;SIZE
	LEAY	1, Y
	LDA	, Y
	CMPA	#I_OPEN
	BNE	1F
	LEAY	1, Y
	LDA	, Y
	CMPA	#I_CLOSE
	BNE	IVALUE_SIZE_ERR
1	LBSR	GET_FREE_SIZE
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_ARRAY_ERR
	LDB	#ERR_SOR
	LBRA	IVALUE_ERR2
IVALUE_SIZE_ERR
	LDB	#ERR_PAREN
	LBRA	IVALUE_ERR2
;---------------------------------------------------------------------------
; multiply or divide calculation
;	IN	Y	CIP
;	OUT	D	value
;		Y	CIP
;---------------------------------------------------------------------------
IMUL
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IMUL"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	X, U
	LBSR	IVALUE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IMUL IVALUE END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	TST	ERR_CODE
	BNE	IMUL_ERR_END	;エラー発生時は終了
	PSHS	D	;現在値をスタックに保存
IMUL_LOOP
	LDA	, Y
	CMPA	#I_MUL
	BEQ	IMUL_MUL
	CMPA	#I_DIV
	BEQ	IMUL_DIV
	;MUL,DIVのいずれでもない
	PULS	D
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IMUL END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, U, PC
	;PULS	D, X, U, PC
	;-----------------------------------------------------------
IMUL_MUL	;掛け算の場合
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IVALUE
	LDX	, S	;被乗数をスタックから取得
	LBSR	MUL16
	STD	, S	;計算結果をスタックに保存
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IMUL:"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	BRA	IMUL_LOOP

	;-----------------------------------------------------------
IMUL_DIV	;割り算の場合
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IVALUE
	CMPD	#0
	BEQ	IMUL_ERR_DIV0
	LDX	, S	;被除数をスタックから取得
	LBSR	DIV16
	STX	, S	;商をスタックに保存
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IDIV:"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	BRA	IMUL_LOOP

IMUL_ERR_DIV0
	LDB	#ERR_DIVBY0
	STB	ERR_CODE
	LEAS	2, S
IMUL_ERR_END
	LDD	#-1
	PULS	X, U, PC
;---------------------------------------------------------------------------
; add or subtract calculation
;	IN	Y	CIP
;	OUT	D	value
;		Y	CIP
;---------------------------------------------------------------------------
IPLUS
	PSHS	X, U
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPLUS"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBSR	IMUL
	TST	ERR_CODE
	BNE	IMUL_ERR_END
	PSHS	D	;現在値をスタックに保存
IPLUS_LOOP
	LDA	, Y
	CMPA	#I_PLUS
	BEQ	IPLUS_PLUS
	CMPA	#I_MINUS
	BEQ	IPLUS_MINUS
	;PLUS,MINUSのいずれでもない
	PULS	D
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPLUS END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, U, PC
	;PULS	D, X, U, PC

	;-----------------------------------------------------------
IPLUS_PLUS	;足し算
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IMUL
	ADDD	, S	;スタック上の現在値を加算
	STD	, S	;結果をスタックに保存
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IPLUS:"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	BRA	IPLUS_LOOP
	;-----------------------------------------------------------
IPLUS_MINUS	;引き算
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IMUL
	LBSR	NEGD	;減算するために符号反転
	ADDD	, S	;スタック上の現在値を加算
	STD	, S	;結果をスタックに保存
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IMINUS:"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	BRA	IPLUS_LOOP
;---------------------------------------------------------------------------
; Get constant number value
;	IN	Y	pointer
;	OUT	D	constant number
;---------------------------------------------------------------------------
IEXP
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	X, U
	LBSR	IPLUS
	TST	ERR_CODE
	BNE	IMUL_ERR_END
	PSHS	D	;現在値をスタックに保存
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
IEXP_LOOP
	LDB	, Y
	SUBB	#I_NEQ
	BLO	IEXP_END
	CMPB	#(I_COMPARE_END-I_COMPARE_START)
	BHI	IEXP_END
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP LOOP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDX	#IEXP_TBL
	ASLB
	ABX
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IPLUS
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"COMPARE"
	;PSHS	CC, D
	;LDD	3, S
	;DBG_PUTHEX_D
	;DBG_PUTS	":"
	;PULS	CC, D
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	CMPD	, S	;スタック上の現在値と比較
	JMP	[, X]
IEXP_END	PULS	D
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP_END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;PULS	D, X, U, PC
	PULS	X, U, PC
IEXP_TBL
	FDB	IEXP_NEQ
	FDB	IEXP_EQ
	FDB	IEXP_SHARP
	FDB	IEXP_LE
	FDB	IEXP_LT
	FDB	IEXP_GE
	FDB	IEXP_GT
IEXP_FALSE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"FALSE"
	;::::::::::debug :::::::::::::
	LDD	#0
	STD	, S	;スタック上の現在値に保存
	BRA	IEXP_LOOP
IEXP_TRUE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TRUE"
	;::::::::::debug :::::::::::::
	LDD	#1
	STD	, S	;スタック上の現在値に保存
	BRA	IEXP_LOOP
	;-----------------------------------------------------------
IEXP_EQ
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP_EQ"
	;::::::::::debug :::::::::::::
	BEQ	IEXP_TRUE
	BRA	IEXP_FALSE
	;-----------------------------------------------------------
IEXP_SHARP
IEXP_NEQ
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP_NOT EQ"
	;::::::::::debug :::::::::::::
	BNE	IEXP_TRUE
	BRA	IEXP_FALSE
	;-----------------------------------------------------------
IEXP_LT
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP LT"
	;::::::::::debug :::::::::::::
	BGT	IEXP_TRUE
	BRA	IEXP_FALSE
	;-----------------------------------------------------------
IEXP_LE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP LE"
	;::::::::::debug :::::::::::::
	BGE	IEXP_TRUE
	BRA	IEXP_FALSE
	;-----------------------------------------------------------
IEXP_GT
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP GT"
	;::::::::::debug :::::::::::::
	BLT	IEXP_TRUE
	BRA	IEXP_FALSE
	;-----------------------------------------------------------
IEXP_GE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXP GE"
	;::::::::::debug :::::::::::::
	BLE	IEXP_TRUE
	BRA	IEXP_FALSE
	;-----------------------------------------------------------

;---------------------------------------------------------------------------
; PRINT handler
;	IN	Y	CIP
;	OUT	Y	CIP
;---------------------------------------------------------------------------
IPRINT
	PSHS	D, X, U
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPRINT"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CLR	PLEN
IPRINT_LOOP
	LDA	, Y
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"\rIPRINT_LOOP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BSR	IS_SEMI_OR_EOL
	BEQ	IPRINT_LOOP_E
	CMPA	#I_STR
	BEQ	IPRINT_STR
	CMPA	#I_SHARP
	BEQ	IPRINT_SHARP
	;-----------------------------------------------------------
	;式の場合
	LBSR	IEXP
	TST	ERR_CODE
	BNE	IPRINT_ERR_END
	LDX	PLEN
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPRINT PUTNUM"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBSR	C_PUTNUM
	BRA	IPRINT_NEXT
	;-----------------------------------------------------------
IPRINT_LOOP_E
	LBSR	C_NEWLINE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPRINT END"
	;::::::::::debug :::::::::::::
IPRINT_ERR_END	PULS	D, X, U, PC
	;-----------------------------------------------------------
IPRINT_STR	;文字列の場合
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPRINT STR"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	LDB	, Y+	;文字数を取得する
1	LDA	, Y+
	LBSR	C_PUTCH
	DECB
	BNE	1B
	BRA	IPRINT_NEXT
	;-----------------------------------------------------------
IPRINT_SHARP	;「#」の場合
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IEXP	;桁数を取得
	TST	ERR_CODE
	BNE	IPRINT_ERR_END
	STD	PLEN	;桁数を保持
	;-----------------------------------------------------------
IPRINT_NEXT
	LDA	, Y
	CMPA	#I_COMMA
	BEQ	IPRINT_COMMA
	;コンマ以外
	BSR	IS_SEMI_OR_EOL
	BEQ	IPRINT_LOOP
	;セミコロンでも文末でもなければエラー
	LDB	#ERR_SYNTAX
	STB	ERR_CODE
	PULS	D, X, U, PC
IPRINT_COMMA	;コンマがある場合
	LEAY	1, Y	;中間コードポインタを次へ進める
	;次の中間コードを取得する
	LDA	, Y
	BSR	IS_SEMI_OR_EOL
	BNE	IPRINT_LOOP	;文末以外はループを継続
	;もし文末なら終了
	PULS	D, X, U, PC

;---------------------------------------------------------------------------
; セミコロンか文末を判定する
;	IN	A	中間コード
;	OUT	ZF	SET : セミコロンまたは文末
;			RESET : 以外
;---------------------------------------------------------------------------
IS_SEMI_OR_EOL	CMPA	#I_SEMI
	BEQ	1F
	CMPA	#I_EOL
1	RTS

;---------------------------------------------------------------------------
; INPUT handler
; IN	Y : CIP
; OUT	Y : CIP
;---------------------------------------------------------------------------
IINPUT
	PSHS	D, X, U
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IINPUT"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	A	;プロンプト表示フラグ
IINPUT_LOOP
	CLR	, S	;まだプロンプトを表示していない
	LDA	, Y
	CMPA	#I_STR
	BNE	1F
	LBSR	IINPUT_PROMPT_STR

	;値を入力する処理
1	CMPA	#I_VAR
	BEQ	IINPUT_VAR
	CMPA	#I_ARRAY
	BEQ	IINPUT_ARRAY
	BRA	IINPUT_ERR_SYNTAX
	;-----------------------------------------------------------
IINPUT_VAR	;変数の場合
	LEAY	1, Y	;中間コードポインタを次へ進める
	TST	, S	;プロンプトを表示したか？
	BNE	1F
	BSR	IINPUT_PROMPT_VAR
1	LBSR	C_GETNUM	;D=値
	TST	ERR_CODE
	BNE	IINPUT_END	;エラー
	TFR	D, U	;U=値
	LDB	, Y+	;変数番号を取得
	JSR	VALUE_ADDRESS
	STU	, X	;変数へ代入
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IINPUT_VAR"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BRA	IINPUT_CONTUNUE_CHK
	;-----------------------------------------------------------
IINPUT_ARRAY
	LEAY	1, Y	;//中間コードポインタを次へ進める
	LBSR	GET_PARAM	;添え字を取得
	TST	ERR_CODE
	BNE	IINPUT_END
	CMPD	#SIZE_ARRY
	BHS	IINPUT_ERR_SOR	;添字が上限を超えている
	TST	, S	;プロンプトを表示したか？
	BNE	1F	;プロンプト表示済み
	BSR	IINPUT_PROMPT_ARR
	;保存先を計算
1	
	JSR	ARRAY_ADDRESS
	LBSR	C_GETNUM
	TST	ERR_CODE
	BNE	IINPUT_END
	;配列へ代入
	STD	, X
	;-----------------------------------------------------------
IINPUT_CONTUNUE_CHK
	;値の入力を連続するかどうか判定する
	LDA	, Y
	;コンマの場合
	CMPA	#I_COMMA
	BEQ	IINPUT_COMMA
	;セミコロン、または、行末の場合
	BSR	IS_SEMI_OR_EOL
	BNE	IINPUT_ERR_SYNTAX
IINPUT_END
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IINPUT END"
	;::::::::::debug :::::::::::::
	PULS	A	;プロンプト表示フラグの削除
	PULS	D, X, U, PC
	;-----------------------------------------------------------
IINPUT_COMMA
	LEAY	1, Y	;//中間コードポインタを次へ進める
	LBRA	IINPUT_LOOP
	;-----------------------------------------------------------
	;エラー
IINPUT_ERR_SOR	LDB	#ERR_SOR
	BRA	1F
IINPUT_ERR_SYNTAX
	LDB	#ERR_SYNTAX
1	STB	ERR_CODE
	PULS	A	;プロンプト表示フラグの削除
	PULS	D, X, U, PC
	;-----------------------------------------------------------
	;変数のプロンプトを表示する
IINPUT_PROMPT_VAR
	PSHS	A
	LDA	, Y
	ADDA	#'A'
	LBSR	C_PUTCH
	LDA	#':'
	LBSR	C_PUTCH
	PULS	A
	NEG	2, S	;プロンプトを表示した
	RTS
	;-----------------------------------------------------------
	;配列のプロンプトを表示する
IINPUT_PROMPT_ARR
	PSHS	D
	LDA	#'@'
	LBSR	C_PUTCH
	LDA	#'('
	LBSR	C_PUTCH
	PULS	D
	LBSR	C_PUTNUM
	LDA	#')'
	LBSR	C_PUTCH
	LDA	#':'
	LBSR	C_PUTCH
	NEG	2, S	;プロンプトを表示した
	RTS
	;-----------------------------------------------------------
	;文字列のプロンプトを表示
IINPUT_PROMPT_STR
	LEAY	1, Y	;//中間コードポインタを次へ進める
	LDB	, Y+	;文字数を取得
	;文字数を取得し、文字を表示する
1	LDA	, Y+
	LBSR	C_PUTCH
	DECB
	BNE	1B
	NEG	, S	;プロンプトを表示した
	LDA	, Y
	RTS

;---------------------------------------------------------------------------
; Variable assignment handler
; IN	Y : CIP
; OUT	Y : CIP
;---------------------------------------------------------------------------
IVAR
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVAR"
	;::::::::::debug :::::::::::::
	PSHS	D, X
	LDB	, Y+	;変数番号を取得して次に進む
	;SUBB	#I_VAR
	JSR	VALUE_ADDRESS
	LDA	, Y
	CMPA	#I_EQ	;「=」以外はエラー
	BNE	IVAR_ERR
	LEAY	1, Y	;//中間コードポインタを次へ進める
	;値の取得と代入
	LBSR	IEXP
	TST	ERR_CODE
	BNE	IVAR_END
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVAR VALUE"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	STD	, X
IVAR_END
	PULS	D, X, PC
IVAR_ERR
	LDB	#ERR_VWOEQ
	STB	ERR_CODE
	PULS	D, X, PC
;---------------------------------------------------------------------------
; Array assignment handler
; IN	Y : CIP
; OUT	Y : CIP
;---------------------------------------------------------------------------
IARRAY
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IARRAY"
	;::::::::::debug :::::::::::::
	PSHS	D, X
	LBSR	GET_PARAM
	TST	ERR_CODE
	BNE	IARRAY_END
	CMPD	#SIZE_ARRY
	BHS	IARRAY_ERR_SOR
	JSR	ARRAY_ADDRESS
	LDA	, Y
	CMPA	#I_EQ	;「=」以外はエラー
	BNE	IARRAY_ERR_VWOEQ
	LEAY	1, Y	;//中間コードポインタを次へ進める
	;値の取得と代入
	LBSR	IEXP
	TST	ERR_CODE
	BNE	IARRAY_END
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IARRAY SET"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	STD	, X
IARRAY_END
	PULS	D, X, PC
IARRAY_ERR_SOR
	LDB	#ERR_SOR
	BRA	1F
IARRAY_ERR_VWOEQ
	LDB	#ERR_VWOEQ
1	STB	ERR_CODE
	PULS	D, X, PC


;---------------------------------------------------------------------------
; LET handler
; IN	Y : CIP
; OUT	Y : CIP
;---------------------------------------------------------------------------
ILET
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"ILET"
	;::::::::::debug :::::::::::::
	LDA	, Y
	CMPA	#I_VAR
	BEQ	ILET_VAR
	CMPA	#I_ARRAY
	BEQ	ILET_ARRAY
	;エラー
	LDB	#ERR_LETWOV
	STB	ERR_CODE
	RTS
ILET_VAR	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IVAR
	RTS
ILET_ARRAY	LEAY	1, Y	;中間コードポインタを次へ進める
	BSR	IARRAY
	RTS



;---------------------------------------------------------------------------
; Execute a series of i-code
; IN	Y	実行する行のポインタ
; OUT	D	次に実行するべき行のポインタ
;---------------------------------------------------------------------------
IEXE
	PSHS	X, Y, U
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE"
	;DBG_PRINT_REGS
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
IEXE_LOOP
	LDB	, Y
	CMPB	#I_EOL
	LBEQ	IEXE_END
	CMPB	#I_SEMI
	BHI	IEXE_NO_CMD
	SUBB	#I_IF
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBLO	IEXE_ERR_SYNTAX
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IEXE_LOOP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDX	#IEXE_TBL
	ASLB
	ABX
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDX	, X
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BNE	IEXE_CALL
IEXE_NO_CMD	
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IEXE_NO_CMD\r"
	;::::::::::debug :::::::::::::
	LDB	, Y
	CMPB	#I_ARRAY
	BEQ	IEXE_C_ARRAY
	CMPB	#I_VAR
	BEQ	IEXE_C_VAR
	CMPB	#I_RUN
	BEQ	IEXE_ERR_COM
	CMPB	#I_NEW
	BEQ	IEXE_ERR_COM
	CMPB	#I_LIST
	BEQ	IEXE_ERR_COM
	BRA	IEXE_ERR_SYNTAX
IEXE_C_ARRAY	
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IEXE_C_ARRAY\r"
	;::::::::::debug :::::::::::::
	LDX	IEXE_TBL_ARRAY
	BRA	IEXE_CALL
IEXE_C_VAR	
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IEXE_C_VAR\r"
	;::::::::::debug :::::::::::::
	LDX	IEXE_TBL_VAR
IEXE_CALL
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IEXE_CALL"
	;DBG_PRINT_REGS
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	JSR	, X
	TST	ERR_CODE
	BNE	IEXE_ERR_END
	LBRA	IEXE_LOOP

IEXE_TBL
	FDB	IEXE_IF
	FDB	IEXE_GOTO
	FDB	IEXE_GOSUB
	FDB	IEXE_RETURN
	FDB	IEXE_FOR
	FDB	0	;TO
	FDB	0	;STEP
	FDB	IEXE_NEXT
	FDB	IEXE_PRINT
	FDB	IEXE_INPUT
	FDB	IEXE_REM
	FDB	IEXE_LET
	FDB	IEXE_STOP
	FDB	IEXE_SEMI
IEXE_TBL_ARRAY	FDB	IEXE_ARRAY
IEXE_TBL_VAR	FDB	IEXE_VAR

IEXE_END
	;次に実行するべき行のポインタを持ち帰る
	LDX	CLP
	LDB	, X
	ABX
	TFR	X, D
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, Y, U, PC

IEXE_ERR_SYNTAX
	LDB	#MSG_ERR_SYNTAX
	BRA	IEXE_ERR_END
IEXE_ERR_COM
	LDB	#ERR_COM
IEXE_ERR_END	STB	ERR_CODE
	PULS	X, Y, U, PC

	;-----------------------------------------------------------
IEXE_IF
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_IF"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IEXP
	TST	ERR_CODE
	BNE	IEXE_IF_ERR
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPD	#0
	BEQ	IEXE_IF_FALSE	;偽の場合の処理はREMと同じ
	;真の場合は次の文を実行する
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IF TRUE"
	;::::::::::debug :::::::::::::
	RTS

IEXE_IF_ERR	
	;::::::::::debug :::::::::::::
	DBG_PUTLINE	"IF ERR"
	;::::::::::debug :::::::::::::
	;LDB	#ERR_IFWOC
	;STB	ERR_CODE
	RTS
IEXE_IF_FALSE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IF FALSE"
	;::::::::::debug :::::::::::::
	;-----------------------------------------------------------
IEXE_REM	;I_EOLに達するまで中間コードポインタを次へ進める
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_REM"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
IEXE_REM_LOOP	LDA	, Y+
	CMPA	#I_EOL
	BNE	IEXE_REM_LOOP
	LEAY	-1, Y
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_REM END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	RTS
	;-----------------------------------------------------------
IEXE_GOTO
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_GOTO"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	;GOTO先を取得する
	BSR	IEXE_GET_GO_LINE
	TST	ERR_CODE
	BNE	IEXE_GOTO_END
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"D:LINE NO,X:LINE PTR,Y:NEXT LINE"
	;::::::::::debug :::::::::::::
	;行ポインタを分岐先へ変更
	STX	CLP
	;中間コードポインタを先頭の中間コードに更新
	LEAY	3, X
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
IEXE_GOTO_END	RTS
IEXE_GOTO_ERR	LDB	#ERR_ULN
	STB	ERR_CODE
	RTS
	;-----------------------------------------------------------
IEXE_GOSUB
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_GOSUB"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	;GOSUB先を取得する
	BSR	IEXE_GET_GO_LINE
	TST	ERR_CODE
	BNE	IEXE_GOTO_END

	LDA	GSTKI
	CMPA	#(SIZE_GSTK - SIZE_NEST_GSTK)
	;GOSUBスタックがいっぱいならエラー
	BHI	IEXE_GOSUB_ERR
	LDU	#GSTK
	LEAU	A, U
	ADDA	#5
	STA	GSTKI
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"GSTK"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDD	CLP	;行ポインタを取得
	STD	, U++	;行ポインタを退避
	STY	, U++	;中間コードポインタを退避
	LDA	LSTKI	;FORスタックインデックスを取得
	STA	, U+	;FORスタックインデックスを退避
	STX	CLP	;行ポインタを分岐先へ更新
	LEAY	3, X	;中間コードポインタを先頭の中間コードに更新
	RTS
IEXE_GOSUB_ERR	LDB	#ERR_GSTKOF
	STB	ERR_CODE
	RTS
	;-----------------------------------------------------------
	;GOTO/GOSUB先の行番号・行ポインタを取得する
	;D:次の行番号
	;X:次の行ポインタ
IEXE_GET_GO_LINE
	LBSR	IEXP	;D=行番号
	TST	ERR_CODE
	BNE	IEXE_GET_NEXT_END
	LBSR	GET_LINE_PTR	;x=line pointer
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"LINE PTR"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	D
	LBSR	GET_LINE_NO	;line pointerから行番号を取得
	;行番号が一致していない場合は分岐先が存在しない
	CMPD	, S
	PULS	D
	BNE	IEXE_GET_NEXT_ERR
IEXE_GET_NEXT_END
	RTS
IEXE_GET_NEXT_ERR
	LDB	#ERR_ULN
	STB	ERR_CODE
	RTS
	;-----------------------------------------------------------
IEXE_RETURN
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_RETURN"
	;::::::::::debug :::::::::::::
	LDA	GSTKI
	CMPA	#SIZE_NEST_GSTK
	BLO	IEXE_RETURN_ERR	;GOSUBスタックが空ならエラー
	LDU	#GSTK
	LEAU	A, U
	SUBA	#5
	STA	GSTKI
	LDA	, -U	;FORスタックインデックスを復帰
	STA	LSTKI
	LDY	, --U	;中間コードポインタを復帰
	LDX	, --U	;行ポインタを復帰
	STX	CLP
	RTS
IEXE_RETURN_ERR	LDB	#ERR_GSTKUF
	STB	ERR_CODE
	RTS
	;-----------------------------------------------------------
IEXE_FOR
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_FOR"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	LDA	, Y+
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPA	#I_VAR	;変数がない場合はエラー
	LBNE	IEXE_FOR_ERR_FORWOV
	LDA	, Y	;変数名を取得
	LBSR	IVAR
	TST	ERR_CODE
	LBNE	IEXE_FOR_END	;エラー発生時は終了
	PSHS	A	;変数のインデックスを保存
	;::::::::::debug :::::::::::::
	;TFR	A, B
	;JSR	VALUE_ADDRESS
	;LDD	, X
	;DBG_PUTS	"FROM "
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	;終了値を取得
	LDA	, Y
	CMPA	#I_TO	;TOがなければエラー
	LBNE	IEXE_FOR_ERR_FORWOTO
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IEXP	;終了値を取得
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TO"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	D	;終了値を保存
	;増分を取得
	LDA	, Y
	CMPA	#I_STEP
	BNE	FOR_NO_STEP
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IEXP	;増分を取得
	BRA	FOR_CHK_STEP
FOR_NO_STEP	LDD	#1	;増分=1
FOR_CHK_STEP	;増分のチェック
	PSHS	D	;増分を保存
	CMPD	#0
	BMI	MINUS_STEP	;増分<0
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"STEP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;増分>=0
	LBSR	NEGD
	ADDD	#32767
	;終了値と比較し、終了値にならない可能性がある場合はエラー
	CMPD	2, S
	BLT	IEXE_FOR_ERR_VOF
	BRA	STEP_OK
MINUS_STEP	
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"MINUS_STEP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBSR	NEGD
	ADDD	#-32767
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;終了値と比較し、終了値にならない可能性がある場合はエラー
	CMPD	2, S
	BGE	IEXE_FOR_ERR_VOF
STEP_OK	;スタックチェック
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"STEP OK"
	;::::::::::debug :::::::::::::
	LDA	LSTKI
	CMPA	#(SIZE_LSTK - SIZE_NEST_LSTK)
	;FORスタックがいっぱいならエラー
	BHI	IEXE_FOR_ERR_LSTKOF
	LDU	#LSTK
	LEAU	A, U
	ADDA	#9
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEW LSTKI(A)"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	STA	LSTKI
	LDD	CLP	;行ポインタを取得
	STD	, U++	;行ポインタを退避
	STY	, U++	;中間コードポインタを退避
	PULS	D, X	;D:増分、X:終了値
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"D=STEP,X=END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	STX	, U++	;終了値を退避
	STD	, U++	;増分を退避
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"FOR TO "
	;LDD	-4, U
	;DBG_PUTHEX_D
	;DBG_PUTS	" STEP "
	;LDD	-2, U
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	PULS	A
	STA	, U+	;変数インデックスを退避
IEXE_FOR_END	RTS

IEXE_FOR_ERR_FORWOV
	LDB	#ERR_FORWOV
	BRA	FOR__ERR_END
IEXE_FOR_ERR_FORWOTO
	PULS	A
	LDB	#ERR_FORWOTO
	BRA	FOR__ERR_END
IEXE_FOR_ERR_VOF
	;::::::::::debug :::::::::::::
	DBG_PUTLINE	"IEXE_FOR_ERR_VOF"
	;::::::::::debug :::::::::::::
	PULS	D, X
	PULS	A
	LDB	#ERR_VOF
	BRA	FOR__ERR_END
IEXE_FOR_ERR_LSTKOF
	LDB	#ERR_LSTKOF
FOR__ERR_END	STB	ERR_CODE
	RTS
	;-----------------------------------------------------------
IEXE_NEXT
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IEXE_NEXT"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	LDA	LSTKI
	CMPA	#SIZE_NEST_LSTK
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBLO	IEXE_NEXT_ERR	;NEXTスタックが空ならエラー
	LDB	, Y+
	CMPB	#I_VAR	;NEXTの後ろに変数がなかったらエラー
	LBNE	IEXE_NEXT_ERR_NEXTWOV
	LDU	#LSTK
	LEAU	A, U
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;	U-1:変数インデックス
	;	U-3:増分
	;	U-5:終了値
	;	U-7:中間コードポインタ
	;	U-9:行ポインタ
	;FORスタックの変数名を取得
	LDB	-1, U
	;NEXTの後ろの変数と比較
	CMPB	, Y+	;一致しなかったらエラー
	BNE	IEXE_NEXT_ERR_NEXTUM
	JSR	VALUE_ADDRESS
	;増分を取得
	LDD	-3, U
	ADDD	, X
	STD	, X
	TFR	D, X
	LDD	-3, U	;増分をチェック
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEXT X=VAL, D=STEP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BMI	NEXT_STEP_MINUS
	;増分がプラスの場合
	CMPX	-5, U
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"END CHK +"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BGT	IEXE_NEXT_OVER	;終了値を超えたので終了
	BRA	IEXE_NEXT_CONT	;ループを継続
NEXT_STEP_MINUS	;増分がマイナスの場合
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"END CHK -"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPX	-5, U
	BLT	IEXE_NEXT_OVER
IEXE_NEXT_CONT	;ループの継続
	LDY	-7, U	;中間コードポインタを復帰
	LDD	-9, U	;行ポインタを復帰
	STD	CLP
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEXT CONT"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	RTS
IEXE_NEXT_OVER	;FOR-NEXTの終了
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEXT END"
	;::::::::::debug :::::::::::::
	LDA	LSTKI
	SUBA	#SIZE_NEST_LSTK
	STA	LSTKI	;スタックを1ネスト分戻す
	RTS

IEXE_NEXT_ERR_NEXTUM
	LDB	#ERR_NEXTUM
	BRA	NEXT_ERR_END
IEXE_NEXT_ERR_NEXTWOV
	LDB	#ERR_NEXTWOV
	BRA	NEXT_ERR_END
IEXE_NEXT_ERR	LDB	#ERR_LSTKUF
NEXT_ERR_END	STB	ERR_CODE
	RTS
	;-----------------------------------------------------------
IEXE_PRINT
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IEXE_PRINT\r"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IPRINT
	RTS
	;-----------------------------------------------------------
IEXE_INPUT
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IINPUT
	RTS
	;-----------------------------------------------------------
IEXE_LET
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	ILET
	RTS
	;-----------------------------------------------------------
IEXE_STOP	;最終行をまで行ポインタ(CLP)を移動する
	LDX	CLP
IEXE_STOP_LOOP	LDB	, X
	BEQ	IEXE_STOP_END
	ABX
	BRA	IEXE_STOP_LOOP
IEXE_STOP_END	STX	CLP
	PULS	D	;IEXE_CALLへの戻り先を破棄する
	TFR	X, D
	;IEXEの呼び出し元に戻る
	PULS	X, Y, U, PC
	;-----------------------------------------------------------
IEXE_SEMI
	LEAY	1, Y	;中間コードポインタを次へ進める
	RTS
	;-----------------------------------------------------------
IEXE_ARRAY
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IARRAY	;代入文を実行
	RTS
	;-----------------------------------------------------------
IEXE_VAR
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IVAR	;代入文を実行
	RTS

;---------------------------------------------------------------------------
; RUN command handler
;---------------------------------------------------------------------------
IRUN
	PSHS	D, X, Y, U
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IRUN START"
	;DBG_PRINT_REGS
	;DBG_NEWLINE
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
	CLR	GSTKI	;GOSUBスタックインデックスの初期化
	CLR	LSTKI	;FORスタックインデックスの初期化
	LDX	#LISTBUF
	STX	CLP	;行ポインタをリスト領域の先頭にセット
IRUN_LOOP	TST	, X	;行ポインタが末尾を指すまで繰り返す
	BEQ	IRUN_END
	LEAY	3, X
	LBSR	IEXE
	TST	ERR_CODE
	BNE	IRUN_END	;エラー発生時は終了
	STD	CLP
	TFR	D, X
	BRA	IRUN_LOOP

IRUN_END	PULS	D, X, Y, U, PC

;---------------------------------------------------------------------------
; LIST command handler
; IN	Y : CIP
;---------------------------------------------------------------------------
ILIST
	PSHS	D, X, Y, U
	LDA	, Y
	CMPA	#I_NUM
	BNE	ILIST_NO_ARG
	LEAX	, Y
	LBSR	GET_LINE_NO	;引数を取得し表示開始行番号とする
	TFR	D, U
	BRA	2F
ILIST_NO_ARG	LDU	#0
2	;行ポインタを表示開始行番号へ進める
	LDX	#LISTBUF	;行ポインタを先頭行へ設定
ILIST_LOOP1	TST	, X
	BEQ	ILIST_LOOP1_E	;末尾なので終了
	CMPU	1, X
	BLS	ILIST_LOOP1_E	;表示開始行以降なので終了
	LDB	, X	;行ポインタを次の行へ進める
	ABX
	BRA	ILIST_LOOP1
ILIST_LOOP1_E	;リストを表示する
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"LIST START"
	;DBG_PRINT_REGS
	;DBG_NEWLINE
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
ILIST_LOOP2	
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"ILIST_LOOP2"
	;DBG_PRINT_REGS
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	TST	, X
	BEQ	ILIST_LOOP2_E
	LBSR	GET_LINE_NO
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	X
	LDX	#0
	LBSR	C_PUTNUM	;行番号を表示
	LBSR	C_PUT_SPACE	;空白を入れる
	PULS	X
	LEAY	3, X
	LBSR	PUTLIST	;行番号より後ろを文字列に変換して表示
	TST	ERR_CODE
	BNE	ILIST_LOOP2_E	;エラー発生時はループを抜ける
	LBSR	C_NEWLINE	;改行
	LDB	, X	;行ポインタを次の行へ進める
	ABX
	BRA	ILIST_LOOP2
ILIST_LOOP2_E	PULS	D, X, Y, U, PC

;---------------------------------------------------------------------------
; NEW command handler
;---------------------------------------------------------------------------
INEW
	PSHS	X, U
	LDU	#0
	;変数の初期化
	LDX	#VAR
	LDA	#26
1	STU	, X++
	DECA
	BNE	1B
	;配列の初期化
	LDX	#ARR
	LDA	#SIZE_ARRY
1	STU	, X++
	DECA
	BNE	1B
	;実行制御用の初期化
	STA	GSTKI	;GOSUBスタックインデクスを0に初期化
	STA	LSTKI	;FORスタックインデクスを0に初期化
	STA	LISTBUF	;プログラム保存領域の先頭に末尾の印を置く
	LDX	#LISTBUF
	STX	CLP	;行ポインタをプログラム保存領域の先頭に設定
	CLR	ERR_CODE
	PULS	X, U, PC

;---------------------------------------------------------------------------
; Command processor
;---------------------------------------------------------------------------
ICOM
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"ICOM\r"
	;::::::::::debug :::::::::::::
	PSHS	X, Y
	LDY	#IBUF
	LDA	, Y
	CMPA	#I_LIST
	BLO	ICOM_OTHER
	BEQ	ICOM_LIST
	CMPA	#I_NEW
	BLO	ICOM_RUN
	BHI	ICOM_OTHER
ICOM_NEW	;NEW命令
	LEAY	1, Y	;中間コードポインタを次へ進める
	LDA	, Y
	CMPA	#I_EOL
	BNE	ICOM_ERR_SYNTAX	;行末以外はエラー
	;行末の場合NEW命令を実行
	LBSR	INEW
	PULS	X, Y, PC

ICOM_LIST	;LIST命令
	LEAY	1, Y	;中間コードポインタを次へ進める
	LDA	, Y
	CMPA	#I_EOL
	BEQ	1F
	LDA	3, Y
	CMPA	#I_EOL
	BNE	ICOM_ERR_SYNTAX
	;もし行末か、あるいは続いて引数があれば、LIST命令を実行
1	LBSR	ILIST
	PULS	X, Y, PC

ICOM_RUN	;RUN命令
	LEAY	1, Y	;中間コードポインタを次へ進める
	LBSR	IRUN
	PULS	X, Y, PC

ICOM_OTHER	;NEW/LIST/RUN以外
	;::::::::::debug :::::::::::::
	;DBG_DUMP_IBUF
	;::::::::::debug :::::::::::::
	LBSR	IEXE
	PULS	X, Y, PC

ICOM_ERR_SYNTAX	LDB	#ERR_SYNTAX
1	STB	ERR_CODE
	RTS


;---------------------------------------------------------------------------
;  TOYOSHIKI Tiny BASIC
;  The BASIC entry point
;---------------------------------------------------------------------------
BASIC
	LBSR	INEW	;実行環境を初期化

	;起動メッセージ
	LDX	#TITLE
	LBSR	C_PUTS	;「TOYOSHIKI TINY BASIC」を表示
	LBSR	C_NEWLINE
	LDX	#EDITION
	LBSR	C_PUTS	;版を区別する文字列を表示
	LBSR	C_NEWLINE
	;「OK」またはエラーメッセージを表示してエラー番号をクリア
	LBSR	ERROR

	;端末から1行を入力して実行
BASIC_LOOP
	LDA	#'>'
	LBSR	C_PUTCH	;プロンプトを表示
	LBSR	C_GETS	;1行を入力
	;1行の文字列を中間コードの並びに変換

;	;::::::::::debug :::::::::::::
;	BSR	DUMP_LBUF	;debug
;	;::::::::::debug :::::::::::::
	;文字列を中間コードに変換して長さを取得
	LBSR	TOKTOI
	TST	ERR_CODE
	BNE	BASIC_ERROR	;もしエラーが発生したら
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"TOKTOI LEN="
	;DBG_PUTHEX_A
	;DBG_NEWLINE
;	;::::::::::debug :::::::::::::
	LDB	IBUF
	CMPB	#I_NUM
	BNE	BASIC_COMMAND
	;もし中間コードバッファの先頭が行番号なら
	;中間コードの並びがプログラムと判断する
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"program\r"
;	;::::::::::debug :::::::::::::
	;中間コードバッファの先頭を長さに書き換える
	STA	IBUF	
	LBSR	INSLIST	;中間コードの1行をリストへ挿入
	TST	ERR_CODE
	BNE	BASIC_ERROR	;もしエラーが発生したら
	BRA	BASIC_LOOP	;繰り返しの先頭に戻る

BASIC_COMMAND	CMPB	#I_EOL
	BEQ	BASIC_ERROR
	;中間コードの並びが命令と判断される場合
	
	LBSR	ICOM
	;fall through
	;エラーメッセージを表示してエラー番号をクリア
BASIC_ERROR	LBSR	ERROR	
	BRA	BASIC_LOOP
;---------------------------------------------------------------------------
;*	INTERRUPT VECTORS
;---------------------------------------------------------------------------
	ORG	$FFF2
	FDB	SWI3
	FDB	SWI2
	FDB	FIRQ
	FDB	IRQ
	FDB	SWI
	FDB	NMI
	FDB	RESET
