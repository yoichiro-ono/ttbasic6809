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
;���l��\������
;D : �l
;X : ����
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
	CLR	WLEN	;���݂̌���
	LDU	#(PBUF+9)
	CLR	, U	;�I�[�����Z�b�g
	;�}�C�i�X���H
	CMPD	#0
	BGE	C_PUTNUM_PLUS
	INC	SIGN	;��������ɃZ�b�g
	LBSR	NEGD	;�����ɕϊ�
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
C_PUTNUM_LOOP2	;�w�茅���ɂȂ�܂ŋ󔒂�t�^����
	CMPA	3, S
	BGE	C_PUTNUM_PRINT
	STB	, -U
	INCA
	BRA	C_PUTNUM_LOOP2
C_PUTNUM_PRINT	LEAX	, U
	LBSR	C_PUTS

	PULS	D, X, U, PC

;---------------------------------------------------------------------------
;���l����͂���
;Called by only INPUT statement
;OUT D : �l
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
	;�s���̕�������ѐ��������͂��ꂽ�ꍇ�̏���
	;�i�������݂�6���𒴂��Ȃ����Ɓj
	CMPA	#'-'
	BEQ	GETNUM_SIGN
	CMPA	#'+'
	BEQ	GETNUM_SIGN
	CMPB	#6
	BHS	GETNUM_LOOP	;6���܂œ��͉\
	LBSR	ISDIGIT
	BEQ	GETNUM_SETBUF
	;�����ȊO�͖���
	BRA	GETNUM_LOOP

GETNUM_SIGN	;�����͍s���̂�OK
	TSTB
	BNE	GETNUM_LOOP
GETNUM_SETBUF
	STA	B, Y
	INCB
	LBSR	C_PUTCH
	BRA	GETNUM_LOOP


	;[BackSpace]�L�[�������ꂽ�ꍇ�̏����i�s���ł͂Ȃ����Ɓj
GETNUM_BS	TSTB
	BEQ	GETNUM_LOOP
	DECB
	LBSR	C_PUT_BS
	BRA	GETNUM_LOOP

GETNUM_END	LBSR	C_NEWLINE
	CLR	B, Y	;�I�[��u��
	;���l�ɕϊ�
	LDB	, Y	;�擪�̕������擾
	CMPB	#'+'	;�u+�v�̏ꍇ�͎��̕�����
	BEQ	GETNUM_NEXT_C
	CMPB	#'-'
	BNE	GETNUM_TO_INT
	NEG	SIGN	;�u-�v�̏ꍇ�̓t���O���Z�b�g��
			;���̕�����
GETNUM_NEXT_C	LEAY	1, Y
GETNUM_TO_INT	LBSR	STR_TO_INT
	BNE	GETNUM_ERR_VOF
;1	LEAU	1, Y	;��������̏ꍇ��2�����ڈȍ~��Ώ�
;2	LDX	#0	;�l���N���A
;GETNUM_LOOP2	STX	VALUE1
;	LDA	, Y+
;	BEQ	GETNUM_LOOP2_E
;	LBSR	MUL_X_BY_10_ADD_A
;	CMPX	VALUE1
;	BHS	GETNUM_LOOP2
;GETNUM_ERR_VOF
;	LDB	#ERR_VOF	;�O���菬�����ꍇ�̓G���[
;	STB	ERR_CODE
;
;GETNUM_LOOP2_E
	TST	SIGN
	BEQ	1F
	;���̒l�ɕϊ�
	LBSR	NEGD
1	PULS	X, Y, PC
GETNUM_ERR_VOF
	LDB	#ERR_VOF	;�O���菬�����ꍇ�̓G���[
	STB	ERR_CODE
	PULS	X, Y, PC

;---------------------------------------------------------------------------
; output console
;	IN	A	�o�͕���
;			CR�̏ꍇ�͑�����LF���o��
;---------------------------------------------------------------------------
C_PUTCH	CMPA	#CR
	LBNE	C_PUTCHAR
	LBSR	C_PUTCHAR
	LDA	#LF	;DO LINEFEED AFTER CR
	LBRA	C_PUTCHAR
;---------------------------------------------------------------------------
; output console newline
;	IN	A	�o�͕���
;			CR�̏ꍇ�͑�����LF���o��
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
;�������\������
;	IN	X	STRING
;---------------------------------------------------------------------------
C_PUTS	PSHS	X
1	LDA	,X+
	BEQ	2F
	LBSR	C_PUTCH
	BRA	1B
2	PULS	X, PC
;---------------------------------------------------------------------------
;BS��\�����ĕ���������
;---------------------------------------------------------------------------
C_PUT_BS	PSHS	A
	LDA	#BS
	LBSR	C_PUTCHAR
	BSR	C_PUT_SPACE
	LDA	#BS
	LBSR	C_PUTCHAR
	PULS	A, PC
;---------------------------------------------------------------------------
;1�����̋󔒂�\������
;---------------------------------------------------------------------------
C_PUT_SPACE	PSHS	A
	LDA	#SPACE
	LBSR	C_PUTCH
	PULS	A, PC
;---------------------------------------------------------------------------
;���������͂�LBUF�ɕۑ�����
;---------------------------------------------------------------------------
C_GETS	PSHS	D, U
	CLRB		;������
	LDU	#LBUF	;���̓o�b�t�@
C_GETS_LOOP	LBSR	C_GETCH
	CMPA	#KEY_ENTER	;[Enter]�ŏI��
	BEQ	C_GETS_LOOP_E

	BSR	REPLACE_TAB	;[Tab]�L�[�͋󔒂ɒu��������
	
	BSR	IS_KEY_BS	;[Back Space]����
	BEQ	C_GETS_BS
	;BS�ȊO
	LBSR	ISPRINT
	BNE	C_GETS_LOOP	;��\������
	CMPB	#(SIZE_LINE-1)	;�o�b�t�@�����Ȃ��悤��
	BHS	C_GETS_LOOP	;B>=(SIZE_LINE-1)
	;���͕������o�b�t�@�ɒǉ�
	STA	B, U
	INCB
	LBSR	C_PUTCH
	BRA	C_GETS_LOOP
C_GETS_BS	;BS
	;�o�b�t�@�ɕ������Ȃ��ꍇ�͉������Ȃ�
	TSTB
	BEQ	C_GETS_LOOP
	;��������1���炷
	DECB
	BSR	C_PUT_BS
	BRA	C_GETS_LOOP
C_GETS_LOOP_E
	LBSR	C_NEWLINE	;���s
	BSR	TRIM_END_SPACE	;�o�b�t�@����łȂ��ꍇ�͖����̋󔒂����
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
	;�o�b�t�@����łȂ��ꍇ�͖����̋󔒂����
	DECB
	LDA	B, U
	LBSR	ISSPACE
	BEQ	1B
	INCB
2	CLR	B, U	;�I�[�������Z�b�g
	RTS
