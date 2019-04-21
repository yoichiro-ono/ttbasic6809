;---------------------------------------------------------------------------
;Xが指すBNNのバイト列からNNが表すshort型の値を返す
;Bが0の場合(リストの終端)はNNが存在しないので特別な値32767を返す
;中間コードポインタは進めない、必要なら3を足す
; Get line numbere by line pointer
;	IN	X	line pointer
;	OUT	D	line number
;---------------------------------------------------------------------------
GET_LINE_NO
	TST	, X
	BEQ	GET_LINE_NO_MAX
	LDD	1, X
	RTS
	;もし末尾だったら行番号の最大値を持ち帰る
GET_LINE_NO_MAX	LDD	#32767
	RTS

;---------------------------------------------------------------------------
; 行番号を指定して行番号が等しいか大きい行の先頭のポインタを得る
; グローバルな変数を変更しない
;	IN	D	line number
;	OUT	X	line pointer
;---------------------------------------------------------------------------
GET_LINE_PTR
	PSHS	D	;save lineno to stack
	LDX	#LISTBUF
1	;先頭から末尾まで繰り返す
	TST	, X
	BEQ	2F
	BSR	GET_LINE_NO
	CMPD	, S	;もし指定の行番号以上なら
	BHS	2F	;繰り返しを打ち切る
	LDB	, X
	ABX
	BRA	1B
2	;ポインタを持ち帰る
	PULS	D, PC

;---------------------------------------------------------------------------
; リスト末尾のアドレスを取得する
;	IN	X	リスト末尾のアドレス
;---------------------------------------------------------------------------
GET_LIST_TAIL
	PSHS	B
	LDX	#LISTBUF
GET_LIST_TAIL_L	LDB	, X
	BEQ	GET_LIST_TAIL_E
	ABX
	BRA	GET_LIST_TAIL_L
GET_LIST_TAIL_E
	PULS	B, PC

;---------------------------------------------------------------------------
; 空きメモリバイト数を取得する
;	OUT	D	FREE MEMORY SIZE
;---------------------------------------------------------------------------
GET_FREE_SIZE
	PSHS	X
	;リスト末尾のアドレスを取得
	BSR	GET_LIST_TAIL
	;リストに入っているバイト数を計算
	TFR	X, D
	SUBD	#LISTBUF
	;Dを反転する(減算のため)
	LBSR	NEGD
	ADDD	#(SIZE_LIST-1)
	PULS	X, PC

;---------------------------------------------------------------------------
;中間コードバッファの内容をリストバッファに保存
;エラーをエラーフラグで知らせる
;---------------------------------------------------------------------------
INSLIST	PSHS	D, X, Y, U
	;X:
	;Y:
	;U:挿入先のポインター(clp)

;	cip = ibuf;//ipは中間コードバッファの中間コードを指す
;		(リストの中間コードではない)
;	clp = getlp(getvalue(cip));//行番号を渡して挿入行の位置を取得

	LDX	#IBUF
	LBSR	GET_LINE_NO	;D<=行番号
	LBSR	GET_LINE_PTR	;X<=挿入先のポインタ
	LEAU	, X	;U<=挿入先のポインタ(clp)

	PSHS	D	;追加/更新する行番号

	;挿入先ポインタの持つ行番号を取得
	LBSR	GET_LINE_NO
	;挿入先の行番号と追加/更新する行番号を比較
	CMPD	, S
	BNE	INSLIST_INSERT
;	;::::::::::debug :::::::::::::
;	LBSR	PUTS
;	FCC	CR, "REPLACE",0
;	PUT_C	'b'
;	;::::::::::debug :::::::::::::
	;空き領域＋差し替え行のバイト数－更新行のバイト数<0の場合NG
	BSR	GET_FREE_SIZE
	ADDB	, X
	ADCA	#0
	;空き領域が現在の行のバイト数より少ない場合はNG
	;D = D - *(#IBUF)
	SUBB	IBUF
	BHS	1F
	SBCA	#0
	LBLS	INSLIST_E_LBUFOF
	;差し替え行を削除する
1	BSR	INSLIST_DEL_LINE
INSLIST_INSERT
;;	;::::::::::debug :::::::::::::
;	PUT_C	'c'
;;	;::::::::::debug :::::::::::::
	PULS	D
	LDX	#IBUF
	LDA	, X
	CMPA	#4	;4の場合は行番後のみでステートメントなし
	BEQ	INSLIST_END
	;空き領域のチェック
	LBSR	GET_FREE_SIZE
	;::::::::::debug :::::::::::::
;	DBG_PUTS	"\rFREE_SIZE:"
;	DBG_PUTHEX_D
;	DBG_NEWLINE
	;::::::::::debug :::::::::::::
	SUBB	, X
	BHS	1F
	SBCA	#0
	LBLS	INSLIST_E_LBUFOF
	;挿入のためのスペースを作る
1	BSR	INSLIST_MK_SPACE

;	;::::::::::debug :::::::::::::
;	LBSR	PUTS
;	FCC	CR, "U:",0
;	TFR	U, D
;	LBSR	PUTHEX_D
;	;::::::::::debug :::::::::::::
	;行を転送する
	LDX	#IBUF
	LDB	, X
	;転送
1	LDA	, X+
	STA	, U+
	DECB
	BNE	1B
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"INSLIST_END\r"
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
INSLIST_END
	PULS	D, X, Y, U, PC
	;-----------------------------------------------------
INSLIST_DEL_LINE
	PSHS	D, X, U
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"B INSLIST_DEL_LINE\r"
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
	;行番号が一致
	;U <= p1(挿入位置)
	LDA	, U
	LEAX	A, U	;X<=Uの次の行
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
INSL_MOVE_F	LDA	, X
	;次の行の長さが0の場合は終わり
	BEQ	INSL_MOVE_F_END
	;次の行を前に詰める
INSL_MOVE_F_LP	LDB	, X+
	STB	, U+
	DECA
	BNE	INSL_MOVE_F_LP
	BRA	INSL_MOVE_F
INSL_MOVE_F_END
	CLR	, U	;リストの末尾に0を置く
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"A INSLIST_DEL_LINE\r"
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
	PULS	D, X, U, PC
	;-----------------------------------------------------
INSLIST_MK_SPACE
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"INSLIST_MK_SPACE\r"
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
	PSHS	U	;clp
	LBSR	GET_LIST_TAIL	;X=lp1
	;移動する幅を計算
	TFR	X, D
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"\rLIST TAIL:"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	SUBD	, S
	ADDD	#1
	PSHS	D
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"\rMOVE_LEN:"
	;DBG_PUTHEX_D
	;::::::::::debug :::::::::::::
	LEAY	, X	;lp1
	LDB	IBUF	;lp2
	;::::::::::debug :::::::::::::
	;TFR	B, A
	;DBG_PUTS	"\r*CIP:"
	;DBG_PUTHEX_A
	;::::::::::debug :::::::::::::
	ABX
	PULS	D	;len(255以下のはず)
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CLRA
	STA	, X	;リストの最後を設定
INSLIST_LOOP	LDA	, -Y
	STA	, -X
	DECB
	BNE	INSLIST_LOOP
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"MK_SPACE\r"
	;DBG_DUMP_LIST
	;::::::::::debug :::::::::::::
	PULS	U, PC
	;-----------------------------------------------------
INSLIST_E_LBUFOF
	LDB	#ERR_LBUFOF
	STB	ERR_CODE
	CLRA
	PULS	D, X, Y, U, PC
;---------------------------------------------------------------------------
;中間コードの1行分をリスト表示
;引数は行の中の先頭の中間コードへのポインタ
;	IN	Y	行ポインタ
;---------------------------------------------------------------------------
PUTLIST	PSHS	D, X, U
	;行末でなければ繰り返す
PUTLIST_LOOP	LDA	, Y
	CMPA	#I_EOL
	BEQ	PUTLIST_END
	CMPA	#I_CODE_MIN
	BLO	PUTLIST_ERROR
	CMPA	#I_NUM
	BLO	PUTLIST_KEYWORD
	BEQ	PUTLIST_NUMBER
	CMPA	#I_STR
	BLO	PUTLIST_VAR
	BEQ	PUTLIST_STR
PUTLIST_ERROR	;どれにも当てはまらなかった場合はエラー
	LDA	#ERR_SYS
	STA	ERR_CODE
PUTLIST_END
	PULS	D, X, U, PC
	;-----------------------------------------------------
PUTLIST_KEYWORD	;キーワードの処理
	LBSR	GET_KEYWORD_STR
	;Xをアドレスとするキーワードを表示する
	LBSR	PUTLIST_PUTS_X
	;キーワードの後ろに空白を出力するかチェック
	LDA	, Y
	BSR	NOSPACE_AF
	;ポインタを次の中間コード or 文字数へ進める
	LDA	, Y+
	CMPA	#I_REM	;現在の中間コードがREMの場合
	BNE	PUTLIST_LOOP
	;もし中間コードがI_REMなら
	BSR	PUTLIST_PUTS_Y
	;コメントの後ろに中間コードはないので終了する
	PULS	D, X, U, PC
	;-----------------------------------------------------
PUTLIST_NUMBER	;定数の処理
	;値を取得して表示
	LDD	1, Y
	LDX	#0
	LBSR	C_PUTNUM
	LEAY	3, Y	;ポインタを次の命令に進める
	;次の命令をチェック
	BRA	PUTLIST_NEXTCHK
	;-----------------------------------------------------
PUTLIST_VAR	;変数の処理
	LEAY	1, Y	;ポインタを変数番号に進める
	LDA	, Y+	;変数番号を取得
	ADDA	#'A'
	LBSR	C_PUTCH
	;-----------------------------------------------------
	;次の命令をチェック
PUTLIST_NEXTCHK
	LDA	, Y
	;次の命令が空白表示例外に当たらなければ空白を表示する
	BSR	NOSPACE_BF
	BRA	PUTLIST_LOOP
	;-----------------------------------------------------
PUTLIST_STR	;文字列の処理
	;文字列の括りに使われている文字を調べる
	LEAY	1, Y	;ポインタを文字数へ進める
	LDB	, Y	;文字数
	;デリミタを決定する
	BSR	PUTLIST_SET_DLM
	PSHS	A	;「"」または「'」
	;文字列の括りを表示
	LBRA	C_PUTCH
	;文字列を表示する
	BSR	PUTLIST_PUTS_Y
	;文字列の括りを表示
	PULS	A
	LBRA	C_PUTCH
	BRA	PUTLIST_LOOP
	;-----------------------------------------------------
PUTLIST_PUTS_X	LDA	,X+
	BEQ	PUTLIST_PUTS_E
	LBSR	C_PUTCH
	BRA	PUTLIST_PUTS_X
PUTLIST_PUTS_E
	RTS
	;-----------------------------------------------------
PUTLIST_PUTS_Y	LDB	, Y+	;文字数を取得して表示する
	;コメントを表示する
PUTS_Y_LOOP	LDA	, Y+
	LBSR	C_PUTCH
	DECB
	BNE	PUTS_Y_LOOP
	RTS
	;-----------------------------------------------------
PUTLIST_SET_DLM	LDA	B, Y
	;「"」($22)が見つかった場合は、括りは「'」とする
	CMPA	#$22
	BEQ	PUTLIST_SET_DLM_E
	DECB
	BNE	PUTLIST_SET_DLM
	;「"」が見つからなかったので、括りは「"」とする
	LDA	#($22-5)
PUTLIST_SET_DLM_E
	ADDA	#5
	RTS
	;-----------------------------------------------------
	;キーワードの後ろに空白を出力するかチェックし
	;必要なら空白を出力
NOSPACE_AF	LBSR	IS_NOSPACE_AF
	BNE	NOSPACE_AF_E
	LBSR	C_PUT_SPACE
NOSPACE_AF_E	RTS
	;-----------------------------------------------------
	;次の命令が空白表示例外に当たらなければ空白を表示する
NOSPACE_BF	LBSR	IS_NOSPACE_BF
	BNE	NOSPACE_BF_E
	LBSR	C_PUT_SPACE
NOSPACE_BF_E	RTS
