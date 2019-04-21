;---------------------------------------------------------------------------
;XORSHIFT-16bit�ɂ�闐������
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
;�����擾
; 0�`D-1�̗������擾����
;---------------------------------------------------------------------------
GETRND
	PSHS	X
	TFR	D, X
	BSR	RANDOM
	EXG	X, D
	BSR	DIV16
	PULS	X, PC

;---------------------------------------------------------------------------
;16bit ���Z
;	IN	X	�폜��
;		D	����
;	OUT	X	��(quotient)
;		D	��](remainder)
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
; 16bit��Z
; 	IN	D	��搔(multiplicand)
;		X	�搔(multiplier)
;	OUT	D	��(product)
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
; 16bit��Z(10�{�Œ�)
; 	IN	D	��搔(multiplicand)
;	OUT	D	��(product)
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
; 16bit�Ϙa(10�{�Œ�: X * 10 + A)
; 	IN	X	��搔(multiplicand)
;		A	����
;	OUT	X	��(product)
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
;������̃f���~�^(" or ')���H
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
;�󔒂̓ǂݔ�΂�
;	IN	Y	������
;	OUT	Y	�󔒂̎��̕���
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
;������̒������擾
;	IN	X	������
;	OUT	A	������
;---------------------------------------------------------------------------
STRLEN_X
	LDA	#-1
1	INCA
	TST	A, X
	BNE	1B
	RTS
;---------------------------------------------------------------------------
;������̒������擾
;	IN	Y	������
;		A	������̃f���~�^
;	OUT	B	������
;---------------------------------------------------------------------------
STRLEN_Y
	PSHS	A
	CLRB
1	LDA	B, Y
	BEQ	2F
	LBSR	ISPRINT
	BNE	2F
	CMPA	, S	;�擪�̕����ƃ`�F�b�N
	BEQ	2F
	INCB
	BRA	1B
2	PULS	A, PC
;---------------------------------------------------------------------------
;������𐔒l�ɕϊ�
;	IN	Y	������
;	OUT	D	���l
;		Y	���l�̌��̕���
;		ZF	SET : OK
;			RESET : NG
;---------------------------------------------------------------------------
STR_TO_INT	PSHS	X
	LDX	#0	;�l���N���A
	PSHS	X
1	LDA	, Y+
	LBSR	ISDIGIT
	BNE	2F
	SUBA	#'0'
	LBSR	MUL_X_BY_10_ADD_A
	CMPX	, S	;�O��̒l�Ɣ�r
	BLO	3F	;�O���菬�����ꍇ�̓G���[
	STX	, S
	BRA	1B
2	LEAY	-1, Y
	SET_ZF
3	PULS	D, X, PC

;---------------------------------------------------------------------------
;�啶���ɕϊ�����
;	IN	A	����
;	OUT	A	�啶���ɕϊ���������
;---------------------------------------------------------------------------
TOUPPER
	LBSR	ISALPHA
	BNE	1F
	ANDA	#$DF
1	RTS
;---------------------------------------------------------------------------
;�\���\�������H
;	IN	A
;	OUT	ZF	SET : �\����
;			RESET : �\���s��
;---------------------------------------------------------------------------
ISPRINT	CMPA	#' '
	BLO	2F	;CLEAR ZERO FLAG
	CMPA	#126
	BHI	2F	;CLEAR ZERO FLAG
	BRA	1F	;SET ZERO FLAG
;---------------------------------------------------------------------------
;�󔒕������H
;	IN	A
;	OUT	ZF	SET : ��
;			RESET : �󔒈ȊO
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
;�������H
;	IN	A
;	OUT	ZF	SET : ����
;			RESET : �����ȊO
;---------------------------------------------------------------------------
ISDIGIT	CMPA	#'0'
	BLO	2F	;CLEAR ZERO FLAG
	CMPA	#('9')
	BLS	1B	;SET ZERO FLAG
2	CLR_ZF
	RTS
;---------------------------------------------------------------------------
;�p�����H
;	IN	A
;	OUT	ZF	SET : �p��
;			RESET : �p���ȊO
;---------------------------------------------------------------------------
ISALPHA	ORA	#%00100000	;�������ɕϊ�����
	CMPA	#'a'
	BLO	2B	;CLEAR ZERO FLAG
	CMPA	#'z'
	BHI	2B	;CLEAR ZERO FLAG
	BRA	1B	;SET ZERO FLAG
