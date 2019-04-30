;---------------------------------------------------------------------------
; キーワード、中間コード変換
;---------------------------------------------------------------------------
KW_GOTO	FCC	"GOTO"
	FCB	0
KW_GOSUB	FCC	"GOSUB"
	FCB	0
KW_RETURN	FCC	"RETURN"
	FCB	0
KW_FOR	FCC	"FOR"
	FCB	0
KW_TO	FCC	"TO"
	FCB	0
KW_STEP	FCC	"STEP"
	FCB	0
KW_NEXT	FCC	"NEXT"
	FCB	0
KW_IF	FCC	"IF"
	FCB	0
KW_REM	FCC	"REM"
	FCB	0
KW_STOP	FCC	"STOP"
	FCB	0
KW_INPUT	FCC	"INPUT"
	FCB	0
KW_PRINT	FCC	"PRINT"
	FCB	0
KW_LET	FCC	"LET"
	FCB	0
KW_COMMA	FCC	","
	FCB	0
KW_SEMI	FCC	";"
	FCB	0
KW_MINUS	FCC	"-"
	FCB	0
KW_PLUS	FCC	"+"
	FCB	0
KW_MUL	FCC	"*"
	FCB	0
KW_DIV	FCC	"/"
	FCB	0
KW_OPEN	FCC	"("
	FCB	0
KW_CLOSE	FCC	")"
	FCB	0
KW_GTE	FCC	">="
	FCB	0
KW_NEQ	FCC	"<>"
	FCB	0
KW_SHARP	FCC	"#"
	FCB	0
KW_GT	FCC	">"
	FCB	0
KW_EQ	FCC	"="
	FCB	0
KW_LTE	FCC	"<="
	FCB	0
KW_LT	FCC	"<"
	FCB	0
KW_ARRAY	FCC	"@"
	FCB	0
KW_RND	FCC	"RND"
	FCB	0
KW_ABS	FCC	"ABS"
	FCB	0
KW_SIZE	FCC	"SIZE"
	FCB	0
KW_LIST	FCC	"LIST"
	FCB	0
KW_RUN	FCC	"RUN"
	FCB	0
KW_NEW	FCC	"NEW"
	FCB	0

KW_TO_ICODE_TBL
I_CODE_MIN	EQU	$80
I_IF	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_IF
	FCB	I_IF
I_GOTO	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_GOTO
	FCB	I_GOTO
I_GOSUB	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_GOSUB
	FCB	I_GOSUB
I_RETURN	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_RETURN
	FCB	I_RETURN
I_FOR	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_FOR
	FCB	I_FOR
I_TO	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_TO
	FCB	I_TO
I_STEP	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_STEP
	FCB	I_STEP
I_NEXT	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_NEXT
	FCB	I_NEXT
I_PRINT	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_PRINT
	FCB	I_PRINT
I_INPUT	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_INPUT
	FCB	I_INPUT
I_REM	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_REM
	FCB	I_REM
I_LET	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_LET
	FCB	I_LET
I_STOP	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_STOP
	FCB	I_STOP
I_SEMI	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_SEMI
	FCB	I_SEMI
	;演算子の先頭
I_MINUS	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_MINUS
	FCB	I_MINUS
I_PLUS	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_PLUS
	FCB	I_PLUS
I_MUL	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_MUL
	FCB	I_MUL
I_DIV	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_DIV
	FCB	I_DIV
I_NEQ	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_NEQ
	FCB	I_NEQ
I_EQ	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_EQ
	FCB	I_EQ
I_SHARP	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_SHARP
	FCB	I_SHARP
I_LT	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_LT
	FCB	I_LT
I_LTE	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_LTE
	FCB	I_LTE
I_GT	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_GT
	FCB	I_GT
I_GTE	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_GTE
	FCB	I_GTE
I_OPEN	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_OPEN
	FCB	I_OPEN
I_CLOSE	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_CLOSE
	FCB	I_CLOSE
I_COMMA	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_COMMA
	FCB	I_COMMA
I_ARRAY	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_ARRAY
	FCB	I_ARRAY
I_RND	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_RND
	FCB	I_RND
I_ABS	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_ABS
	FCB	I_ABS
I_SIZE	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_SIZE
	FCB	I_SIZE
I_LIST	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_LIST
	FCB	I_LIST
I_RUN	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_RUN
	FCB	I_RUN
I_NEW	EQU	(*-KW_TO_ICODE_TBL)/3+I_CODE_MIN
	FDB	KW_NEW
	FCB	I_NEW
	FDB	$FFFF	;キーワード終わり
	;以降はキーワードではないので空白は個別処理される
I_NUM	EQU	I_NEW+1
I_VAR	EQU	I_NUM+1
I_STR	EQU	I_VAR+1
I_EOL	EQU	I_STR+1

;-----------------------------------------------------
;TOKENからICODEを取得する
;IN	Y	TOKENへのポインタ
;OUT	ZERO FLG	SET : 変換OK
;          		RESET : 変換NG
;-----------------------------------------------------
TOKEN_TO_ICODE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TOKEN_TO_ICODE"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;キーワードテーブルで変換を試みる
	LDU	#KW_TO_ICODE_TBL	;U <= キーワードテーブル
1	LDX	, U	;キーワードへのポインタを取得
	CMPX	#$FFFF	;$FFFFの場合はキーワードが終わり
	BEQ	4F
	;文字の先頭を保存
	PSHS	Y
	;キーワードと単語の比較
2	;文字バッファから1文字取り出して大文字に変換
	LDA	, Y+
	LBSR	TOUPPER
	;キーワードの終了判定
	TST	, X
	BEQ	3F
	;キーワードと比較
	CMPA	, X+
	BEQ	2B
	PULS	Y
	LEAU	3, U	;次のキーワードへ移動
	BRA	1B
3	;キーワードが一致した
	PULS	X	;保存していた位置を破棄
	LDA	2, U	;ICODEを取得
	LEAY	-1, Y
	SET_ZF
	RTS
4	;キーワードが不一致
	CLR_ZF
	RTS


;-----------------------------------------------------
;中間コードが後ろに空白を入れない中間コードかチェックする
;IN	A	中間コード
;OUT	ZERO FLG	SET : 空白を入れない
;          		RESET : 空白を入れる
;-----------------------------------------------------
IS_NOSPACE_AF
	PSHS	X
	LDX	#NSA_TBL
	BRA	NOSPACE_CHK
	

;-----------------------------------------------------
;中間コードが前が定数か変数のとき前の空白をなくす中間コード
;IN	A	中間コード
;OUT	ZERO FLG	SET : 空白を入れない
;          		RESET : 空白を入れる
;-----------------------------------------------------
IS_NOSPACE_BF
	PSHS	X
	LDX	#NSB_TBL
NOSPACE_CHK	CMPA	, X
	BEQ	1F
	TST	, X+
	BNE	NOSPACE_CHK
	CLR_ZF
1	PULS	X, PC

;後ろに空白を入れない中間コード
NSA_TBL	FCB	I_RETURN
	FCB	I_STOP
	FCB	I_COMMA
	FCB	I_MINUS
	FCB	I_PLUS
	FCB	I_MUL
	FCB	I_DIV
	FCB	I_OPEN
	FCB	I_CLOSE
	FCB	I_GTE
	FCB	I_SHARP
	FCB	I_GT
	FCB	I_EQ
	FCB	I_NEQ
	FCB	I_LTE
	FCB	I_LT
	FCB	I_ARRAY
	FCB	I_RND
	FCB	I_ABS
	FCB	I_SIZE
	FCB	0

;前が定数か変数のとき前の空白をなくす中間コード
NSB_TBL
	FCB	I_MINUS
	FCB	I_PLUS
	FCB	I_MUL
	FCB	I_DIV
	FCB	I_OPEN
	FCB	I_CLOSE
	FCB	I_GTE
	FCB	I_SHARP
	FCB	I_GT
	FCB	I_EQ
	FCB	I_NEQ
	FCB	I_LTE
	FCB	I_LT
	FCB	I_COMMA
	FCB	I_SEMI
	FCB	I_EOL
	FCB	0


;-----------------------------------------------------
;内部コードを内部コード変換バッファに追加する
;	IN	A	中間コード
;-----------------------------------------------------
STORE_ICODE_B
	PSHS	B, X
	LDX	#IBUF
	LDB	WLEN
	INC	WLEN
	STA	B, X
	PULS	B, X, PC
;-----------------------------------------------------
;内部コードを内部コード変換バッファに追加する
;	IN	D	中間コード
;-----------------------------------------------------
STORE_ICODE_W
	PSHS	D, X
	LDX	#IBUF
	LDB	WLEN
	ABX
	ADDB	#2
	STB	WLEN
	PULS	D
	STD	, X
	PULS	X, PC

;---------------------------------------------------------------------------
;トークンを内部コードに変換する
;Convert token to i-code
;Return byte length or 0
;Called by only INPUT statement
;	OUT	A	中間コードバッファの長さ
;---------------------------------------------------------------------------
TOKTOI
	PSHS	X, Y, U
	LDY	#LBUF
	CLR	WLEN	;中間コードのバイト数
TOKTOI_LOOP	
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TOKTOI"
	;DBG_DUMP_LBUF
	;::::::::::debug :::::::::::::
	LBSR	SKIP_SPACE_Y
	TST	, Y
	LBEQ	TOKTOI_END
	;キーワードテーブルでICODEに変換を試みる
	LBSR	TOKEN_TO_ICODE
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BEQ	KEYWORD
	LDA	, Y
	;数字の場合は、定数への変換を試みる
	LBSR	ISDIGIT
	LBEQ	TOKEN_NUMBER
	;「"」or「'」の場合は文字列への返還を試みる
	LBSR	IS_STRING_DLM
	LBEQ	TOKEN_STRING
	;変数への変換を試みる
	LBSR	ISALPHA
	LBNE	TOKEN_E_SYNTAX	;アルファベット以外の場合はエラー
	LDB	WLEN
	CMPB	#(SIZE_IBUF-2)	;もし中間コードが長すぎたら
	LBHS	TOKEN_E_IBUFOF	;エラー
	;変数が3個並んだらエラー
	CMPB	#4
	BLO	TOKEN_VAR
	;直前が変数かチェック
	LDX	#IBUF
	ABX
	LDA	-2, X
	CMPA	#I_VAR
	BNE	TOKEN_VAR
	LDA	-4, X
	CMPA	#I_VAR
	LBEQ	TOKEN_E_SYNTAX	;変数が３個並ぶためエラー
	;-----------------------------------------------------
TOKEN_VAR	LDA	#I_VAR
	LBSR	STORE_ICODE_B
	LDA	, Y+
	LBSR	TOUPPER
	SUBA	#'A'
	LBSR	STORE_ICODE_B
	LBRA	TOKTOI_LOOP
	;-----------------------------------------------------
KEYWORD	;キーワードが一致した
	LDB	WLEN
	CMPB	#(SIZE_IBUF-1)	;もし中間コードが長すぎたら
	LBHS	TOKEN_E_IBUFOF	;エラー
	;中間コードをを保存
	LBSR	STORE_ICODE_B
	;コメントの場合はコメント処理を行う
	CMPA	#I_REM
	;コメント以外なので繰り返しの先頭へ戻って次の単語を変換する
	LBNE	TOKTOI_LOOP
	;-----------------------------------------------------
TOKEN_COMMENT	;コメントを保存し、終了する
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"\rTOKEN_COMMENT\r"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBSR	SKIP_SPACE_Y
	LEAX	, Y
	;コメントの文字数を取得
	LBSR	STRLEN_X
	TFR	A, B
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"STRLEN\r"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	ADDB	WLEN
	;もし中間コードが長すぎたらエラー番号をセット
	CMPB	#(SIZE_IBUF-2)
	LBHS	TOKEN_E_IBUFOF
	;コメントの文字数を記録
	LBSR	STORE_ICODE_B
	LDX	#IBUF
	LDB	WLEN
	ABX
	;コメントを記録
TOKEN_CMT_L2	LDA	, Y+
	BEQ	TOKTOI_END	;文字列の処理を打ち切る（終端の処理へ進む）
	STA	, X+
	INC	WLEN
	LBRA	TOKEN_CMT_L2
	;-----------------------------------------------------
TOKTOI_END	LDA	#I_EOL
	LBSR	STORE_ICODE_B
	;::::::::::debug :::::::::::::
	;DBG_DUMP_IBUF
	;::::::::::debug :::::::::::::
	LDA	WLEN
	PULS	X, Y, U, PC
	;-----------------------------------------------------
TOKEN_NUMBER	;数値への変換を行う
;	;::::::::::debug :::::::::::::
;	PSHS	D, Y
;	LBSR	PUTS
;	FCC	CR,"Y(1)=",0
;	TFR	Y, D
;	LBSR	PUTHEX_D
;	LBSR	NEWLINE
;	PULS	D, Y
;	;::::::::::debug :::::::::::::
	LBSR	STR_TO_INT
	BNE	TOKEN_E_NUM_VOF	;エラー
	STD	VALUE1
;	;::::::::::debug :::::::::::::
;	PSHS	D, Y
;	LBSR	PUTS
;	FCC	CR,"Y(2)=",0
;	TFR	Y, D
;	LBSR	PUTHEX_D
;	LBSR	NEWLINE
;	PULS	D, Y
;	;::::::::::debug :::::::::::::
	LDX	#IBUF
	;数値定数
	LDA	WLEN
	CMPA	#(SIZE_IBUF-3)
	LBHS	TOKEN_E_IBUFOF	;もし中間コードが長すぎたらエラー

	LDA	#I_NUM
	LBSR	STORE_ICODE_B
	LDD	VALUE1
	LBSR	STORE_ICODE_W
	LBRA	TOKTOI_LOOP
	;-----------------------------------------------------
TOKEN_STRING	;文字列への変換を試みる
	;先頭の文字を記憶する
	STA	SIGN
	LEAY	1, Y	;次の文字に進む
	LBSR	STRLEN_Y
	TFR	B, A
	INCA
	ADDA	WLEN
	;もし中間コードが長すぎたらエラー
	CMPA	#SIZE_IBUF
	BHS	TOKEN_E_IBUFOF
	;中間コードを記録
	LDA	#I_STR
	LBSR	STORE_ICODE_B
	;文字列の文字数を記録
	TFR	B, A
	LBSR	STORE_ICODE_B
	;文字列を記録
1	DECB
	BMI	2F
	LDA	, Y+
	LBSR	STORE_ICODE_B
	BRA	1B
2	LDA	, Y
	CMPA	SIGN
	LBNE	TOKTOI_LOOP
	;もし文字が「"」か「'」なら次の文字へ進む
	LEAY	1, Y
	LBRA	TOKTOI_LOOP
	;-----------------------------------------------------
TOKEN_E_IBUFOF
	LDB	#ERR_IBUFOF
	BRA	TOKEN_ERR

	;-----------------------------------------------------
TOKEN_E_SYNTAX
	LDB	#ERR_SYNTAX
	BRA	TOKEN_ERR
	;-----------------------------------------------------
TOKEN_E_NUM_VOF
	LDB	#ERR_VOF
TOKEN_ERR	STB	ERR_CODE
	CLRA
	PULS	X, Y, U, PC
;---------------------------------------------------------------------------
;中間コードに対応したキーワード文字列のアドレスを取得する
;	IN	A	中間コード
;	OUT	X	キーワード文字列のアドレス
;---------------------------------------------------------------------------
GET_KEYWORD_STR
	PSHS	B
	LDX	#KW_TO_ICODE_TBL
	;キーワード文字列のアドレスを取得
	SUBA	#I_CODE_MIN
	TFR	A, B
	;文字列のアドレス=KW_TO_ICODE_TBL+(ICODE-I_CODE_MIN)*3
	ABX
	ABX
	ABX
	LDX	, X
	PULS	B, PC
