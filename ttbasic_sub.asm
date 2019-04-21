;---------------------------------------------------------------------------
;XORSHIFT-16bitによる乱数生成
; RANDOM_SEED ^= RANDOM_SEED << 7
; RANDOM_SEED ^= RANDOM_SEED >> 9
; RANDOM_SEED ^= RANDOM_SEED << 8
;	OUT	D	random($0000-$FFFF)
;---------------------------------------------------------------------------
RANDOM
	; seed ^= seed << 7
	LDA	RANDOM_SEED[1]
	LDB	RANDOM_SEED
	RORB
	RORA
	RORB
	ANDB	#$80
	EORA	RANDOM_SEED
	EORB	RANDOM_SEED[1]
	STD	RANDOM_SEED
	; RANDOM_SEED ^= RANDOM_SEED >> 9
	LDB	RANDOM_SEED
	LSRB
	EORB	RANDOM_SEED[1]
	STB	RANDOM_SEED[1]
	; RANDOM_SEED ^= RANDOM_SEED << 8
	LDA	RANDOM_SEED[1]
	EORA	RANDOM_SEED
	STA	RANDOM_SEED
	;d=RANDOM_SEED
	RTS
;---------------------------------------------------------------------------
;乱数取得
; 0～D-1の乱数を取得する
;---------------------------------------------------------------------------
GETRND
	PSHS	X
	TFR	D, X
	BSR	RANDOM
	EXG	X, D
	BSR	DIV16
	PULS	X, PC

;---------------------------------------------------------------------------
;16bit 除算
;	IN	X	被除数
;		D	除数
;	OUT	X	商(quotient)
;		D	剰余(remainder)
;---------------------------------------------------------------------------
DIV16	PSHS	X,B,A
	LDB	#16
	PSHS	B
	CLRA
	CLRB
	PSHS	B,A
;* 0,S=16-bit quotient; 2,S=loop counter;
;* 3,S=16-bit divisor; 5,S=16-bit dividend

D16010	LSL	6,S		;shift MSB of dividend into carry
	ROL	5,S		;shift carry and MSB of dividend, into carry
	ROLB			;new bit of dividend now in bit 0 of B
	ROLA
	CMPD	3,S		;does the divisor "fit" into D?
	BLO	D16020		;if not
	SUBD	3,S
	ORCC	#1		;set carry
	BRA	D16030
D16020	ANDCC	#$FE		;reset carry
D16030	ROL	1,S		;shift carry into quotient
	ROL	,S

	DEC	2,S		;another bit of the dividend to process?
	BNE	D16010		;if yes

	PULS	X		;quotient to return
	LEAS	5,S
	RTS
;---------------------------------------------------------------------------
; 16bit乗算
; 	IN	D	被乗数(multiplicand)
;		X	乗数(multiplier)
;	OUT	D	積(product)
;---------------------------------------------------------------------------
MUL16	PSHS	U,X,B,A	;U pushed to create 2 temp bytes at 4,S
	LDB	3,S	;low byte of original X
	MUL
	STD	4,S	;keep for later
	LDD	1,S	;low byte of orig D, high byte of orig X
	MUL
	ADDB	5,S	;only low byte is needed
	STB	5,S
	LDA	1,S	;low byte of orig D
	LDB	3,S	;low byte of orig X
	MUL
	ADDA	5,S
	LEAS	6,S
	RTS
;---------------------------------------------------------------------------
; 16bit乗算(10倍固定)
; 	IN	D	被乗数(multiplicand)
;	OUT	D	積(product)
;---------------------------------------------------------------------------
MUL10D
	;D=D*2
	CLR_FLG		;2
	ROLB		;1
	ROLA		;1
	PSHS	D	;5+2:2D
	;D=D*4
	CLR_FLG		;2
	ROLB		;1
	ROLA		;1
	CLR_FLG		;2
	ROLB		;1
	ROLA		;1:8D
	;8D+2D=10D
	ADDD	, S	;6+1
	LEAS	2, S	;4+1
	RTS
;---------------------------------------------------------------------------
; 16bit積和(10倍固定: X * 10 + A)
; 	IN	X	被乗数(multiplicand)
;		A	加数
;	OUT	X	積(product)
;---------------------------------------------------------------------------
MUL_X_BY_10_ADD_A
	PSHS	D
	TFR	X, D
	BSR	MUL10D
	TFR	D, X
	PULS	D
	LEAX	A, X
	RTS
;---------------------------------------------------------------------------
; Neg D
;	IN	D
;	OUT	D
;---------------------------------------------------------------------------
NEGD	COMA
	COMB
	ADDD	#1
	RTS
;---------------------------------------------------------------------------
;文字列のデリミタ(" or ')か？
;	IN 	A
;	OUT	ZF	SET : YES
;			RESET : NO
;---------------------------------------------------------------------------
IS_STRING_DLM
	CMPA	#$22
	BEQ	1F
	CMPA	#$27
1	RTS
;---------------------------------------------------------------------------
;空白の読み飛ばし
;	IN	Y	文字列
;	OUT	Y	空白の次の文字
;---------------------------------------------------------------------------
SKIP_SPACE_Y
	LDA	, Y+
	BEQ	SKIP_SPACE_Y_E
	LBSR	ISSPACE
	BNE	SKIP_SPACE_Y_E
	BRA	SKIP_SPACE_Y
SKIP_SPACE_Y_E	LEAY	-1, Y
	RTS
;---------------------------------------------------------------------------
;文字列の長さを取得
;	IN	X	文字列
;	OUT	A	文字数
;---------------------------------------------------------------------------
STRLEN_X
	LDA	#-1
1	INCA
	TST	A, X
	BNE	1B
	RTS
;---------------------------------------------------------------------------
;文字列の長さを取得
;	IN	Y	文字列
;		A	文字列のデリミタ
;	OUT	B	文字数
;---------------------------------------------------------------------------
STRLEN_Y
	PSHS	A
	CLRB
1	LDA	B, Y
	BEQ	2F
	LBSR	ISPRINT
	BNE	2F
	CMPA	, S	;先頭の文字とチェック
	BEQ	2F
	INCB
	BRA	1B
2	PULS	A, PC
;---------------------------------------------------------------------------
;文字列を数値に変換
;	IN	Y	文字列
;	OUT	D	数値
;		Y	数値の後ろの文字
;		ZF	SET : OK
;			RESET : NG
;---------------------------------------------------------------------------
STR_TO_INT	PSHS	X
	LDX	#0	;値をクリア
	PSHS	X
1	LDA	, Y+
	LBSR	ISDIGIT
	BNE	2F
	SUBA	#'0'
	LBSR	MUL_X_BY_10_ADD_A
	CMPX	, S	;前回の値と比較
	BLO	3F	;前回より小さい場合はエラー
	STX	, S
	BRA	1B
2	LEAY	-1, Y
	SET_ZF
3	PULS	D, X, PC

;---------------------------------------------------------------------------
;大文字に変換する
;	IN	A	文字
;	OUT	A	大文字に変換した文字
;---------------------------------------------------------------------------
TOUPPER
	LBSR	ISALPHA
	BNE	1F
	ANDA	#$DF
1	RTS
;---------------------------------------------------------------------------
;表示可能文字か？
;	IN	A
;	OUT	ZF	SET : 表示可
;			RESET : 表示不可
;---------------------------------------------------------------------------
ISPRINT	CMPA	#' '
	BLO	2F	;CLEAR ZERO FLAG
	CMPA	#126
	BHI	2F	;CLEAR ZERO FLAG
	BRA	1F	;SET ZERO FLAG
;---------------------------------------------------------------------------
;空白文字か？
;	IN	A
;	OUT	ZF	SET : 空白
;			RESET : 空白以外
;---------------------------------------------------------------------------
ISSPACE	CMPA	#' '
	BEQ	3F
	CMPA	#9
	BLO	2F	;CLEAR ZERO FLAG
	CMPA	#13
	BHI	2F	;CLEAR ZERO FLAG
1	SET_ZF
3	RTS
;---------------------------------------------------------------------------
;数字か？
;	IN	A
;	OUT	ZF	SET : 数字
;			RESET : 数字以外
;---------------------------------------------------------------------------
ISDIGIT	CMPA	#'0'
	BLO	2F	;CLEAR ZERO FLAG
	CMPA	#('9')
	BLS	1B	;SET ZERO FLAG
2	CLR_ZF
	RTS
;---------------------------------------------------------------------------
;英字か？
;	IN	A
;	OUT	ZF	SET : 英字
;			RESET : 英字以外
;---------------------------------------------------------------------------
ISALPHA	ORA	#%00100000	;小文字に変換する
	CMPA	#'a'
	BLO	2B	;CLEAR ZERO FLAG
	CMPA	#'z'
	BHI	2B	;CLEAR ZERO FLAG
	BRA	1B	;SET ZERO FLAG
