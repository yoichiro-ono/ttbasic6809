;=====================================================================
; エラーメッセージ
;=====================================================================
MSG_ERR_OK	FCC	"OK"
	FCB	0
MSG_ERR_DIVBY0	FCC	"Devision by zero"
	FCB	0
MSG_ERR_VOF	FCC	"Overflow"
	FCB	0
MSG_ERR_SOR	FCC	"Subscript out of range"
	FCB	0
MSG_ERR_IBUFOF	FCC	"Icode buffer full"
	FCB	0
MSG_ERR_LBUFOF	FCC	"List full"
	FCB	0
MSG_ERR_GSTKOF	FCC	"GOSUB too many nested"
	FCB	0
MSG_ERR_GSTKUF	FCC	"RETURN stack underflow"
	FCB	0
MSG_ERR_LSTKOF	FCC	"FOR too many nested"
	FCB	0
MSG_ERR_LSTKUF	FCC	"NEXT without FOR"
	FCB	0
MSG_ERR_NEXTWOV	FCC	"NEXT without counter"
	FCB	0
MSG_ERR_NEXTUM	FCC	"NEXT mismatch FOR"
	FCB	0
MSG_ERR_FORWOV	FCC	"FOR without variable"
	FCB	0
MSG_ERR_FORWOTO	FCC	"FOR without TO"
	FCB	0
MSG_ERR_LETWOV	FCC	"LET without variable"
	FCB	0
MSG_ERR_IFWOC	FCC	"IF without condition"
	FCB	0
MSG_ERR_ULN	FCC	"Undefined line number"
	FCB	0
MSG_ERR_PAREN	FCC	"'(' or ')' expected"
	FCB	0
MSG_ERR_VWOEQ	FCC	"'=' expected"
	FCB	0
MSG_ERR_COM	FCC	"Illegal command"
	FCB	0
MSG_ERR_SYNTAX	FCC	"Syntax error"
	FCB	0
MSG_ERR_SYS	FCC	"Internal error"
	FCB	0
MSG_ERR_ESC	FCC	"Abort by [ESC]"
	FCB	0

ERROR_TBL
ERR_OK	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_OK
ERR_DIVBY0	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_DIVBY0
ERR_VOF	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_VOF
ERR_SOR	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_SOR
ERR_IBUFOF	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_IBUFOF
ERR_LBUFOF	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_LBUFOF
ERR_GSTKOF	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_GSTKOF
ERR_GSTKUF	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_GSTKUF
ERR_LSTKOF	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_LSTKOF
ERR_LSTKUF	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_LSTKUF
ERR_NEXTWOV	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_NEXTWOV
ERR_NEXTUM	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_NEXTUM
ERR_FORWOV	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_FORWOV
ERR_FORWOTO	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_FORWOTO
ERR_LETWOV	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_FORWOTO
ERR_IFWOC	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_IFWOC
ERR_ULN	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_ULN
ERR_PAREN	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_PAREN
ERR_VWOEQ	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_VWOEQ
ERR_COM	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_COM
ERR_SYNTAX	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_SYNTAX
ERR_SYS	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_SYS
ERR_ESC	EQU	(*-ERROR_TBL)
	FDB	MSG_ERR_ESC

;---------------------------------------------------------------------------
; Print OK or error message
;---------------------------------------------------------------------------
ERROR
	PSHS	D, X, Y
	TST	ERR_CODE
	BEQ	PRINT_MSG
	;もし「OK」ではなかったら
	;もしプログラムの実行中なら（cipがリストの中にあり、clpが末尾ではない場合）
	LBSR	C_NEWLINE	;改行
	CMPY	#LISTBUF
	BLO	IN_COMMAND	;プログラムの実行中でない
	CMPY	#(LISTBUF+SIZE_LIST)
	BHS	IN_COMMAND	;プログラムの実行中でない
	LDX	CLP
	TST	, X
	BEQ	IN_COMMAND	;プログラムの実行中でない
	;プログラムの実行中
	LDX	#PROMPT_LINE
	LBSR	C_PUTS	;「LINE:」を表示
	LDX	CLP	;行番号を取得
	LBSR	GET_LINE_NO
	LDX	0
	LBSR	C_PUTNUM	;行番号を表示
	LBSR	C_PUT_SPACE	;空白を表示
	LDY	CLP
	LEAY	3, Y
	LBSR	PUTLIST	;リストの該当行を表示
	BRA	PRINT_MSG
IN_COMMAND	;指示の実行中
	LDX	#PROMPT_YOU_TYPE
	LBSR	C_PUTS	;「YOU TYPE:」を表示
	LDX	#LBUF	;文字列バッファの内容を表示
	LBSR	C_PUTS
PRINT_MSG	LBSR	C_NEWLINE	;改行
	;エラーコードに対応したメッセージのアドレスを取得
	LDB	ERR_CODE
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"ERR_CODE"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDX	#ERROR_TBL
	ASLB
	ABX
	LDX	, X
	LBSR	C_PUTS	;「OK」またはエラーメッセージを表示
	LBSR	C_NEWLINE	;改行
	CLR	ERR_CODE
	PULS	D, X, Y, PC
