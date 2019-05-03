;/*
; TOYOSHIKI Tiny BASIC for Arduino
; (C)2012 Tetsuya Suzuki
; GNU General Public License
;  2019/xx/xx, Porting by Tamakichi�Afor 6809 ; */

;---------------------------------------------------------------------------
;MACRO�y�ѐݒ�
;---------------------------------------------------------------------------
	INCLUDE	/ttbasic_macro.asm/
	INCLUDE	/ttbasic_def.asm/
;---------------------------------------------------------------------------
;RAM����t��
;---------------------------------------------------------------------------
	ORG	$0000
RANDOM_SEED	RMB	2	;����
CLP	RMB	2	;Pointer current line
GSTKI	RMB	1	;GOSUB stack index
GSTK	RMB	SIZE_GSTK	;GOSUB stack
LSTKI	RMB	1	;FOR stack index
LSTK	RMB	SIZE_LSTK	;FOR stack
ERR_CODE	RMB	1	;�G���[�R�[�h
PBUF	RMB	10	;�\���p���[�N
SIGN	RMB	1	;����
WLEN	RMB	1	;��
PLEN	RMB	2	;PRINT�̌���
WSIZE	RMB	1
VALUE1	RMB	2	;�l
VALUE2	RMB	2	;�l

VAR	RMB	26*2	;�ϐ��̈�(Variable area)
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
;���荞�݃n���h��
;---------------------------------------------------------------------------
SWI3	;�\�t�g�E�F�A���荞�݂R
	RTI
SWI2	;�\�t�g�E�F�A���荞�݂Q
	RTI
FIRQ	;�������荞��
	RTI
IRQ	;�ʏ튄�荞��
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
SWI	;�\�t�g�E�F�A���荞�݂P
	RTI
NMI	;�}�X�N�s���荞��
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
;���Z�b�g����
;---------------------------------------------------------------------------
RESET	;���Z�b�g
	;DP�̏�����
	CLRA
	TFR	A, DP
	;�X�^�b�N�̐ݒ�
	LDS	#STACK_TOP
	;���������l�̐ݒ�
	LDD	#12345
	STD	RANDOM_SEED
	;ACIA�̏�����
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
;�e�탂�W���[��
;---------------------------------------------------------------------------

	INCLUDE	/ttbasic_debug.asm/
	INCLUDE	/ttbasic_console.asm/
	INCLUDE	/ttbasic_keyword.asm/
	INCLUDE	/ttbasic_sub.asm/
	INCLUDE	/ttbasic_list.asm/
	INCLUDE	/ttbasic_error.asm/

;---------------------------------------------------------------------------
; ���ʂł�����ꂽ����l�ɕϊ����Ē��ԃR�[�h�|�C���^��i�߂�
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
	;"("�łȂ��ꍇ�̓G���[
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPA	#I_OPEN
	BNE	GET_PARAM_ERR
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�

	LBSR	IEXP	;�����v�Z
	TST	ERR_CODE	;�����G���[����������
	BNE	1F	;�I��

	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"GET_PARAM2"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	D
	;")"�łȂ��ꍇ�̓G���[
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
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
	;�W�����v�e�[�u���v�Z
	LDX	#IVALUE_TBL
	ASLB		;B=B*2
	ABX
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;0�̏ꍇ�͑ΏۊO
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
	;�萔�̎擾
IVALUE_NUM	;�萔
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LDD	, Y++	;�萔���擾�����ԃR�[�h�|�C���^��萔�̎��֐i�߂�
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_NUM"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_PLUS	;+�t���̒l�̎擾
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	;BSR	IVALUE	;�l���擾
	JSR	IVALUE
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IVALUE_PLUS"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_MINUS	;���̒l�̎擾
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IVALUE
	LBSR	NEGD
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IVALUE_MINUS"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_VAR	;�ϐ��ԍ����擾����
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
IVALUE_OPEN	;���ʂ̒l�̎擾
	LBSR	GET_PARAM
	PULS	X, PC

	;-----------------------------------------------------------
IVALUE_ARRAY	;�z��̒l�̎擾
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IVALUE_ARRAY"
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	GET_PARAM
	TST	ERR_CODE
	BNE	IVALUE_END	;�G���[�������͏I��
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
	LBNE	IVALUE_END	;�G���[�������͏I��
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
	LBNE	IVALUE_END	;�G���[�������͏I��
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
	BNE	IMUL_ERR_END	;�G���[�������͏I��
	PSHS	D	;���ݒl���X�^�b�N�ɕۑ�
IMUL_LOOP
	LDA	, Y
	CMPA	#I_MUL
	BEQ	IMUL_MUL
	CMPA	#I_DIV
	BEQ	IMUL_DIV
	;MUL,DIV�̂�����ł��Ȃ�
	PULS	D
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IMUL END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, U, PC
	;PULS	D, X, U, PC
	;-----------------------------------------------------------
IMUL_MUL	;�|���Z�̏ꍇ
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IVALUE
	LDX	, S	;��搔���X�^�b�N����擾
	LBSR	MUL16
	STD	, S	;�v�Z���ʂ��X�^�b�N�ɕۑ�
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IMUL:"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	BRA	IMUL_LOOP

	;-----------------------------------------------------------
IMUL_DIV	;����Z�̏ꍇ
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IVALUE
	CMPD	#0
	BEQ	IMUL_ERR_DIV0
	LDX	, S	;�폜�����X�^�b�N����擾
	LBSR	DIV16
	STX	, S	;�����X�^�b�N�ɕۑ�
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
	PSHS	D	;���ݒl���X�^�b�N�ɕۑ�
IPLUS_LOOP
	LDA	, Y
	CMPA	#I_PLUS
	BEQ	IPLUS_PLUS
	CMPA	#I_MINUS
	BEQ	IPLUS_MINUS
	;PLUS,MINUS�̂�����ł��Ȃ�
	PULS	D
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPLUS END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PULS	X, U, PC
	;PULS	D, X, U, PC

	;-----------------------------------------------------------
IPLUS_PLUS	;�����Z
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IMUL
	ADDD	, S	;�X�^�b�N��̌��ݒl�����Z
	STD	, S	;���ʂ��X�^�b�N�ɕۑ�
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"IPLUS:"
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	BRA	IPLUS_LOOP
	;-----------------------------------------------------------
IPLUS_MINUS	;�����Z
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IMUL
	LBSR	NEGD	;���Z���邽�߂ɕ������]
	ADDD	, S	;�X�^�b�N��̌��ݒl�����Z
	STD	, S	;���ʂ��X�^�b�N�ɕۑ�
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
	PSHS	D	;���ݒl���X�^�b�N�ɕۑ�
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
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
	CMPD	, S	;�X�^�b�N��̌��ݒl�Ɣ�r
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
	STD	, S	;�X�^�b�N��̌��ݒl�ɕۑ�
	BRA	IEXP_LOOP
IEXP_TRUE
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TRUE"
	;::::::::::debug :::::::::::::
	LDD	#1
	STD	, S	;�X�^�b�N��̌��ݒl�ɕۑ�
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
	;���̏ꍇ
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
IPRINT_STR	;������̏ꍇ
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IPRINT STR"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LDB	, Y+	;���������擾����
1	LDA	, Y+
	LBSR	C_PUTCH
	DECB
	BNE	1B
	BRA	IPRINT_NEXT
	;-----------------------------------------------------------
IPRINT_SHARP	;�u#�v�̏ꍇ
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IEXP	;�������擾
	TST	ERR_CODE
	BNE	IPRINT_ERR_END
	STD	PLEN	;������ێ�
	;-----------------------------------------------------------
IPRINT_NEXT
	LDA	, Y
	CMPA	#I_COMMA
	BEQ	IPRINT_COMMA
	;�R���}�ȊO
	BSR	IS_SEMI_OR_EOL
	BEQ	IPRINT_LOOP
	;�Z�~�R�����ł������ł��Ȃ���΃G���[
	LDB	#ERR_SYNTAX
	STB	ERR_CODE
	PULS	D, X, U, PC
IPRINT_COMMA	;�R���}������ꍇ
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	;���̒��ԃR�[�h���擾����
	LDA	, Y
	BSR	IS_SEMI_OR_EOL
	BNE	IPRINT_LOOP	;�����ȊO�̓��[�v���p��
	;���������Ȃ�I��
	PULS	D, X, U, PC

;---------------------------------------------------------------------------
; �Z�~�R�����������𔻒肷��
;	IN	A	���ԃR�[�h
;	OUT	ZF	SET : �Z�~�R�����܂��͕���
;			RESET : �ȊO
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
	PSHS	A	;�v�����v�g�\���t���O
IINPUT_LOOP
	CLR	, S	;�܂��v�����v�g��\�����Ă��Ȃ�
	LDA	, Y
	CMPA	#I_STR
	BNE	1F
	LBSR	IINPUT_PROMPT_STR

	;�l����͂��鏈��
1	CMPA	#I_VAR
	BEQ	IINPUT_VAR
	CMPA	#I_ARRAY
	BEQ	IINPUT_ARRAY
	BRA	IINPUT_ERR_SYNTAX
	;-----------------------------------------------------------
IINPUT_VAR	;�ϐ��̏ꍇ
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	TST	, S	;�v�����v�g��\���������H
	BNE	1F
	BSR	IINPUT_PROMPT_VAR
1	LBSR	C_GETNUM	;D=�l
	TST	ERR_CODE
	BNE	IINPUT_END	;�G���[
	TFR	D, U	;U=�l
	LDB	, Y+	;�ϐ��ԍ����擾
	JSR	VALUE_ADDRESS
	STU	, X	;�ϐ��֑��
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IINPUT_VAR"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BRA	IINPUT_CONTUNUE_CHK
	;-----------------------------------------------------------
IINPUT_ARRAY
	LEAY	1, Y	;//���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	GET_PARAM	;�Y�������擾
	TST	ERR_CODE
	BNE	IINPUT_END
	CMPD	#SIZE_ARRY
	BHS	IINPUT_ERR_SOR	;�Y��������𒴂��Ă���
	TST	, S	;�v�����v�g��\���������H
	BNE	1F	;�v�����v�g�\���ς�
	BSR	IINPUT_PROMPT_ARR
	;�ۑ�����v�Z
1	
	JSR	ARRAY_ADDRESS
	LBSR	C_GETNUM
	TST	ERR_CODE
	BNE	IINPUT_END
	;�z��֑��
	STD	, X
	;-----------------------------------------------------------
IINPUT_CONTUNUE_CHK
	;�l�̓��͂�A�����邩�ǂ������肷��
	LDA	, Y
	;�R���}�̏ꍇ
	CMPA	#I_COMMA
	BEQ	IINPUT_COMMA
	;�Z�~�R�����A�܂��́A�s���̏ꍇ
	BSR	IS_SEMI_OR_EOL
	BNE	IINPUT_ERR_SYNTAX
IINPUT_END
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"IINPUT END"
	;::::::::::debug :::::::::::::
	PULS	A	;�v�����v�g�\���t���O�̍폜
	PULS	D, X, U, PC
	;-----------------------------------------------------------
IINPUT_COMMA
	LEAY	1, Y	;//���ԃR�[�h�|�C���^�����֐i�߂�
	LBRA	IINPUT_LOOP
	;-----------------------------------------------------------
	;�G���[
IINPUT_ERR_SOR	LDB	#ERR_SOR
	BRA	1F
IINPUT_ERR_SYNTAX
	LDB	#ERR_SYNTAX
1	STB	ERR_CODE
	PULS	A	;�v�����v�g�\���t���O�̍폜
	PULS	D, X, U, PC
	;-----------------------------------------------------------
	;�ϐ��̃v�����v�g��\������
IINPUT_PROMPT_VAR
	PSHS	A
	LDA	, Y
	ADDA	#'A'
	LBSR	C_PUTCH
	LDA	#':'
	LBSR	C_PUTCH
	PULS	A
	NEG	2, S	;�v�����v�g��\������
	RTS
	;-----------------------------------------------------------
	;�z��̃v�����v�g��\������
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
	NEG	2, S	;�v�����v�g��\������
	RTS
	;-----------------------------------------------------------
	;������̃v�����v�g��\��
IINPUT_PROMPT_STR
	LEAY	1, Y	;//���ԃR�[�h�|�C���^�����֐i�߂�
	LDB	, Y+	;���������擾
	;���������擾���A������\������
1	LDA	, Y+
	LBSR	C_PUTCH
	DECB
	BNE	1B
	NEG	, S	;�v�����v�g��\������
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
	LDB	, Y+	;�ϐ��ԍ����擾���Ď��ɐi��
	;SUBB	#I_VAR
	JSR	VALUE_ADDRESS
	LDA	, Y
	CMPA	#I_EQ	;�u=�v�ȊO�̓G���[
	BNE	IVAR_ERR
	LEAY	1, Y	;//���ԃR�[�h�|�C���^�����֐i�߂�
	;�l�̎擾�Ƒ��
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
	CMPA	#I_EQ	;�u=�v�ȊO�̓G���[
	BNE	IARRAY_ERR_VWOEQ
	LEAY	1, Y	;//���ԃR�[�h�|�C���^�����֐i�߂�
	;�l�̎擾�Ƒ��
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
	;�G���[
	LDB	#ERR_LETWOV
	STB	ERR_CODE
	RTS
ILET_VAR	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IVAR
	RTS
ILET_ARRAY	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	BSR	IARRAY
	RTS



;---------------------------------------------------------------------------
; Execute a series of i-code
; IN	Y	���s����s�̃|�C���^
; OUT	D	���Ɏ��s����ׂ��s�̃|�C���^
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
	;���Ɏ��s����ׂ��s�̃|�C���^�������A��
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IEXP
	TST	ERR_CODE
	BNE	IEXE_IF_ERR
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPD	#0
	BEQ	IEXE_IF_FALSE	;�U�̏ꍇ�̏�����REM�Ɠ���
	;�^�̏ꍇ�͎��̕������s����
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
IEXE_REM	;I_EOL�ɒB����܂Œ��ԃR�[�h�|�C���^�����֐i�߂�
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	;GOTO����擾����
	BSR	IEXE_GET_GO_LINE
	TST	ERR_CODE
	BNE	IEXE_GOTO_END
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"D:LINE NO,X:LINE PTR,Y:NEXT LINE"
	;::::::::::debug :::::::::::::
	;�s�|�C���^�𕪊��֕ύX
	STX	CLP
	;���ԃR�[�h�|�C���^��擪�̒��ԃR�[�h�ɍX�V
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	;GOSUB����擾����
	BSR	IEXE_GET_GO_LINE
	TST	ERR_CODE
	BNE	IEXE_GOTO_END

	LDA	GSTKI
	CMPA	#(SIZE_GSTK - SIZE_NEST_GSTK)
	;GOSUB�X�^�b�N�������ς��Ȃ�G���[
	BHI	IEXE_GOSUB_ERR
	LDU	#GSTK
	LEAU	A, U
	ADDA	#5
	STA	GSTKI
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"GSTK"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LDD	CLP	;�s�|�C���^���擾
	STD	, U++	;�s�|�C���^��ޔ�
	STY	, U++	;���ԃR�[�h�|�C���^��ޔ�
	LDA	LSTKI	;FOR�X�^�b�N�C���f�b�N�X���擾
	STA	, U+	;FOR�X�^�b�N�C���f�b�N�X��ޔ�
	STX	CLP	;�s�|�C���^�𕪊��֍X�V
	LEAY	3, X	;���ԃR�[�h�|�C���^��擪�̒��ԃR�[�h�ɍX�V
	RTS
IEXE_GOSUB_ERR	LDB	#ERR_GSTKOF
	STB	ERR_CODE
	RTS
	;-----------------------------------------------------------
	;GOTO/GOSUB��̍s�ԍ��E�s�|�C���^���擾����
	;D:���̍s�ԍ�
	;X:���̍s�|�C���^
IEXE_GET_GO_LINE
	LBSR	IEXP	;D=�s�ԍ�
	TST	ERR_CODE
	BNE	IEXE_GET_NEXT_END
	LBSR	GET_LINE_PTR	;x=line pointer
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"LINE PTR"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	D
	LBSR	GET_LINE_NO	;line pointer����s�ԍ����擾
	;�s�ԍ�����v���Ă��Ȃ��ꍇ�͕���悪���݂��Ȃ�
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
	BLO	IEXE_RETURN_ERR	;GOSUB�X�^�b�N����Ȃ�G���[
	LDU	#GSTK
	LEAU	A, U
	SUBA	#5
	STA	GSTKI
	LDA	, -U	;FOR�X�^�b�N�C���f�b�N�X�𕜋A
	STA	LSTKI
	LDY	, --U	;���ԃR�[�h�|�C���^�𕜋A
	LDX	, --U	;�s�|�C���^�𕜋A
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LDA	, Y+
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPA	#I_VAR	;�ϐ����Ȃ��ꍇ�̓G���[
	LBNE	IEXE_FOR_ERR_FORWOV
	LDA	, Y	;�ϐ������擾
	LBSR	IVAR
	TST	ERR_CODE
	LBNE	IEXE_FOR_END	;�G���[�������͏I��
	PSHS	A	;�ϐ��̃C���f�b�N�X��ۑ�
	;::::::::::debug :::::::::::::
	;TFR	A, B
	;JSR	VALUE_ADDRESS
	;LDD	, X
	;DBG_PUTS	"FROM "
	;DBG_PUTHEX_D
	;DBG_NEWLINE
	;::::::::::debug :::::::::::::
	;�I���l���擾
	LDA	, Y
	CMPA	#I_TO	;TO���Ȃ���΃G���[
	LBNE	IEXE_FOR_ERR_FORWOTO
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IEXP	;�I���l���擾
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"TO"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	PSHS	D	;�I���l��ۑ�
	;�������擾
	LDA	, Y
	CMPA	#I_STEP
	BNE	FOR_NO_STEP
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IEXP	;�������擾
	BRA	FOR_CHK_STEP
FOR_NO_STEP	LDD	#1	;����=1
FOR_CHK_STEP	;�����̃`�F�b�N
	PSHS	D	;������ۑ�
	CMPD	#0
	BMI	MINUS_STEP	;����<0
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"STEP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;����>=0
	LBSR	NEGD
	ADDD	#32767
	;�I���l�Ɣ�r���A�I���l�ɂȂ�Ȃ��\��������ꍇ�̓G���[
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
	;�I���l�Ɣ�r���A�I���l�ɂȂ�Ȃ��\��������ꍇ�̓G���[
	CMPD	2, S
	BGE	IEXE_FOR_ERR_VOF
STEP_OK	;�X�^�b�N�`�F�b�N
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"STEP OK"
	;::::::::::debug :::::::::::::
	LDA	LSTKI
	CMPA	#(SIZE_LSTK - SIZE_NEST_LSTK)
	;FOR�X�^�b�N�������ς��Ȃ�G���[
	BHI	IEXE_FOR_ERR_LSTKOF
	LDU	#LSTK
	LEAU	A, U
	ADDA	#9
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEW LSTKI(A)"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	STA	LSTKI
	LDD	CLP	;�s�|�C���^���擾
	STD	, U++	;�s�|�C���^��ޔ�
	STY	, U++	;���ԃR�[�h�|�C���^��ޔ�
	PULS	D, X	;D:�����AX:�I���l
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"D=STEP,X=END"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	STX	, U++	;�I���l��ޔ�
	STD	, U++	;������ޔ�
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
	STA	, U+	;�ϐ��C���f�b�N�X��ޔ�
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LDA	LSTKI
	CMPA	#SIZE_NEST_LSTK
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	LBLO	IEXE_NEXT_ERR	;NEXT�X�^�b�N����Ȃ�G���[
	LDB	, Y+
	CMPB	#I_VAR	;NEXT�̌��ɕϐ����Ȃ�������G���[
	LBNE	IEXE_NEXT_ERR_NEXTWOV
	LDU	#LSTK
	LEAU	A, U
	;::::::::::debug :::::::::::::
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	;	U-1:�ϐ��C���f�b�N�X
	;	U-3:����
	;	U-5:�I���l
	;	U-7:���ԃR�[�h�|�C���^
	;	U-9:�s�|�C���^
	;FOR�X�^�b�N�̕ϐ������擾
	LDB	-1, U
	;NEXT�̌��̕ϐ��Ɣ�r
	CMPB	, Y+	;��v���Ȃ�������G���[
	BNE	IEXE_NEXT_ERR_NEXTUM
	JSR	VALUE_ADDRESS
	;�������擾
	LDD	-3, U
	ADDD	, X
	STD	, X
	TFR	D, X
	LDD	-3, U	;�������`�F�b�N
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEXT X=VAL, D=STEP"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BMI	NEXT_STEP_MINUS
	;�������v���X�̏ꍇ
	CMPX	-5, U
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"END CHK +"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	BGT	IEXE_NEXT_OVER	;�I���l�𒴂����̂ŏI��
	BRA	IEXE_NEXT_CONT	;���[�v���p��
NEXT_STEP_MINUS	;�������}�C�i�X�̏ꍇ
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"END CHK -"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	CMPX	-5, U
	BLT	IEXE_NEXT_OVER
IEXE_NEXT_CONT	;���[�v�̌p��
	LDY	-7, U	;���ԃR�[�h�|�C���^�𕜋A
	LDD	-9, U	;�s�|�C���^�𕜋A
	STD	CLP
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEXT CONT"
	;DBG_PRINT_REGS
	;::::::::::debug :::::::::::::
	RTS
IEXE_NEXT_OVER	;FOR-NEXT�̏I��
	;::::::::::debug :::::::::::::
	;DBG_PUTLINE	"NEXT END"
	;::::::::::debug :::::::::::::
	LDA	LSTKI
	SUBA	#SIZE_NEST_LSTK
	STA	LSTKI	;�X�^�b�N��1�l�X�g���߂�
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
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IPRINT
	RTS
	;-----------------------------------------------------------
IEXE_INPUT
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IINPUT
	RTS
	;-----------------------------------------------------------
IEXE_LET
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	ILET
	RTS
	;-----------------------------------------------------------
IEXE_STOP	;�ŏI�s���܂ōs�|�C���^(CLP)���ړ�����
	LDX	CLP
IEXE_STOP_LOOP	LDB	, X
	BEQ	IEXE_STOP_END
	ABX
	BRA	IEXE_STOP_LOOP
IEXE_STOP_END	STX	CLP
	PULS	D	;IEXE_CALL�ւ̖߂���j������
	TFR	X, D
	;IEXE�̌Ăяo�����ɖ߂�
	PULS	X, Y, U, PC
	;-----------------------------------------------------------
IEXE_SEMI
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	RTS
	;-----------------------------------------------------------
IEXE_ARRAY
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IARRAY	;����������s
	RTS
	;-----------------------------------------------------------
IEXE_VAR
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IVAR	;����������s
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
	CLR	GSTKI	;GOSUB�X�^�b�N�C���f�b�N�X�̏�����
	CLR	LSTKI	;FOR�X�^�b�N�C���f�b�N�X�̏�����
	LDX	#LISTBUF
	STX	CLP	;�s�|�C���^�����X�g�̈�̐擪�ɃZ�b�g
IRUN_LOOP	TST	, X	;�s�|�C���^���������w���܂ŌJ��Ԃ�
	BEQ	IRUN_END
	LEAY	3, X
	LBSR	IEXE
	TST	ERR_CODE
	BNE	IRUN_END	;�G���[�������͏I��
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
	LBSR	GET_LINE_NO	;�������擾���\���J�n�s�ԍ��Ƃ���
	TFR	D, U
	BRA	2F
ILIST_NO_ARG	LDU	#0
2	;�s�|�C���^��\���J�n�s�ԍ��֐i�߂�
	LDX	#LISTBUF	;�s�|�C���^��擪�s�֐ݒ�
ILIST_LOOP1	TST	, X
	BEQ	ILIST_LOOP1_E	;�����Ȃ̂ŏI��
	CMPU	1, X
	BLS	ILIST_LOOP1_E	;�\���J�n�s�ȍ~�Ȃ̂ŏI��
	LDB	, X	;�s�|�C���^�����̍s�֐i�߂�
	ABX
	BRA	ILIST_LOOP1
ILIST_LOOP1_E	;���X�g��\������
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
	LBSR	C_PUTNUM	;�s�ԍ���\��
	LBSR	C_PUT_SPACE	;�󔒂�����
	PULS	X
	LEAY	3, X
	LBSR	PUTLIST	;�s�ԍ������𕶎���ɕϊ����ĕ\��
	TST	ERR_CODE
	BNE	ILIST_LOOP2_E	;�G���[�������̓��[�v�𔲂���
	LBSR	C_NEWLINE	;���s
	LDB	, X	;�s�|�C���^�����̍s�֐i�߂�
	ABX
	BRA	ILIST_LOOP2
ILIST_LOOP2_E	PULS	D, X, Y, U, PC

;---------------------------------------------------------------------------
; NEW command handler
;---------------------------------------------------------------------------
INEW
	PSHS	X, U
	LDU	#0
	;�ϐ��̏�����
	LDX	#VAR
	LDA	#26
1	STU	, X++
	DECA
	BNE	1B
	;�z��̏�����
	LDX	#ARR
	LDA	#SIZE_ARRY
1	STU	, X++
	DECA
	BNE	1B
	;���s����p�̏�����
	STA	GSTKI	;GOSUB�X�^�b�N�C���f�N�X��0�ɏ�����
	STA	LSTKI	;FOR�X�^�b�N�C���f�N�X��0�ɏ�����
	STA	LISTBUF	;�v���O�����ۑ��̈�̐擪�ɖ����̈��u��
	LDX	#LISTBUF
	STX	CLP	;�s�|�C���^���v���O�����ۑ��̈�̐擪�ɐݒ�
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
ICOM_NEW	;NEW����
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LDA	, Y
	CMPA	#I_EOL
	BNE	ICOM_ERR_SYNTAX	;�s���ȊO�̓G���[
	;�s���̏ꍇNEW���߂����s
	LBSR	INEW
	PULS	X, Y, PC

ICOM_LIST	;LIST����
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LDA	, Y
	CMPA	#I_EOL
	BEQ	1F
	LDA	3, Y
	CMPA	#I_EOL
	BNE	ICOM_ERR_SYNTAX
	;�����s�����A���邢�͑����Ĉ���������΁ALIST���߂����s
1	LBSR	ILIST
	PULS	X, Y, PC

ICOM_RUN	;RUN����
	LEAY	1, Y	;���ԃR�[�h�|�C���^�����֐i�߂�
	LBSR	IRUN
	PULS	X, Y, PC

ICOM_OTHER	;NEW/LIST/RUN�ȊO
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
	LBSR	INEW	;���s����������

	;�N�����b�Z�[�W
	LDX	#TITLE
	LBSR	C_PUTS	;�uTOYOSHIKI TINY BASIC�v��\��
	LBSR	C_NEWLINE
	LDX	#EDITION
	LBSR	C_PUTS	;�ł���ʂ��镶�����\��
	LBSR	C_NEWLINE
	;�uOK�v�܂��̓G���[���b�Z�[�W��\�����ăG���[�ԍ����N���A
	LBSR	ERROR

	;�[������1�s����͂��Ď��s
BASIC_LOOP
	LDA	#'>'
	LBSR	C_PUTCH	;�v�����v�g��\��
	LBSR	C_GETS	;1�s�����
	;1�s�̕�����𒆊ԃR�[�h�̕��тɕϊ�

;	;::::::::::debug :::::::::::::
;	BSR	DUMP_LBUF	;debug
;	;::::::::::debug :::::::::::::
	;������𒆊ԃR�[�h�ɕϊ����Ē������擾
	LBSR	TOKTOI
	TST	ERR_CODE
	BNE	BASIC_ERROR	;�����G���[������������
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"TOKTOI LEN="
	;DBG_PUTHEX_A
	;DBG_NEWLINE
;	;::::::::::debug :::::::::::::
	LDB	IBUF
	CMPB	#I_NUM
	BNE	BASIC_COMMAND
	;�������ԃR�[�h�o�b�t�@�̐擪���s�ԍ��Ȃ�
	;���ԃR�[�h�̕��т��v���O�����Ɣ��f����
	;::::::::::debug :::::::::::::
	;DBG_PUTS	"program\r"
;	;::::::::::debug :::::::::::::
	;���ԃR�[�h�o�b�t�@�̐擪�𒷂��ɏ���������
	STA	IBUF	
	LBSR	INSLIST	;���ԃR�[�h��1�s�����X�g�֑}��
	TST	ERR_CODE
	BNE	BASIC_ERROR	;�����G���[������������
	BRA	BASIC_LOOP	;�J��Ԃ��̐擪�ɖ߂�

BASIC_COMMAND	CMPB	#I_EOL
	BEQ	BASIC_ERROR
	;���ԃR�[�h�̕��т����߂Ɣ��f�����ꍇ
	
	LBSR	ICOM
	;fall through
	;�G���[���b�Z�[�W��\�����ăG���[�ԍ����N���A
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
