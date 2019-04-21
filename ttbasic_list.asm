;---------------------------------------------------------------------------
;X���w��BNN�̃o�C�g�񂩂�NN���\��short�^�̒l��Ԃ�
;B��0�̏ꍇ(���X�g�̏I�[)��NN�����݂��Ȃ��̂œ��ʂȒl32767��Ԃ�
;���ԃR�[�h�|�C���^�͐i�߂Ȃ��A�K�v�Ȃ�3�𑫂�
; Get line numbere by line pointer
;	IN	X	line pointer
;	OUT	D	line number
;---------------------------------------------------------------------------
GET_LINE_NO
	TST	, X
	BEQ	GET_LINE_NO_MAX
	LDD	1, X
	RTS
	;����������������s�ԍ��̍ő�l�������A��
GET_LINE_NO_MAX	LDD	#32767
	RTS

;---------------------------------------------------------------------------
; �s�ԍ����w�肵�čs�ԍ������������傫���s�̐擪�̃|�C���^�𓾂�
; �O���[�o���ȕϐ���ύX���Ȃ�
;	IN	D	line number
;	OUT	X	line pointer
;---------------------------------------------------------------------------
GET_LINE_PTR
	PSHS	D	;save lineno to stack
	LDX	#LISTBUF
1	;�擪���疖���܂ŌJ��Ԃ�
	TST	, X
	BEQ	2F
	BSR	GET_LINE_NO
	CMPD	, S	;�����w��̍s�ԍ��ȏ�Ȃ�
	BHS	2F	;�J��Ԃ���ł��؂�
	LDB	, X
	ABX
	BRA	1B
2	;�|�C���^�������A��
	PULS	D, PC

;---------------------------------------------------------------------------
; ���X�g�����̃A�h���X���擾����
;	IN	X	���X�g�����̃A�h���X
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
; �󂫃������o�C�g�����擾����
;	OUT	D	FREE MEMORY SIZE
;---------------------------------------------------------------------------
GET_FREE_SIZE
	PSHS	X
	;���X�g�����̃A�h���X���擾
	BSR	GET_LIST_TAIL
	;���X�g�ɓ����Ă���o�C�g�����v�Z
	TFR	X, D
	SUBD	#LISTBUF
	;D�𔽓]����(���Z�̂���)
	LBSR	NEGD
	ADDD	#(SIZE_LIST-1)
	PULS	X, PC

;---------------------------------------------------------------------------
;���ԃR�[�h�o�b�t�@�̓��e�����X�g�o�b�t�@�ɕۑ�
;�G���[���G���[�t���O�Œm�点��
;---------------------------------------------------------------------------
INSLIST	PSHS	D, X, Y, U
	;X:
	;Y:
	;U:�}����̃|�C���^�[(clp)

;	cip = ibuf;//ip�͒��ԃR�[�h�o�b�t�@�̒��ԃR�[�h���w��
;		(���X�g�̒��ԃR�[�h�ł͂Ȃ�)
;	clp = getlp(getvalue(cip));//�s�ԍ���n���đ}���s�̈ʒu���擾

	LDX	#IBUF
	LBSR	GET_LINE_NO	;D<=�s�ԍ�
	LBSR	GET_LINE_PTR	;X<=�}����̃|�C���^
	LEAU	, X	;U<=�}����̃|�C���^(clp)

	PSHS	D	;�ǉ�/�X�V����s�ԍ�

	;�}����|�C���^�̎��s�ԍ����擾
	LBSR	GET_LINE_NO
	;�}����̍s�ԍ��ƒǉ�/�X�V����s�ԍ����r
	CMPD	, S
	BNE	INSLIST_INSERT
;	;::::::::::debug :::::::::::::
;	LBSR	PUTS
;	FCC	CR, "REPLACE",0
;	PUT_C	'b'
;	;::::::::::debug :::::::::::::
	;�󂫗̈�{�����ւ��s�̃o�C�g���|�X�V�s�̃o�C�g��<0�̏ꍇNG
	BSR	GET_FREE_SIZE
	ADDB	, X
	ADCA	#0
	;�󂫗̈悪���݂̍s�̃o�C�g����菭�Ȃ��ꍇ��NG
	;D = D - *(#IBUF)
	SUBB	IBUF
	BHS	1F
	SBCA	#0
	LBLS	INSLIST_E_LBUFOF
	;�����ւ��s���폜����
1	BSR	INSLIST_DEL_LINE
INSLIST_INSERT
;;	;::::::::::debug :::::::::::::
;	PUT_C	'c'
;;	;::::::::::debug :::::::::::::
	PULS	D
	LDX	#IBUF
	LDA	, X
	CMPA	#4	;4�̏ꍇ�͍s�Ԍ�݂̂ŃX�e�[�g�����g�Ȃ�
	BEQ	INSLIST_END
	;�󂫗̈�̃`�F�b�N
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
	;�}���̂��߂̃X�y�[�X�����
1	BSR	INSLIST_MK_SPACE

;	;::::::::::debug :::::::::::::
;	LBSR	PUTS
;	FCC	CR, "U:",0
;	TFR	U, D
;	LBSR	PUTHEX_D
;	;::::::::::debug :::::::::::::
	;�s��]������
	LDX	#IBUF
	LDB	, X
	;�]��
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
	;�s�ԍ�����v
	;U <= p1(�}���ʒu)
	LDA	, U
	LEAX	A, U	;X<=U�̎��̍s
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
INSL_MOVE_F	LDA	, X
	;���̍s�̒�����0�̏ꍇ�͏I���
	BEQ	INSL_MOVE_F_END
	;���̍s��O�ɋl�߂�
INSL_MOVE_F_LP	LDB	, X+
	STB	, U+
	DECA
	BNE	INSL_MOVE_F_LP
	BRA	INSL_MOVE_F
INSL_MOVE_F_END
	CLR	, U	;���X�g�̖�����0��u��
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
	;�ړ����镝���v�Z
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
	PULS	D	;len(255�ȉ��̂͂�)
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CLRA
	STA	, X	;���X�g�̍Ō��ݒ�
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
;���ԃR�[�h��1�s�������X�g�\��
;�����͍s�̒��̐擪�̒��ԃR�[�h�ւ̃|�C���^
;	IN	Y	�s�|�C���^
;---------------------------------------------------------------------------
PUTLIST	PSHS	D, X, U
	;�s���łȂ���ΌJ��Ԃ�
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
PUTLIST_ERROR	;�ǂ�ɂ����Ă͂܂�Ȃ������ꍇ�̓G���[
	LDA	#ERR_SYS
	STA	ERR_CODE
PUTLIST_END
	PULS	D, X, U, PC
	;-----------------------------------------------------
PUTLIST_KEYWORD	;�L�[���[�h�̏���
	LBSR	GET_KEYWORD_STR
	;X���A�h���X�Ƃ���L�[���[�h��\������
	LBSR	PUTLIST_PUTS_X
	;�L�[���[�h�̌��ɋ󔒂��o�͂��邩�`�F�b�N
	LDA	, Y
	BSR	NOSPACE_AF
	;�|�C���^�����̒��ԃR�[�h or �������֐i�߂�
	LDA	, Y+
	CMPA	#I_REM	;���݂̒��ԃR�[�h��REM�̏ꍇ
	BNE	PUTLIST_LOOP
	;�������ԃR�[�h��I_REM�Ȃ�
	BSR	PUTLIST_PUTS_Y
	;�R�����g�̌��ɒ��ԃR�[�h�͂Ȃ��̂ŏI������
	PULS	D, X, U, PC
	;-----------------------------------------------------
PUTLIST_NUMBER	;�萔�̏���
	;�l���擾���ĕ\��
	LDD	1, Y
	LDX	#0
	LBSR	C_PUTNUM
	LEAY	3, Y	;�|�C���^�����̖��߂ɐi�߂�
	;���̖��߂��`�F�b�N
	BRA	PUTLIST_NEXTCHK
	;-----------------------------------------------------
PUTLIST_VAR	;�ϐ��̏���
	LEAY	1, Y	;�|�C���^��ϐ��ԍ��ɐi�߂�
	LDA	, Y+	;�ϐ��ԍ����擾
	ADDA	#'A'
	LBSR	C_PUTCH
	;-----------------------------------------------------
	;���̖��߂��`�F�b�N
PUTLIST_NEXTCHK
	LDA	, Y
	;���̖��߂��󔒕\����O�ɓ�����Ȃ���΋󔒂�\������
	BSR	NOSPACE_BF
	BRA	PUTLIST_LOOP
	;-----------------------------------------------------
PUTLIST_STR	;������̏���
	;������̊���Ɏg���Ă��镶���𒲂ׂ�
	LEAY	1, Y	;�|�C���^�𕶎����֐i�߂�
	LDB	, Y	;������
	;�f���~�^�����肷��
	BSR	PUTLIST_SET_DLM
	PSHS	A	;�u"�v�܂��́u'�v
	;������̊����\��
	LBRA	C_PUTCH
	;�������\������
	BSR	PUTLIST_PUTS_Y
	;������̊����\��
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
PUTLIST_PUTS_Y	LDB	, Y+	;���������擾���ĕ\������
	;�R�����g��\������
PUTS_Y_LOOP	LDA	, Y+
	LBSR	C_PUTCH
	DECB
	BNE	PUTS_Y_LOOP
	RTS
	;-----------------------------------------------------
PUTLIST_SET_DLM	LDA	B, Y
	;�u"�v($22)�����������ꍇ�́A����́u'�v�Ƃ���
	CMPA	#$22
	BEQ	PUTLIST_SET_DLM_E
	DECB
	BNE	PUTLIST_SET_DLM
	;�u"�v��������Ȃ������̂ŁA����́u"�v�Ƃ���
	LDA	#($22-5)
PUTLIST_SET_DLM_E
	ADDA	#5
	RTS
	;-----------------------------------------------------
	;�L�[���[�h�̌��ɋ󔒂��o�͂��邩�`�F�b�N��
	;�K�v�Ȃ�󔒂��o��
NOSPACE_AF	LBSR	IS_NOSPACE_AF
	BNE	NOSPACE_AF_E
	LBSR	C_PUT_SPACE
NOSPACE_AF_E	RTS
	;-----------------------------------------------------
	;���̖��߂��󔒕\����O�ɓ�����Ȃ���΋󔒂�\������
NOSPACE_BF	LBSR	IS_NOSPACE_BF
	BNE	NOSPACE_BF_E
	LBSR	C_PUT_SPACE
NOSPACE_BF_E	RTS
