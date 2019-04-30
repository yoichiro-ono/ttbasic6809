;---------------------------------------------------------------------------
; �L�[���[�h�A���ԃR�[�h�ϊ�
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
	;���Z�q�̐擪
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
	FDB	$FFFF	;�L�[���[�h�I���
	;�ȍ~�̓L�[���[�h�ł͂Ȃ��̂ŋ󔒂͌ʏ��������
I_NUM	EQU	I_NEW+1
I_VAR	EQU	I_NUM+1
I_STR	EQU	I_VAR+1
I_EOL	EQU	I_STR+1

;-----------------------------------------------------
;TOKEN����ICODE���擾����
;IN	Y	TOKEN�ւ̃|�C���^
;OUT	ZERO FLG	SET : �ϊ�OK
;          		RESET : �ϊ�NG
;-----------------------------------------------------
TOKEN_TO_ICODE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TOKEN_TO_ICODE"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;�L�[���[�h�e�[�u���ŕϊ������݂�
	LDU	#KW_TO_ICODE_TBL	;U <= �L�[���[�h�e�[�u��
1	LDX	, U	;�L�[���[�h�ւ̃|�C���^���擾
	CMPX	#$FFFF	;$FFFF�̏ꍇ�̓L�[���[�h���I���
	BEQ	4F
	;�����̐擪��ۑ�
	PSHS	Y
	;�L�[���[�h�ƒP��̔�r
2	;�����o�b�t�@����1�������o���đ啶���ɕϊ�
	LDA	, Y+
	LBSR	TOUPPER
	;�L�[���[�h�̏I������
	TST	, X
	BEQ	3F
	;�L�[���[�h�Ɣ�r
	CMPA	, X+
	BEQ	2B
	PULS	Y
	LEAU	3, U	;���̃L�[���[�h�ֈړ�
	BRA	1B
3	;�L�[���[�h����v����
	PULS	X	;�ۑ����Ă����ʒu��j��
	LDA	2, U	;ICODE���擾
	LEAY	-1, Y
	SET_ZF
	RTS
4	;�L�[���[�h���s��v
	CLR_ZF
	RTS


;-----------------------------------------------------
;���ԃR�[�h�����ɋ󔒂����Ȃ����ԃR�[�h���`�F�b�N����
;IN	A	���ԃR�[�h
;OUT	ZERO FLG	SET : �󔒂����Ȃ�
;          		RESET : �󔒂�����
;-----------------------------------------------------
IS_NOSPACE_AF
	PSHS	X
	LDX	#NSA_TBL
	BRA	NOSPACE_CHK
	

;-----------------------------------------------------
;���ԃR�[�h���O���萔���ϐ��̂Ƃ��O�̋󔒂��Ȃ������ԃR�[�h
;IN	A	���ԃR�[�h
;OUT	ZERO FLG	SET : �󔒂����Ȃ�
;          		RESET : �󔒂�����
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

;���ɋ󔒂����Ȃ����ԃR�[�h
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

;�O���萔���ϐ��̂Ƃ��O�̋󔒂��Ȃ������ԃR�[�h
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
;�����R�[�h������R�[�h�ϊ��o�b�t�@�ɒǉ�����
;	IN	A	���ԃR�[�h
;-----------------------------------------------------
STORE_ICODE_B
	PSHS	B, X
	LDX	#IBUF
	LDB	WLEN
	INC	WLEN
	STA	B, X
	PULS	B, X, PC
;-----------------------------------------------------
;�����R�[�h������R�[�h�ϊ��o�b�t�@�ɒǉ�����
;	IN	D	���ԃR�[�h
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
;�g�[�N��������R�[�h�ɕϊ�����
;Convert token to i-code
;Return byte length or 0
;Called by only INPUT statement
;	OUT	A	���ԃR�[�h�o�b�t�@�̒���
;---------------------------------------------------------------------------
TOKTOI
	PSHS	X, Y, U
	LDY	#LBUF
	CLR	WLEN	;���ԃR�[�h�̃o�C�g��
TOKTOI_LOOP	
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TOKTOI"
	;DBG_DUMP_LBUF
	;::::::::::debug :::::::::::::
	LBSR	SKIP_SPACE_Y
	TST	, Y
	LBEQ	TOKTOI_END
	;�L�[���[�h�e�[�u����ICODE�ɕϊ������݂�
	LBSR	TOKEN_TO_ICODE
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BEQ	KEYWORD
	LDA	, Y
	;�����̏ꍇ�́A�萔�ւ̕ϊ������݂�
	LBSR	ISDIGIT
	LBEQ	TOKEN_NUMBER
	;�u"�vor�u'�v�̏ꍇ�͕�����ւ̕Ԋ҂����݂�
	LBSR	IS_STRING_DLM
	LBEQ	TOKEN_STRING
	;�ϐ��ւ̕ϊ������݂�
	LBSR	ISALPHA
	LBNE	TOKEN_E_SYNTAX	;�A���t�@�x�b�g�ȊO�̏ꍇ�̓G���[
	LDB	WLEN
	CMPB	#(SIZE_IBUF-2)	;�������ԃR�[�h������������
	LBHS	TOKEN_E_IBUFOF	;�G���[
	;�ϐ���3���񂾂�G���[
	CMPB	#4
	BLO	TOKEN_VAR
	;���O���ϐ����`�F�b�N
	LDX	#IBUF
	ABX
	LDA	-2, X
	CMPA	#I_VAR
	BNE	TOKEN_VAR
	LDA	-4, X
	CMPA	#I_VAR
	LBEQ	TOKEN_E_SYNTAX	;�ϐ����R���Ԃ��߃G���[
	;-----------------------------------------------------
TOKEN_VAR	LDA	#I_VAR
	LBSR	STORE_ICODE_B
	LDA	, Y+
	LBSR	TOUPPER
	SUBA	#'A'
	LBSR	STORE_ICODE_B
	LBRA	TOKTOI_LOOP
	;-----------------------------------------------------
KEYWORD	;�L�[���[�h����v����
	LDB	WLEN
	CMPB	#(SIZE_IBUF-1)	;�������ԃR�[�h������������
	LBHS	TOKEN_E_IBUFOF	;�G���[
	;���ԃR�[�h����ۑ�
	LBSR	STORE_ICODE_B
	;�R�����g�̏ꍇ�̓R�����g�������s��
	CMPA	#I_REM
	;�R�����g�ȊO�Ȃ̂ŌJ��Ԃ��̐擪�֖߂��Ď��̒P���ϊ�����
	LBNE	TOKTOI_LOOP
	;-----------------------------------------------------
TOKEN_COMMENT	;�R�����g��ۑ����A�I������
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"\rTOKEN_COMMENT\r"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBSR	SKIP_SPACE_Y
	LEAX	, Y
	;�R�����g�̕��������擾
	LBSR	STRLEN_X
	TFR	A, B
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"STRLEN\r"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	ADDB	WLEN
	;�������ԃR�[�h������������G���[�ԍ����Z�b�g
	CMPB	#(SIZE_IBUF-2)
	LBHS	TOKEN_E_IBUFOF
	;�R�����g�̕��������L�^
	LBSR	STORE_ICODE_B
	LDX	#IBUF
	LDB	WLEN
	ABX
	;�R�����g���L�^
TOKEN_CMT_L2	LDA	, Y+
	BEQ	TOKTOI_END	;������̏�����ł��؂�i�I�[�̏����֐i�ށj
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
TOKEN_NUMBER	;���l�ւ̕ϊ����s��
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
	BNE	TOKEN_E_NUM_VOF	;�G���[
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
	;���l�萔
	LDA	WLEN
	CMPA	#(SIZE_IBUF-3)
	LBHS	TOKEN_E_IBUFOF	;�������ԃR�[�h������������G���[

	LDA	#I_NUM
	LBSR	STORE_ICODE_B
	LDD	VALUE1
	LBSR	STORE_ICODE_W
	LBRA	TOKTOI_LOOP
	;-----------------------------------------------------
TOKEN_STRING	;������ւ̕ϊ������݂�
	;�擪�̕������L������
	STA	SIGN
	LEAY	1, Y	;���̕����ɐi��
	LBSR	STRLEN_Y
	TFR	B, A
	INCA
	ADDA	WLEN
	;�������ԃR�[�h������������G���[
	CMPA	#SIZE_IBUF
	BHS	TOKEN_E_IBUFOF
	;���ԃR�[�h���L�^
	LDA	#I_STR
	LBSR	STORE_ICODE_B
	;������̕��������L�^
	TFR	B, A
	LBSR	STORE_ICODE_B
	;��������L�^
1	DECB
	BMI	2F
	LDA	, Y+
	LBSR	STORE_ICODE_B
	BRA	1B
2	LDA	, Y
	CMPA	SIGN
	LBNE	TOKTOI_LOOP
	;�����������u"�v���u'�v�Ȃ玟�̕����֐i��
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
;���ԃR�[�h�ɑΉ������L�[���[�h������̃A�h���X���擾����
;	IN	A	���ԃR�[�h
;	OUT	X	�L�[���[�h������̃A�h���X
;---------------------------------------------------------------------------
GET_KEYWORD_STR
	PSHS	B
	LDX	#KW_TO_ICODE_TBL
	;�L�[���[�h������̃A�h���X���擾
	SUBA	#I_CODE_MIN
	TFR	A, B
	;������̃A�h���X=KW_TO_ICODE_TBL+(ICODE-I_CODE_MIN)*3
	ABX
	ABX
	ABX
	LDX	, X
	PULS	B, PC
