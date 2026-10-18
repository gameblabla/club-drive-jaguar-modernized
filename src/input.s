	.include	'eq.s'
	.include	'externs.s'

	.extern	start
	.text
input::
	bsr		readpad				;read joypad, buttons, keys
	move.l	joyedge,d0
	or.l		joyedge2,d0
	move.l	d0,joybothe			;set joyedge for both players combined
	move.l	joycur,d0
	or.l		joycur2,d0
	move.l	d0,joybothc			;set joycur for both players combined

	move.l	joycur,d0
	btst.l	#KEY_STAR,d0
	beq.b	.50
	btst.l	#KEY_HASH,d0
	bne		inp_res				;* key and # key restarts program
	.50:
	move.l	joycur2,d0
	btst.l	#KEY_STAR,d0
	beq.b	.90
	btst.l	#KEY_HASH,d0
;;	bne		restart				;* key and # key restarts program
	beq		.90
		jsr		clearscr
		bra		start
.90:
	bra		ck_radio
	;rts

;-----------------
;reset has been detected by player 1 - look for option for EEPROM clear
inp_res:
	move.l	#$00000008,G_CTRL		;stop the GPU
;	move.l	#olist_ram,listAddr		;reset displayed object list
	jsr		clearscr
	; wait until keyup and look for option key (for EEPROM clear)
	moveq	#0, d7		; a bool so that clear EEPROM only happens once
	.30:
		bsr		readpad
		move.l	joycur,d0
		btst.l	#OPTION,d0
		beq.b	.40
			btst		#0, d7
			bne.b	.40		; did it!
			bsr		sv_defhi						;reset high scores
			moveq	#1, d7	; been there!
			bra.b	.30
		.40:
		and.l	#(1<<KEY_STAR)|(1<<KEY_HASH), d0
		bne.b	.30
	bra		start


;-------------------------------------------------------------------------------------
; a more dead input for pause
pinput::
	bsr		readpad				;read joypad, buttons, keys
	move.l	joyedge,d0
	or.l		joyedge2,d0
	move.l	d0,joybothe			;set joyedge for both players combined
;	move.l	joycur,d0
;	or.l		joycur2,d0
;	move.l	d0,joybothc			;set joycur for both players combined

	move.l	joycur,d0
	btst.l	#KEY_STAR,d0
	beq.b	.50
	btst.l	#KEY_HASH,d0
	bne.b		inp_res			; retail short backward branch				;* key and # key restarts program
.50:
	move.l	joycur2,d0
	btst.l	#KEY_STAR,d0
	beq.b	.90
	btst.l	#KEY_HASH,d0
	bne		start
.90:
	rts
;***********************************************************************************************
readpad::
;must set bit 8 ($100) in JOYOUT to cancel mute
	move.l	#$f0fffffc,d1		; d1 = Joypad data mask
	moveq.l	#-1,d2			; d2 = Cumulative joypad reading

	move.w	#$81fe,JOYOUT
	move.l	JOYIN,d0			; Read joypad, pause button, A button
	or.l		d1,d0			; Mask off unused bits
	ror.l	#4,d0
	and.l	d0,d2			; d2 = xxApxxxx RLDUxxxx xxxxxxxx xxxxxxxx
	move.w	#$81fd,JOYOUT
	move.l	JOYIN,d0			; Read *741 keys, B button
	or.l		d1,d0			; Mask off unused bits
	ror.l	#8,d0
	and.l	d0,d2			; d2 = xxApxxBx RLDU741* xxxxxxxx xxxxxxxx
	move.w	#$81fb,JOYOUT
	move.l	JOYIN,d0			; Read 2580 keys, C button
	or.l		d1,d0			; Mask off unused bits
	rol.l	#6,d0
	rol.l	#6,d0
	and.l	d0,d2			; d2 = xxApxxBx RLDU741* xxCxxxxx 2580xxxx
	move.w	#$81f7,JOYOUT
	move.l	JOYIN,d0			; Read 369# keys, Option button
	or.l		d1,d0			; Mask off unused bits
	rol.l	#8,d0
	and.l	d0,d2			; d2 = xxAPxxBx RLDU741* xxCxxxOx 2580369#

	moveq.l	#-1,d1
	eor.l	d2,d1			; d1 = Inputs active high

	move.l	joycur,d0
	move.l	d1,joycur			; Current joypad reading
	eor.l	d1,d0			;		0 & 0 = 0
	and.l	d1,d0			;		0 & 1 = 1
							;		1 & 0 = 0
							;		1 & 1 = 1
	move.l	d0,joyedge		;joypad, buttons, keys that were just pressed
;fall through to readpad2
readpad2::
;must set bit 8 ($100) in JOYOUT to cancel mute
;read player 2 controller
	move.l	#$0FFFFFF3,d1		; d1 = Joypad data mask
	moveq.l	#-1,d2			; d2 = Cumulative joypad reading

	move.w	#$817f,JOYOUT
	move.l	JOYIN,d0			; Read joypad, pause button, A button
	or.l		d1,d0			; Mask off unused bits
	rol.b	#2,d0			; this is different than readpad
	ror.l	#8,d0
	and.l	d0,d2			; d2 = xxApxxxx RLDUxxxx xxxxxxxx xxxxxxxx
	move.w	#$81bf,JOYOUT
	move.l	JOYIN,d0			; Read *741 keys, B button
	or.l		d1,d0			; Mask off unused bits
	rol.b	#2,d0			; this is different than readpad
	ror.l	#8,d0
	ror.l	#4,d0			; this is different than readpad
	and.l	d0,d2			; d2 = xxApxxBx RLDU741* xxxxxxxx xxxxxxxx
	move.w	#$81df,JOYOUT
	move.l	JOYIN,d0			; Read 2580 keys, C button
	or.l		d1,d0			; Mask off unused bits
	rol.b	#2,d0			; this is different than readpad
	rol.l	#8,d0
	and.l	d0,d2			; d2 = xxApxxBx RLDU741* xxCxxxxx 2580xxxx
	move.w	#$81ef,JOYOUT
	move.l	JOYIN,d0			; Read 369# keys, Option button
	or.l		d1,d0			; Mask off unused bits
	rol.b	#2,d0			; this is different than readpad
	rol.l	#4,d0
	and.l	d0,d2			; d2 = xxAPxxBx RLDU741* xxCxxxOx 2580369#

	moveq.l	#-1,d1
	eor.l	d2,d1			; d1 = Inputs active high

	move.l	joycur2,d0
	move.l	d1,joycur2		; Current joypad reading
	eor.l	d1,d0			;		0 & 0 = 0
	and.l	d1,d0			;		0 & 1 = 1
							;		1 & 0 = 0
							;		1 & 1 = 1
	move.l	d0,joyedge2		;joypad, buttons, keys that were just pressed
	rts

